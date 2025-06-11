# Generating PR Reviews using Qodo's PR Agent

This exercise demonstrates how Qodo's PR agent can be used to generate pull request reviews using a large language model (LLM). The agent is designed to analyze pull requests and provide feedback on code quality, potential issues, and suggestions for improvements.

## Context

Over the past few months, I have found value in using GitHub's Copilot for reviewing pull requests against personal projects. However, I wanted to explore other options that could be tuned and potentially self-hosted. Qodo's PR agent is an open-source project that uses LLMs to analyze pull requests and provide feedback, making it a suitable candidate for this exercise.

## Lessons Learned

While Qodo's PR agent is open-source, almost half of the advertised features are gated to their paid product, which does not allow self-hosting except for its highest tier.

While I was able to install the agent into an Alpine Linux container without a lot of trouble, I found it difficult to configure as it seemingly does not support a traditional configuration file, opting to use environment variables or python scripts instead. Additionally, error messages were not very helpful, and the documentation was sparse.

Running the agent against a PR multiple times resulted in different recommendations. I used a smaller model to speed up the process which might have contributed to the inconsistency, but I suspect that it's inherent to the use of LLMs for this task, and would still occur with larger models.
