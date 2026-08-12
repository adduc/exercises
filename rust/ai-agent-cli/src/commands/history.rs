use super::{Command, CommandOutcome, CommandRegistry};
use crate::agent::Agent;

pub struct HistoryCommand;

impl Command for HistoryCommand {
    fn name(&self) -> &str {
        "history"
    }

    fn description(&self) -> &str {
        "Show the current conversation history"
    }

    fn execute(&self, agent: &Agent, _registry: &CommandRegistry) -> CommandOutcome {
        print!("{}", agent.debug_history());
        CommandOutcome::Continue
    }
}
