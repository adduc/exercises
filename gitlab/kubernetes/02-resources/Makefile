TF_CMD := tofu


help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

k3s/clean: ## Tear down the k3s cluster and remove all data
	docker compose kill
	docker compose rm -f
	sudo rm -rf data/k3s-server

gitlab/recreate: ## Recreate the GitLab instance, useful for resetting the environment
	$(TF_CMD) destroy -auto-approve

	[ ! -f ../kubeconfig.yaml ] || kubectl --kubeconfig=../kubeconfig.yaml wait --for=delete namespace gitlab --timeout=300s
	$(TF_CMD) apply -auto-approve

	$(MAKE) -j4 \
		gitlab/trust-self-signed-cert \
		gitlab/set-root-theme \
		gitlab/create-root-personal-access-token \
		gitlab/trust-ssh-key
	@echo "GitLab instance recreated successfully."

gitlab/trust-self-signed-cert: ## Trust the self-signed certificate for the GitLab instance
	kubectl --kubeconfig=../kubeconfig.yaml -n gitlab get secrets/gitlab-wildcard-tls-chain -o json \
		| jq -r '.data.["gitlab.172.17.0.1.nip.io.crt"]' \
		| base64 -d \
		| sudo tee /etc/pki/ca-trust/source/anchors/dev-gitlab.pem \
		&& sudo update-ca-trust

gitlab/set-root-theme: ## Set the GitLab root user theme (dark mode where possible)
	@echo "Setting GitLab root user theme..."

	echo "puts User.find_by(username: 'root').update(theme_id: 1, color_mode_id: 3, color_scheme_id: 2)" \
		| kubectl --kubeconfig=../kubeconfig.yaml -n gitlab exec -i -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails runner -

	@echo "Root user theme updated."

gitlab/create-root-personal-access-token: ## Create a Personal Access Token for the GitLab root user
	@echo "Creating a new GitLab Personal Access Token for the root user..."

	TOKEN=$$($(TF_CMD) output -raw root_personal_access_token) \
	&& echo "User.find_by(username: 'root').personal_access_tokens.create(name: 'preseed', scopes: ['api', 'k8s_proxy'], expires_at: 1.year.from_now, token_digest: Gitlab::CryptoHelper.sha256('$$TOKEN'))" \
		| kubectl --kubeconfig=../kubeconfig.yaml -n gitlab exec -i -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails runner -

	@echo "Personal Access Token created"

gitlab/trust-ssh-key: ## Trust the SSH key for the GitLab instance by adding it to the authorized keys
	@echo "Trusting SSH key for GitLab..."

	echo "Key.new(title: 'import', key: '$(shell cat ~/.ssh/id_*.pub)', user_id: User.find_by(username: 'root').id).save" \
		| kubectl --kubeconfig=../kubeconfig.yaml -n gitlab exec -i -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails runner -

	@echo "SSH key trusted."

# Key.new(title: "import", key: "$(shell cat ~/.ssh/id_*.pub)", user_id: User.find_by(username: 'root'))

gitlab/rails-console: ## Open the GitLab Rails console for debugging or administrative tasks
	@echo "Opening GitLab Rails console..."
	kubectl --kubeconfig=../kubeconfig.yaml -n gitlab exec -it -c toolbox deployment.apps/gitlab-toolbox -- gitlab-rails console
