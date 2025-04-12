FIND_EXCLUDE=-not -ipath '*/uncommitted/*' -not -ipath '*/vendor/*'

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

## Golang Recipes

golang-lint: ## Lint all Go exercises (in parallel)
	@echo "Linting all Go exercises (in parallel)..."
	@find $(FIND_EXCLUDE) -name 'go.mod' -exec dirname {} + \
		| xargs -t -P$(shell nproc) -i bash -c "cd {} && golangci-lint run --allow-parallel-runners"

golang-lint-serial: ## Lint all Go exercises (in serial)
	@echo "Linting all Go exercises (in serial)..."
	@find $(FIND_EXCLUDE) -name 'go.mod' -exec dirname {} + \
		| xargs -t -P1 -i bash -c "cd {} && golangci-lint run"

## PHP Recipes

php-lint: ## Lint all PHP exercises (in parallel)
	@echo "Linting all PHP exercises (in parallel)..."
	@find $(FIND_EXCLUDE) -name '*.php' -print0 | \
		xargs -0 -L200 -t -P$(shell nproc) php -l

php-lint-serial: ## Lint all PHP exercises (in serial)
	@echo "Linting all PHP exercises (in serial)..."
	@find $(FIND_EXCLUDE) -name '*.php' -print0 | \
		xargs -0 -L200 -t -P1 php -l

## CI Recipes

ACT_CMD = act -P ubuntu-24.04=ghcr.io/catthehacker/ubuntu:full-24.04

ci/act/pr-terraform: ## Run Terraform PR checks using act
	@echo "Running Terraform PR checks using act..."
	@$(ACT_CMD) pull_request -W .github/workflows/pr-terraform.yml
