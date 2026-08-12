mod exit;
mod help;
mod history;

pub use exit::ExitCommand;
pub use help::HelpCommand;
pub use history::HistoryCommand;

use std::collections::HashMap;

use crate::agent::Agent;

pub enum CommandOutcome {
    Continue,
    Exit,
}

pub trait Command: Send + Sync {
    fn name(&self) -> &str;
    fn description(&self) -> &str;
    fn execute(&self, agent: &Agent, registry: &CommandRegistry) -> CommandOutcome;
}

#[derive(Default)]
pub struct CommandRegistry {
    commands: HashMap<String, Box<dyn Command>>,
}

impl CommandRegistry {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn register(&mut self, command: Box<dyn Command>) {
        self.commands.insert(command.name().to_string(), command);
    }

    pub fn get(&self, name: &str) -> Option<&dyn Command> {
        self.commands.get(name).map(|c| c.as_ref())
    }

    /// Registered commands sorted by name, for stable /help output.
    pub fn sorted(&self) -> Vec<&dyn Command> {
        let mut commands: Vec<&dyn Command> = self.commands.values().map(|c| c.as_ref()).collect();
        commands.sort_by_key(|c| c.name());
        commands
    }
}
