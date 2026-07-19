use gtk4::prelude::*;
use gtk4::{Application, ApplicationWindow, Box as GtkBox, Button, Label, Orientation};
use sysinfo::{ProcessRefreshKind, ProcessesToUpdate, System};

const APP_ID: &str = "org.example.HelloWorld";

fn main() {
    // Defaults to the lighter renderer (avoids libLLVM + Mesa Vulkan backends, ~37 MB RSS) but lets GSK_RENDERER override if already set.
    if std::env::var("GSK_RENDERER").is_err() {
        unsafe {
            std::env::set_var("GSK_RENDERER", "cairo");
        }
    }

    let app = Application::builder().application_id(APP_ID).build();
    app.connect_activate(build_ui);
    app.run();
}

fn build_ui(app: &Application) {
    let label = Label::builder().label("Hello, World!").build();

    let memory_label = Label::new(None);
    let memory_label_for_button = memory_label.clone();

    let button = Button::with_label("Show Memory Usage");
    button.connect_clicked(move |_| {
        let text = match current_memory_usage_bytes() {
            Some(bytes) => format!("Memory usage: {:.2} MB", bytes as f64 / 1024.0 / 1024.0),
            None => "Memory usage: unavailable".to_string(),
        };
        memory_label_for_button.set_text(&text);
    });

    let vbox = GtkBox::new(Orientation::Vertical, 8);
    vbox.set_margin_top(16);
    vbox.set_margin_bottom(16);
    vbox.set_margin_start(16);
    vbox.set_margin_end(16);
    vbox.append(&label);
    vbox.append(&button);
    vbox.append(&memory_label);

    let window = ApplicationWindow::builder()
        .application(app)
        .title("Hello, World")
        .default_width(360)
        .default_height(200)
        .child(&vbox)
        .build();

    window.present();
}

fn current_memory_usage_bytes() -> Option<u64> {
    let pid = sysinfo::get_current_pid().ok()?;
    let mut system = System::new();
    system.refresh_processes_specifics(
        ProcessesToUpdate::Some(&[pid]),
        false,
        ProcessRefreshKind::nothing().with_memory(),
    );
    system.process(pid).map(|process| process.memory())
}
