ifneq ($(wildcard .env),)
include .env
else
$(info no .env file found)
endif

ifeq ($(GITHUB__USER_TOKEN),)
$(error GITHUB__USER_TOKEN is not set. Please set it in the .env file or pass it as an argument.)
endif

ifeq ($(PR_URL),)
$(error PR_URL is not set. Please set it in the .env file or pass it as an argument.)
endif

DOCKER_ENV_VARS = \
	-e GITHUB__USER_TOKEN=$(GITHUB__USER_TOKEN) \
	-e CONFIG__MODEL=ollama/qwen2.5-coder:7b \
	-e CONFIG__CUSTOM_MODEL_MAX_TOKENS=128000 \
	-e OLLAMA__API_BASE=http://172.17.0.1:11434

review:
	docker run -t -i $(DOCKER_ENV_VARS) \
	codiumai/pr-agent:latest \
			--pr_url=$(PR_URL) review

improve:
	docker run -t -i $(DOCKER_ENV_VARS) \
	codiumai/pr-agent:latest \
			--pr_url=$(PR_URL) improve --extended

run:
	docker run -t -i $(DOCKER_ENV_VARS) \
	codiumai/pr-agent:latest \
			--pr_url=$(PR_URL)
