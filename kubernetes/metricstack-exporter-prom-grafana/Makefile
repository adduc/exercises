TF_CMD := tofu

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

up: ## Start the k3s cluster and apply Terraform configuration
	docker compose up -d --wait
	$(TF_CMD) init
	$(TF_CMD) apply -auto-approve

down: ## Stop the k3s cluster
	docker compose down

clean: ## Stop the k3s cluster and remove all data
	docker compose down --timeout 0 --volumes
	sudo rm -rf data/
