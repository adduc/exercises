# Running Loki in Docker for log aggregation

This exercise demonstrates how Loki can be used to aggregate logs from multiple Docker containers. Loki is a log aggregation system designed to work seamlessly with Grafana.

## Usage

A makefile is provided to simplify the process of running Loki in Docker. The following commands are available:
- `make help`: Display a help message with available commands.
- `make start`: Start Loki in Docker.
- `make stop`: Stop and remove the Loki container.
- `make log`: Send a sample log entry to Loki.
- `make query/service_name`: Query Loki for logs with label `{service_name="foobar"}`
- `make query/foo`: Query Loki for logs with label `{foo="bar"}`


## Thoughts

- Unlike prometheus, Loki does not provide a web interface for querying
  logs. Instead, it is designed to be queried through its API (which a
  dashboard solution like Grafana can use).
- While Loki does support indexing labels, it does not have an optimized
  solution for storing labels with high cardinality. This means that
  labels with many unique values (like user IDs or session IDs) can lead
  to performance issues.
