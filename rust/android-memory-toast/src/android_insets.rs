//! Reads the Android window's current top system-bar inset (status bar
//! height) via JNI, so the UI can pad itself precisely instead of guessing.
//!
//! `android-activity`'s `AndroidApp::content_rect()` looks like the natural
//! source for this, but on-device testing on a Pixel 9 Pro (real
//! `WindowInsets`-reported status bar inset: 153px) showed it reporting
//! 279px -- fed by the legacy `NativeActivity.onContentRectChanged`
//! callback, which predates the `WindowInsets` API (API 20+) and isn't kept
//! accurate for edge-to-edge windows on this device/OS combination. Querying
//! `View.getRootWindowInsets()` directly matches what the system itself used
//! to lay out the window.
//!
//! Note this needs the actual `Activity` object from `AndroidApp`, not the
//! `Context` that `ndk_context::android_context()` provides -- that's the
//! process-wide `Application` singleton (which is why it works fine for
//! `android_toast::show_toast`, but has no window of its own).

use jni::objects::Global;
use jni::{Env, JavaVM, bind_java_type};

bind_java_type! {
    pub(crate) AndroidActivity => "android.app.Activity",
    type_map = {
        AndroidWindow => "android.view.Window",
    },
    methods {
        non_null fn get_window() -> AndroidWindow,
    },
}

bind_java_type! {
    pub(crate) AndroidWindow => "android.view.Window",
    type_map = {
        AndroidView => "android.view.View",
    },
    methods {
        non_null fn get_decor_view() -> AndroidView,
    },
}

bind_java_type! {
    pub(crate) AndroidView => "android.view.View",
    type_map = {
        WindowInsets => "android.view.WindowInsets",
    },
    methods {
        // Nullable: returns null before the window's first layout pass.
        fn get_root_window_insets() -> WindowInsets,
    },
}

bind_java_type! {
    pub(crate) WindowInsets => "android.view.WindowInsets",
    methods {
        // Deprecated in favor of `getInsets(WindowInsets.Type)` (API 30+),
        // but it's simple, single-purpose, and available since API 20 --
        // well below this app's min_sdk of 24 -- so it needs no SDK_INT
        // branching to stay correct across every supported OS version.
        fn get_system_window_inset_top() -> jint,
    },
}

fn query(env: &mut Env, activity_ptr: jni::sys::jobject) -> jni::errors::Result<i32> {
    // Safety: `activity_ptr` is an unowned JNI global reference to the app's
    // real Activity, valid for as long as the `AndroidApp` it came from is
    // alive (which outlives this call). We only borrow it via `as_cast_raw`,
    // never wrap or drop it as if we owned it.
    let activity = unsafe { env.as_cast_raw::<Global<AndroidActivity>>(&activity_ptr) }?;
    let window = activity.get_window(env)?;
    let decor_view = window.get_decor_view(env)?;
    let insets = decor_view.get_root_window_insets(env)?;
    if insets.is_null() {
        return Ok(0);
    }
    insets.get_system_window_inset_top(env)
}

/// Returns the current status bar height in physical pixels, or `0` if it
/// can't be determined yet (e.g. before the window's first layout pass).
pub fn status_bar_inset_top_px(app: &winit::platform::android::activity::AndroidApp) -> i32 {
    // Safety: both pointers come straight from `AndroidApp`, which winit
    // populates with the process's real JavaVM/Activity before any Rust
    // code runs. Called on the calling thread, no cross-thread hand-off.
    let vm = unsafe { JavaVM::from_raw(app.vm_as_ptr().cast()) };
    let activity_ptr = app.activity_as_ptr() as jni::sys::jobject;

    match vm.attach_current_thread(|env| query(env, activity_ptr)) {
        Ok(px) => px,
        Err(err) => {
            log::error!("status_bar_inset_top_px: {err}");
            0
        }
    }
}
