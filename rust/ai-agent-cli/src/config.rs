use std::path::Path;

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};

const DEFAULT_SYSTEM_PROMPT: &str = "You are a helpful assistant with access to tools. Use them when they help answer the user's question.";

#[derive(Debug, Clone, Default, Deserialize, Serialize)]
#[serde(default)]
pub struct Config {
    pub llm: LlmConfig,
    pub agent: AgentConfig,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default)]
pub struct LlmConfig {
    pub base_url: String,
    pub api_key: Option<String>,
    pub model: String,
}

impl Default for LlmConfig {
    fn default() -> Self {
        Self {
            base_url: "http://localhost:8080/v1".to_string(),
            api_key: None,
            model: "local-model".to_string(),
        }
    }
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default)]
pub struct AgentConfig {
    pub system_prompt: String,
}

impl Default for AgentConfig {
    fn default() -> Self {
        Self {
            system_prompt: DEFAULT_SYSTEM_PROMPT.to_string(),
        }
    }
}

impl Config {
    pub fn load(path: &Path) -> Result<Self> {
        let mut config = if path.exists() {
            let text = std::fs::read_to_string(path)
                .with_context(|| format!("failed to read config file {}", path.display()))?;
            toml::from_str(&text)
                .with_context(|| format!("failed to parse config file {}", path.display()))?
        } else {
            Config::default()
        };

        if let Ok(key) = std::env::var("AGENT_API_KEY") {
            config.llm.api_key = Some(key);
        }

        Ok(config)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_when_file_missing() {
        let config = Config::load(Path::new("/nonexistent/agent.toml")).unwrap();
        assert_eq!(config.llm.base_url, "http://localhost:8080/v1");
        assert_eq!(config.llm.model, "local-model");
    }

    #[test]
    fn partial_toml_fills_in_defaults() {
        let toml_text = r#"
            [llm]
            model = "qwen2.5-7b"
        "#;
        let config: Config = toml::from_str(toml_text).unwrap();
        assert_eq!(config.llm.model, "qwen2.5-7b");
        assert_eq!(config.llm.base_url, "http://localhost:8080/v1");
    }
}
