//! Shows a native Android `Toast` from pure Rust, with no Java/Kotlin source
//! files anywhere in the project.
//!
//! The tricky part is that `Toast` needs an active `android.os.Looper` on
//! whichever thread constructs it (any thread works, not just the main UI
//! thread — this has been true since early Android). Since `android_main`'s
//! thread doesn't have one prepared, and there's no way to hand Android a
//! `Runnable`/`Handler.Callback` implementation without compiling a Java
//! class (which `cargo-apk` has no facility to do), we instead spin up a
//! dedicated native thread per toast that prepares its own `Looper`, shows
//! the toast, and pumps that `Looper` just long enough for the toast to be
//! displayed and dismissed by the system.

use jni::objects::{JObject, JString};
use jni::{JavaVM, bind_java_type};
use std::time::Duration;

bind_java_type! {
    pub(crate) AndroidContext => "android.content.Context",
}

bind_java_type! {
    pub(crate) Looper => "android.os.Looper",
    methods {
        static fn prepare(),
        static non_null fn my_looper() -> Looper,
        fn quit_safely(),
        static fn run_loop {
            sig = () -> (),
            name = "loop",
        },
    },
}

bind_java_type! {
    pub(crate) Toast => "android.widget.Toast",
    type_map = {
        AndroidContext => "android.content.Context",
    },
    methods {
        static fn make_text(ctx: AndroidContext, text: JCharSequence, dur: jint) -> Toast,
        fn show(),
    },
}

/// Shows a short-duration Toast with the given text.
///
/// Safe to call from any thread; does its own JNI attachment. Only valid
/// while the app's `AndroidApp`/JavaVM (populated by `winit`'s Android
/// backend before `android_main` runs) is alive.
pub fn show_toast(text: impl Into<String>) {
    let text = text.into();
    let android_ctx = ndk_context::android_context();
    // Raw pointers aren't `Send`; carry them across the thread boundary as
    // plain integers and reconstitute them on the other side.
    let vm_addr = android_ctx.vm() as usize;
    let activity_addr = android_ctx.context() as usize;

    std::thread::spawn(move || {
        // Safety: `vm_addr` is provided by `ndk_context`, which winit
        // populates with the process's real JavaVM before any Rust code runs.
        let vm = unsafe { JavaVM::from_raw(vm_addr as *mut _) };
        let activity_ptr = activity_addr as jni::sys::jobject;

        let setup = vm.attach_current_thread(|env| -> jni::errors::Result<_> {
            Looper::prepare(env)?;
            let looper = Looper::my_looper(env)?;
            let looper_global = env.new_global_ref(&looper)?;

            // Safety: `activity_ptr` is the app's Activity/Context object and
            // stays valid for the lifetime of the process.
            let activity = unsafe { JObject::from_raw(env, activity_ptr) };
            let context = AndroidContext::cast_local(env, activity)?;

            let jtext = JString::new(env, &text)?;
            let toast = Toast::make_text(env, &context, jtext.as_char_sequence(), 0)?;
            toast.show(env)?;

            Ok(looper_global)
        });

        let looper_global = match setup {
            Ok(looper_global) => looper_global,
            Err(err) => {
                log::error!("show_toast: setup failed: {err}");
                return;
            }
        };

        // Watchdog: Toast.LENGTH_SHORT is on screen for about 2 seconds.
        // Quit the Looper a bit after that so `Looper::run_loop` below
        // returns and this thread exits, instead of blocking forever. The
        // extra headroom past 2s absorbs the Binder round-trip jitter for
        // the system's own scheduled "hide" callback; too short a delay
        // and quitSafely() can drop that not-yet-due message, which shows
        // up as a harmless but noisy "Handler ... on a dead thread" warning.
        std::thread::spawn(move || {
            std::thread::sleep(Duration::from_millis(3500));
            let vm = unsafe { JavaVM::from_raw(vm_addr as *mut _) };
            let _ = vm.attach_current_thread(|env| looper_global.quit_safely(env));
        });

        // Pumps this thread's message queue so the Toast's internal Handler
        // callbacks (show/hide/timeout) actually get dispatched.
        let _ = vm.attach_current_thread(|env| Looper::run_loop(env));
    });
}
