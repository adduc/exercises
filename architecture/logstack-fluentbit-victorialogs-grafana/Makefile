help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

bootstrap: ## Create necessary directories and set permissions
	@echo "Creating necessary directories and setting permissions..."
	@mkdir -p data/{grafana,victoria-logs,fluent-bit}
	@sudo chown 472 data/grafana

reset: ## Stop and remove containers, and clear data directories
	@echo "Stopping and removing containers, and clearing data directories..."
	@docker compose kill
	@docker compose down
	@sudo rm -rf data/grafana/* data/victoria-logs/* data/fluent-bit/* watch/a.log

up: ## Start the containers in detached mode
	@echo "Starting containers in detached mode..."
	@docker compose up -d

down: ## Stop the containers
	@echo "Stopping the containers..."
	@docker compose down

logs: ## Display logs for all containers
	@echo "Displaying logs for all containers..."
	@docker compose logs -f

create-log-entry: ## Create a sample log entry in watch/a.log
	@echo "Creating sample log entry..."
	echo "asdfasdf $RANDOM" >> watch/a.log
