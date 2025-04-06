GITLAB_USERNAME ?= root

KUBE_CONFIG ?= ../../kubernetes/gitlab/kubeconfig.yaml
KUBE_NAMESPACE ?= gitlab
KUBE_CTL ?= kubectl
KUBE_ARGS ?= --kubeconfig=$(KUBE_CONFIG) -n $(KUBE_NAMESPACE)

# Check if SSH public key exists
ifneq ("$(wildcard ~/.ssh/id_*.pub)","")
SSH_KEY_CONTENT := $(shell cat ~/.ssh/id_*.pub)
else
$(error No SSH public key found in ~/.ssh/id_*.pub)
endif

ifeq (, $(shell which $(KUBE_CTL)))
$(error "kubectl is not installed or not in PATH. Please install it to proceed.")
endif

# Ruby code to trust the SSH key for the GitLab user
define TRUST_SSH_KEY_SCRIPT
	key = Key.new(
		title: 'import',
		key: '$(SSH_KEY_CONTENT)',
		user_id: User.find_by(username: '$(GITLAB_USERNAME)').id
	)

	if key.save
	  puts "SSH key successfully trusted for user '$(GITLAB_USERNAME)'."
	else
	  puts "Failed to trust SSH key: #{key.errors.full_messages.join(', ')}"
	  exit 1
	end
endef

export TRUST_SSH_KEY_SCRIPT

help: ## Show this help message
	@grep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

kubernetes/run: ## Use kubectl to invoke the GitLab Rails console and trust the SSH key
	@echo "$$TRUST_SSH_KEY_SCRIPT" | \
		$(KUBE_CTL) $(KUBE_ARGS) exec -i -c toolbox deploy/gitlab-toolbox \
		-- gitlab-rails runner -

debug/print-script: ## Print the Ruby script used to trust the SSH key
	@echo "$$TRUST_SSH_KEY_SCRIPT"
