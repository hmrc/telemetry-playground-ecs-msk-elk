export COMPOSE_PROJECT_NAME=tel-1287
export COMPOSE_NETWORK=$(COMPOSE_PROJECT_NAME)_default
export ARTIFACTORY_FQDN ?= artefacts.tax.service.gov.uk

.PHONY: default
default: help

.PHONY: help
help: ## Help on targets
	@grep --no-filename -E '^[a-zA-Z1-9_-]+\s*:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: lazydocker
lazydocker: ## lazydocker the stack
	@env COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) lazydocker

export DOCKER_STACK_YAML ?= -f docker-compose.yaml

.PHONY: up down logs config ps rm exec
up down logs config ps rm exec stop: ## Invoke docker-compose $@ $(args) $(svc)
	docker-compose $(DOCKER_STACK_YAML) $@ $(args) $(svc)

.PHONY: stack-up
stack-up: args ?= -d --build
stack-up: up ## Stack up and scale (set 'svc' to filter services)

.PHONY: stack-down
stack-down: down ## Stack down (stop and remove containers, networks, images, and volumes)

.PHONY: stack-tail
stack-tail: args ?= "-f"
stack-tail: logs ## Stack tail logs (set 'svc' to filter services)

.PHONY: stack-network
stack-network: ## Stack network inspect
	@docker network inspect $(COMPOSE_NETWORK)

.PHONY: sh-collectd
sh-collectd: ## Get an interactive shell in a collectd container
	@docker-compose run --rm collectd bash

.PHONY: sh-logstash
sh-logstash: ## Get an interactive shell in a logstash container
	@docker-compose run --rm --entrypoint=sh logstash

.PHONY: test
test: ## Run the tests in the logstash collectd plugin
	@cd collectd/mdtp_scripts/collectd_logstash && \
	ls -la && \
	poetry run pytest --cov=telemetry_collectd_logstash tests
