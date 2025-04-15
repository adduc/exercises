help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

run: ## Run the GitLab CI pipeline locally
	# @see https://github.com/firecow/gitlab-ci-local
	gitlab-ci-local --cwd ../.. manual-inputs
