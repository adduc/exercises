use anyhow::{Result, anyhow, bail};

use crate::config::Config;
use crate::llm::{ChatCompletionRequest, LlmClient, Message};
use crate::tools::ToolRegistry;

const MAX_TOOL_ITERATIONS: usize = 8;

pub struct Agent {
    llm: LlmClient,
    model: String,
    tools: ToolRegistry,
    history: Vec<Message>,
}

impl Agent {
    pub fn new(config: &Config, llm: LlmClient, tools: ToolRegistry) -> Self {
        let history = vec![Message::system(config.agent.system_prompt.clone())];
        Self {
            llm,
            model: config.llm.model.clone(),
            tools,
            history,
        }
    }

    /// Debug view of the current history: message count and a truncated
    /// preview of each message's role and content.
    pub fn debug_history(&self) -> String {
        let mut out = format!("{} messages in history\n", self.history.len());
        for (i, m) in self.history.iter().enumerate() {
            let preview: String = m
                .content
                .as_deref()
                .unwrap_or("")
                .chars()
                .take(60)
                .collect();
            out.push_str(&format!("  [{i}] {:?}: {preview}\n", m.role));
        }
        out
    }

    pub async fn handle_user_turn(&mut self, input: &str) -> Result<String> {
        self.history.push(Message::user(input));

        let tool_definitions = if self.tools.is_empty() {
            None
        } else {
            Some(self.tools.tool_definitions())
        };

        for _ in 0..MAX_TOOL_ITERATIONS {
            let request = ChatCompletionRequest {
                model: self.model.clone(),
                messages: self.history.clone(),
                tools: tool_definitions.clone(),
            };

            let response = self.llm.chat_completion(&request).await?;
            let message = response
                .choices
                .into_iter()
                .next()
                .ok_or_else(|| anyhow!("LLM response contained no choices"))?
                .message;

            let tool_calls = message.tool_calls.clone();
            self.history.push(message.clone());

            let Some(tool_calls) = tool_calls.filter(|calls| !calls.is_empty()) else {
                return Ok(message.content.unwrap_or_default());
            };

            for call in tool_calls {
                let arguments: serde_json::Value =
                    serde_json::from_str(&call.function.arguments).unwrap_or_default();

                let result = match self.tools.execute(&call.function.name, arguments).await {
                    Ok(result) => result,
                    Err(err) => format!("Error: {err}"),
                };

                self.history.push(Message::tool_result(call.id, result));
            }
        }

        bail!("agent exceeded {MAX_TOOL_ITERATIONS} tool-call iterations without a final answer")
    }
}
