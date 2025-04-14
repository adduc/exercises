GITLAB_USERNAME ?= root

KUBE_CONFIG ?= ../../kubernetes/gitlab/kubeconfig.yaml
KUBE_NAMESPACE ?= gitlab
KUBE_CTL ?= kubectl
KUBE_ARGS ?= --kubeconfig=$(KUBE_CONFIG) -n $(KUBE_NAMESPACE)

ifeq (, $(shell which $(KUBE_CTL)))
$(error "kubectl is not installed or not in PATH. Please install it to proceed.")
endif

# Check for .env file
ifneq ("$(wildcard .env)","")
include .env
else
$(error ".env file not found. Please create a .env file from .dist.env")
endif

define CREATE_ACCESS_TOKEN_SCRIPT
	result = User.find_by(username: '$(GITLAB_USERNAME)').personal_access_tokens.create(
		name: 'preseed',
		scopes: ['api'],
		expires_at: 1.year.from_now,
		token_digest: Gitlab::CryptoHelper.sha256('$(TOKEN)')
	)

	if result
	  puts "Personal Access Token successfully created for user '$(GITLAB_USERNAME)'."
	else
	  puts "Failed to create Personal Access Token: #{result.errors.full_messages.join(', ')}"
	  exit 1
	end
endef

export CREATE_ACCESS_TOKEN_SCRIPT

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

kubernetes/run: ## Run script using kubectl to invoke the GitLab Rails console
	@echo "Creating a new GitLab Personal Access Token for user '$(GITLAB_USERNAME)'..."
	@echo "$$CREATE_ACCESS_TOKEN_SCRIPT" | \
		$(KUBE_CTL) $(KUBE_ARGS) exec -i -c toolbox deploy/gitlab-toolbox \
		-- gitlab-rails runner -

debug/print-script: ## Print the Ruby script used to set the user theme
	@echo "$$CREATE_ACCESS_TOKEN_SCRIPT"
