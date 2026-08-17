use eframe::egui;

#[cfg(target_os = "android")]
mod android_insets;
#[cfg(target_os = "android")]
mod android_toast;

#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
fn android_main(app: winit::platform::android::activity::AndroidApp) {
    android_logger::init_once(
        android_logger::Config::default().with_max_level(log::LevelFilter::Info),
    );

    // `eframe::NativeOptions` takes ownership of `app` below, so keep our own
    // clone to query live window insets every frame. `AndroidApp` is a cheap
    // `Clone` handle onto shared state, not a duplicate activity.
    let android_app = app.clone();

    let options = eframe::NativeOptions {
        android_app: Some(app),
        ..Default::default()
    };
    eframe::run_native(
        "Memory Toast",
        options,
        Box::new(move |cc| {
            let mut my_app = MyApp::new(cc);
            my_app.android_app = Some(android_app);
            Ok(Box::new(my_app))
        }),
    )
    .unwrap();
}

/// Reads this process's own resident set size from `/proc/self/status`,
/// which the kernel exposes identically on desktop Linux and on Android
/// (both are Linux), so this same code path runs on both.
fn memory_usage_string() -> Option<String> {
    let status = std::fs::read_to_string("/proc/self/status").ok()?;

    let field = |name: &str| -> Option<u64> {
        status
            .lines()
            .find_map(|line| line.strip_prefix(name))?
            .split_whitespace()
            .next()?
            .parse()
            .ok()
    };

    let rss_kb = field("VmRSS:")?;
    let virt_kb = field("VmSize:").unwrap_or(0);

    Some(format!(
        "Memory in use: {:.1} MB\n(virtual: {:.1} MB)",
        rss_kb as f64 / 1024.0,
        virt_kb as f64 / 1024.0,
    ))
}

pub struct MyApp {
    last_reading: Option<String>,
    // Handle used to read the window's live status bar inset every frame;
    // see `android_insets`. `eframe`/`winit` don't surface this themselves.
    #[cfg(target_os = "android")]
    android_app: Option<winit::platform::android::activity::AndroidApp>,
}

impl MyApp {
    pub fn new(_cc: &eframe::CreationContext<'_>) -> Self {
        Self {
            last_reading: None,
            #[cfg(target_os = "android")]
            android_app: None,
        }
    }
}

impl eframe::App for MyApp {
    fn ui(&mut self, ui: &mut egui::Ui, _frame: &mut eframe::Frame) {
        // Clear the status bar. On Android, the system's edge-to-edge
        // defaults have shifted across OS versions (older releases already
        // excluded the status bar from the window's content area; newer
        // ones draw full-bleed under it by default), so a fixed constant
        // can't track the real, device-specific inset. Query the live
        // `WindowInsets` via JNI instead -- see `android_insets` for why
        // that's used in preference to `android-activity`'s content-rect API.
        #[cfg(target_os = "android")]
        if let Some(app) = &self.android_app {
            let top_inset_px = android_insets::status_bar_inset_top_px(app);
            ui.add_space(top_inset_px as f32 / ui.ctx().pixels_per_point());
        }
        #[cfg(not(target_os = "android"))]
        ui.add_space(24.0);

        ui.heading("Memory Usage Demo");
        ui.separator();
        ui.add_space(8.0);

        ui.label(
            self.last_reading
                .as_deref()
                .unwrap_or("Press the button to check memory usage."),
        );

        ui.add_space(12.0);

        if ui.button("Show Memory Usage").clicked() {
            if let Some(text) = memory_usage_string() {
                #[cfg(target_os = "android")]
                android_toast::show_toast(&text);

                #[cfg(not(target_os = "android"))]
                println!("[toast] {text}");

                self.last_reading = Some(text);
            }
        }
    }
}
