use super::{Command, CommandOutcome, CommandRegistry};
use crate::agent::Agent;

pub struct ExitCommand;

impl Command for ExitCommand {
    fn name(&self) -> &str {
        "exit"
    }

    fn description(&self) -> &str {
        "Exit the program"
    }

    fn execute(&self, _agent: &Agent, _registry: &CommandRegistry) -> CommandOutcome {
        CommandOutcome::Exit
    }
}
