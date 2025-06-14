help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

start: ## Start the Ansible container
	docker compose up -d

stop: ## Stop the Ansible container
	docker compose down

server-shell: ## Open a shell in the Ansible container
	docker compose exec -u ansible server bash

target-shell: ## Open a shell in the target container
	docker compose exec -u ansible target bash

ansible-playbook: ## Execute the example playbook
	docker compose exec -u ansible server ansible-playbook -i inventory.yml playbook.yml

ansible-playbook-debug: ## Execute the example playbook with debug mode
	docker compose exec -u ansible -e ANSIBLE_DEBUG=1 server ansible-playbook -i inventory.yml playbook.yml

install-requirements: ## Install Ansible requirements
	docker compose exec -u ansible server ansible-galaxy install -r requirements.yml
