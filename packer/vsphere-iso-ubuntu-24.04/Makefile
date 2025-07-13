help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Packer (and install plugins if necessary)
	packer init .

build: ## Build the VM image using Packer
	packer build .

build-debug: ## Build the VM image using Packer with debug logging enabled
	@echo "Building VM image in debug mode..."
	PACKER_LOG=10 PACKER_LOG_PATH=packer.log packer build .
