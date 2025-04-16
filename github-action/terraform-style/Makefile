ACT_CMD = act -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:full-24.04 \
	--action-offline-mode \
	--container-options "--group-add $$(stat -c %g /var/run/docker.sock)"

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

run: ## Run Terraform style checks using act
	@echo "Running Terraform style checks using act..."
	@$(ACT_CMD) pull_request --workflows terraform-style.yml
