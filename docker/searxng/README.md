# Running SearXNG using Docker

This exercise demonstrates how SearXNG's official Docker image can be used to
run a self-hosted metasearch engine.

## Context

I have been playing around with a self-hosted LLM and wanted to explore options
that would allow the LLM to perform web searches. One of the commonly
recommended solutions is SearXNG, which takes care of making calls to various
search engines and aggregating the results in a variety of formats.

This exercise aims to run SearXNG within Docker. It does not cover the use of
an MCP service or any other ways to hook up SearXNG to a self-hosted LLM.
