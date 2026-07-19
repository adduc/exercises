use sysinfo::{Pid, ProcessesToUpdate, System};

slint::include_modules!();

fn main() -> Result<(), slint::PlatformError> {
    let window = AppWindow::new()?;

    let weak_window = window.as_weak();
    window.on_check_memory_usage(move || {
        let window = weak_window.unwrap();

        let pid = Pid::from_u32(std::process::id());
        let mut system = System::new();
        system.refresh_processes(ProcessesToUpdate::Some(&[pid]), true);

        let text = match system.process(pid) {
            Some(process) => {
                let memory_mb = process.memory() as f64 / (1024.0 * 1024.0);
                format!("Memory usage: {:.2} MB", memory_mb)
            }
            None => "Memory usage: unavailable".to_string(),
        };

        window.set_memory_usage_text(text.into());
    });

    window.run()
}
