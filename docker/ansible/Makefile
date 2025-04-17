help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

start: ## Start the Ansible container
	docker compose up -d

stop: ## Stop the Ansible container
	docker compose down

exec: ## Execute the example playbook inside the Ansible container
	docker compose exec ansible ansible-playbook example-playbook.yml

shell: ## Open a shell in the running Ansible container
	docker compose exec ansible sh

run/playbook: ## Execute the example playbook inside a new Ansible container
	docker compose run --rm ansible ansible-playbook example-playbook.yml

run/shell: ## Open a shell in a new Ansible container
	docker compose run --rm ansible sh
