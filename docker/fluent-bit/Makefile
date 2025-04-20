help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

log: ## Send an example syslog message
	echo "<165>1 $(shell date +%Y-%m-%dT%H:%M:%S.%N%z) 192.0.2.1 myproc 8710 - - %% It's time to make the do-nuts." \
	| nc -u -w1 127.0.0.1 5140
