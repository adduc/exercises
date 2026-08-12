use rustyline::DefaultEditor;
use rustyline::error::ReadlineError;

use crate::agent::Agent;
use crate::commands::{CommandOutcome, CommandRegistry, ExitCommand, HelpCommand, HistoryCommand};

pub async fn run(mut agent: Agent) {
    let mut editor = DefaultEditor::new().expect("failed to initialize line editor");

    let mut commands = CommandRegistry::new();
    commands.register(Box::new(HelpCommand));
    commands.register(Box::new(HistoryCommand));
    commands.register(Box::new(ExitCommand));

    loop {
        match editor.readline("> ") {
            Ok(line) => {
                let line = line.trim();
                if line.is_empty() {
                    continue;
                }
                editor.add_history_entry(line).ok();

                if let Some(name) = line.strip_prefix('/') {
                    match commands.get(name) {
                        Some(command) => match command.execute(&agent, &commands) {
                            CommandOutcome::Continue => continue,
                            CommandOutcome::Exit => break,
                        },
                        None => {
                            println!("Unknown command: /{name} (try /help)");
                            continue;
                        }
                    }
                }

                match agent.handle_user_turn(line).await {
                    Ok(response) => println!("{response}"),
                    Err(err) => eprintln!("error: {err:#}"),
                }
            }
            Err(ReadlineError::Interrupted) | Err(ReadlineError::Eof) => break,
            Err(err) => {
                eprintln!("readline error: {err}");
                break;
            }
        }
    }
}
