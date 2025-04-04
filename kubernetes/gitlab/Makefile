help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

k3s/clean: ## Tear down the k3s cluster and remove all data
	docker compose kill
	docker compose rm -f
	sudo rm -rf data/k3s-server

gitlab/recreate: ## Recreate the GitLab instance, useful for resetting the environment
	terraform destroy -auto-approve
	kubectl --kubeconfig=kubeconfig.yaml wait --for=delete namespace gitlab --timeout=300s
	terraform apply -auto-approve

	$(MAKE) gitlab/set-root-theme

gitlab/set-root-theme: ## Set the GitLab root user theme (dark mode where possible)
	@echo "Setting GitLab root user theme..."

	echo "puts User.find_by(username: 'root').update(theme_id: 1, color_mode_id: 3, color_scheme_id: 2)" \
		| kubectl --kubeconfig=kubeconfig.yaml -n gitlab exec -i -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails runner -

	@echo "Root user theme updated."

gitlab/create-root-personal-access-token: ## Create a Personal Access Token for the GitLab root user
	@echo "Creating a new GitLab Personal Access Token for the root user..."

	echo "puts User.find_by(username: 'root').personal_access_tokens.create(name: 'token', scopes: ['api'], expires_at: 1.year.from_now).token" \
		| kubectl --kubeconfig=kubeconfig.yaml -n gitlab exec -i -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails runner - \
		> root_access_token.txt

	@echo "Personal Access Token created and saved to root_access_token.txt"

gitlab/trust-ssh-key: ## Trust the SSH key for the GitLab instance by adding it to the authorized keys
	@echo "Trusting SSH key for GitLab..."

	echo "Key.new(title: 'import', key: '$(shell cat ~/.ssh/id_*.pub)', user_id: User.find_by(username: 'root').id).save" \
		| kubectl --kubeconfig=kubeconfig.yaml -n gitlab exec -i -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails runner -

	@echo "SSH key trusted."

# Key.new(title: "import", key: "$(shell cat ~/.ssh/id_*.pub)", user_id: User.find_by(username: 'root'))

gitlab/rails-console: ## Open the GitLab Rails console for debugging or administrative tasks
	@echo "Opening GitLab Rails console..."
	kubectl --kubeconfig=kubeconfig.yaml -n gitlab exec -it -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails console
