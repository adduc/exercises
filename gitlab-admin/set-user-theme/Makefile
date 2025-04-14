GITLAB_USERNAME ?= root

KUBE_CONFIG ?= ../../kubernetes/gitlab/kubeconfig.yaml
KUBE_NAMESPACE ?= gitlab
KUBE_CTL ?= kubectl
KUBE_ARGS ?= --kubeconfig=$(KUBE_CONFIG) -n $(KUBE_NAMESPACE)

ifeq (, $(shell which $(KUBE_CTL)))
$(error "kubectl is not installed or not in PATH. Please install it to proceed.")
endif

define SET_USER_THEME_SCRIPT
	result = User.find_by(username: '$(GITLAB_USERNAME)').
		update(theme_id: 1, color_mode_id: 3, color_scheme_id: 2)

	if result
	  puts "User theme successfully updated for user '$(GITLAB_USERNAME)'."
	else
	  puts "Failed to update user theme: #{result.errors.full_messages.join(', ')}"
	  exit 1
	end
endef

export SET_USER_THEME_SCRIPT

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

kubernetes/run: ## Run script using kubectl to invoke the GitLab Rails console
	@echo "Setting GitLab user theme for user '$(GITLAB_USERNAME)'..."
	@echo "$$SET_USER_THEME_SCRIPT" | \
		$(KUBE_CTL) $(KUBE_ARGS) exec -i -c toolbox deploy/gitlab-toolbox \
		-- gitlab-rails runner -

debug/print-script: ## Print the Ruby script used to set the user theme
	@echo "$$SET_USER_THEME_SCRIPT"
