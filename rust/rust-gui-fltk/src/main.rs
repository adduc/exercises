use fltk::{app, button::Button, frame::Frame, group::Flex, prelude::*, window::Window};
use sysinfo::{Pid, ProcessesToUpdate, System};

fn main() {
    let app = app::App::default();

    let mut window = Window::default().with_size(320, 200).with_label("FLTK Demo");

    let mut flex = Flex::default_fill().column();
    flex.set_margin(20);
    flex.set_spacing(10);

    let mut hello_label = Frame::default().with_label("Hello, World!");
    hello_label.set_label_size(20);

    let mut button = Button::default().with_label("Check Memory Usage");

    let mut memory_label = Frame::default().with_label("");

    flex.end();
    window.end();
    window.show();

    let pid = Pid::from_u32(std::process::id());

    button.set_callback(move |_| {
        let mut sys = System::new();
        sys.refresh_processes(ProcessesToUpdate::Some(&[pid]), true);
        if let Some(process) = sys.process(pid) {
            let mem_mb = process.memory() as f64 / 1024.0 / 1024.0;
            memory_label.set_label(&format!("Memory usage: {:.2} MB", mem_mb));
        }
    });

    app.run().unwrap();
}
