.PHONY: help build run watch

help: ## Show this help message
	@echo "Usage: make [target]..."
	@echo ""
	@echo "Targets:"
	@grep -h '\s##\s' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}' | sort

## Build Commands

build: build/server ## Build all binaries

build/server: ## Build the server binary
	go build -o bin/server cmd/server/main.go

## Run Commands

run: ## Run all binaries
	$(MAKE) -j1 run/server

run/server: ## Run the web server
	go run cmd/server/main.go

## Test Commands

test: ## Run tests
	go test ./... -v

## Watch Commands (relies on gow)
# @see https://github.com/mitranim/gow

watch: ## Watch for changes and run all binaries
	$(MAKE) -j1 watch/server

watch/server: ## Watch for changes and run the web server
	gow -e=go,html,env -w . run cmd/server/main.go

watch/test: ## Watch for changes and run tests
	gow -e=go -w . test ./... -v

# @todo implement "bootstrap"
