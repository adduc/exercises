use memory_toast::MyApp;

fn main() -> eframe::Result {
    eframe::run_native(
        "Memory Toast",
        eframe::NativeOptions::default(),
        Box::new(|cc| Ok(Box::new(MyApp::new(cc)))),
    )
}
