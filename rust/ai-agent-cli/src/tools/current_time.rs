use anyhow::Result;
use chrono::Local;
use serde_json::json;

use super::Tool;

pub struct CurrentTimeTool;

#[async_trait::async_trait]
impl Tool for CurrentTimeTool {
    fn name(&self) -> &str {
        "current_time"
    }

    fn description(&self) -> &str {
        "Returns the current local date and time."
    }

    fn parameters_schema(&self) -> serde_json::Value {
        json!({
            "type": "object",
            "properties": {},
        })
    }

    async fn execute(&self, _arguments: serde_json::Value) -> Result<String> {
        Ok(Local::now().to_rfc2822())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn returns_a_plausible_timestamp() {
        let tool = CurrentTimeTool;
        let result = tool.execute(json!({})).await.unwrap();
        assert!(result.contains(&Local::now().format("%Y").to_string()));
    }
}
