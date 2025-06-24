TF_CMD := tofu

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

run: ## Start the k3s cluster and apply the example
	$(MAKE) start
	$(TF_CMD) init
	$(TF_CMD) apply -auto-approve

start: ## Start the k3s cluster (does not create the example)
	docker compose up -d --wait

stop: ## Stop the k3s cluster
	docker compose down

reset: ## Stop and remove all data
	docker compose down -t0
	sudo rm -rf data/
