mod types;

pub use types::{
    ChatCompletionRequest, ChatCompletionResponse, FunctionDef, Message, ToolDefinition,
};

use anyhow::{Context, Result, bail};

pub struct LlmClient {
    http: reqwest::Client,
    base_url: String,
    api_key: Option<String>,
}

impl LlmClient {
    pub fn new(base_url: String, api_key: Option<String>) -> Self {
        Self {
            http: reqwest::Client::new(),
            base_url,
            api_key,
        }
    }

    pub async fn chat_completion(
        &self,
        request: &ChatCompletionRequest,
    ) -> Result<ChatCompletionResponse> {
        let url = format!("{}/chat/completions", self.base_url.trim_end_matches('/'));

        let mut builder = self.http.post(&url).json(request);
        if let Some(key) = &self.api_key {
            builder = builder.bearer_auth(key);
        }

        let response = builder
            .send()
            .await
            .with_context(|| format!("failed to reach LLM endpoint at {url}"))?;

        let status = response.status();
        if !status.is_success() {
            let body = response.text().await.unwrap_or_default();
            bail!("LLM endpoint returned {status}: {body}");
        }

        response
            .json::<ChatCompletionResponse>()
            .await
            .context("failed to parse LLM response")
    }
}
