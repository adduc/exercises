use super::{Command, CommandOutcome, CommandRegistry};
use crate::agent::Agent;

pub struct HelpCommand;

impl Command for HelpCommand {
    fn name(&self) -> &str {
        "help"
    }

    fn description(&self) -> &str {
        "Show this list of commands"
    }

    fn execute(&self, _agent: &Agent, registry: &CommandRegistry) -> CommandOutcome {
        println!("Commands:");
        for command in registry.sorted() {
            println!("  /{:<10} {}", command.name(), command.description());
        }
        CommandOutcome::Continue
    }
}
