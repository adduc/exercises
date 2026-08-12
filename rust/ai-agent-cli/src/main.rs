mod agent;
mod commands;
mod config;
mod llm;
mod repl;
mod tools;

use std::path::PathBuf;

use clap::Parser;

#[derive(Parser)]
struct Cli {
    /// Path to the TOML config file.
    #[arg(long, default_value = "agent.toml")]
    config: PathBuf,
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    let cli = Cli::parse();
    let config = config::Config::load(&cli.config)?;

    let llm = llm::LlmClient::new(
      config.llm.base_url.clone(),
      config.llm.api_key.clone()
    );

    let mut registry = tools::ToolRegistry::new();
    registry.register(Box::new(tools::CurrentTimeTool));

    let agent = agent::Agent::new(&config, llm, registry);

    repl::run(agent).await;
    Ok(())
}
