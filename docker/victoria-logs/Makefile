help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

start: ## Start VictoriaLogs container
	@echo "Starting victoria-logs container..."
	docker compose up -d

stop: ## Stop VictoriaLogs container
	@echo "Stopping victoria-logs container..."
	docker compose down

log: ## Send example logs to VictoriaLogs
	@echo "Sending example logs to Loki..."
	@echo -e \
		'{ "log": { "level": "info", "message": "hello world" }, "date": "0", "stream": "stream1" }'"\n"\
		'{ "log": { "level": "error", "message": "oh no!" }, "date": "0", "stream": "stream1" }'"\n"\
		'{ "log": { "level": "info", "message": "hello world" }, "date": "0", "stream": "stream2" }'"\n"\
	| curl -X POST -H 'Content-Type: application/stream+json' --data-binary @- \
		'http://localhost:9428/insert/jsonline?_stream_fields=stream&_time_field=date&_msg_field=log.message'

query/all: ## Query all logs
	@echo "Querying all logs..."
	curl -s http://localhost:9428/select/logsql/query -d 'query=*' | jq

query/stream: ## Query logs from a specific stream
	@echo "Querying logs from stream1..."
	curl -s http://localhost:9428/select/logsql/query -d 'query=stream:"stream1"' | jq

query/log-level: ## Query logs with a specific log level
	@echo "Querying logs with level 'info'..."
	curl -s http://localhost:9428/select/logsql/query -d 'query=log.level:"info"' | jq
