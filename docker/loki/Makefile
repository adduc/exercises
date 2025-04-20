help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

start: ## Start Loki in a Docker container
	@echo "Starting Loki..."
	@docker compose up -d

stop: ## Stop Loki Docker container
	@echo "Stopping Loki..."
	@docker compose down

log: ## Send a sample log entry to Loki
	@echo "Pushing log entry to Loki..."
	@curl -s -X POST \
		-H "Content-Type: application/json" \
		"http://localhost:3100/loki/api/v1/push" \
		--data-raw "{\"streams\": [{ \"stream\": { \"service\": \"foobar\", \"foo\": \"bar\" }, \"values\": [ [ \"$$(date +%s%N)\", \"fizzbuzz\" ] ] }]}"

query/service_name: ## Query Loki for logs with label {service_name="foobar"}
	@echo "Querying Loki for logs with label {service_name=\"foobar\"}..."
	@curl http://localhost:3100/loki/api/v1/query_range \
		--url-query "query={service_name=\"foobar\"}" \
		| jq ".data.result[0].values"

query/foo: ## Query Loki for logs with label {foo="bar"}
	@echo "Querying Loki for logs with label {foo=\"bar\"}..."
	@curl http://localhost:3100/loki/api/v1/query_range \
		--url-query "query={foo=\"bar\"}" \
		| jq ".data.result[0].values"
