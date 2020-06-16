export COMPOSE_PROJECT_NAME=tel-1287
export COMPOSE_NETWORK=$(COMPOSE_PROJECT_NAME)_default
export ARTIFACTORY_FQDN ?= artefacts.tax.service.gov.uk

.PHONY: default
default: help

.PHONY: help
help: ## Help on targets
	@grep --no-filename -E '^[a-zA-Z1-9_-]+\s*:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: help-md
help-md:
	@$(MAKE) -s help|sort|awk '{ printf "|"$$1;$$1="";print "|"$$0"|";}'

.PHONY: all-up
all-up: ## all up everything
	$(MAKE) stack-up
	$(MAKE) source-up

.PHONY: all-down
all-down: ## all down everything
	-$(MAKE) source-down
	-$(MAKE) stack-down


## Utility targets
.PHONY: clean
clean: ## Remove data/ and pprofs/
	-sudo rm -fr data/ pprofs/

.PHONY: yamllint
yamllint: ## YML lint docker-compose YAML
	$@ -d "{extends: relaxed, rules: {line-length: {max: 200}}}"  docker-compose*.yaml

.PHONY: lazydocker
lazydocker: ## lazydocker the stack
	@env COMPOSE_PROJECT_NAME=$(COMPOSE_PROJECT_NAME) lazydocker

.PHONY: wireshark
wireshark: ## Wireshark the metrics stack network bridge
	@echo "##" Service IP Addresses
	@docker network inspect --format='{{range .Containers}}{{println .IPv4Address .Name}}{{end}}'  $(COMPOSE_NETWORK) | sed -e 's!/..!!g' | sort -k 2
	@echo ""
	@$@ -k -i br-`docker network inspect $(COMPOSE_NETWORK) --format '{{ .Id }}' | cut -c1-12`

.PHONY: scope-launch
scope-launch: ## [scope](https://www.weave.works/oss/scope/) launch
	scope launch

.PHONY: scope-stop
scope-stop: ## scope stop
	scope stop

## METRICS STACK
export DOCKER_STACK_YAML ?= -f docker-compose.yaml -f docker-compose.local.yaml

.PHONY: up down logs config ps rm exec
up down logs config ps rm exec stop: ## Invoke docker-compose $@ $(args) $(svc)
	docker-compose $(DOCKER_STACK_YAML) $@ $(args) $(svc)

.PHONY: stack-up
stack-up: args ?= -d
stack-up: up ## Stack up and scale (set 'svc' to filter services)

.PHONY: stack-down
stack-down: down ## Stack down (stop and remove containers, networks, images, and volumes)

.PHONY: stack-tail
stack-tail: args ?= "-f"
stack-tail: logs ## Stack tail logs (set 'svc' to filter services)

.PHONY: stack-network
stack-network: ## Stack network inspect
	@docker network inspect $(COMPOSE_NETWORK)

.PHONY: scale
scale: svc ?= _OVERRIDE_
scale: size ?= 0
scale: ## Scale a 'svc' by 'size'
	docker-compose $(DOCKER_STACK_YAML) $@ $(svc)=$(size)

.PHONY: recycle
recycle: ## Recycle a service (set 'svc' to recycle)
	-$(MAKE) scale svc=$(svc) size=0
	$(MAKE) scale svc=$(svc) size=1

.PHONY: clickhouse-client
clickhouse-client: ## Invoke clickhose-client
	docker-compose exec clickhouse bash -c "export HOME=/var/lib/clickhouse/ ; exec clickhouse client"

.PHONY: clickhouse_metric_paths
clickhouse_metric_paths: db_table ?= graphite.graphite_tree
clickhouse_metric_paths: ## Dump concrete metric paths (default is 'db_table=graphite.graphite_tree')
	docker exec clickhouse bash -c "export HOME=/var/lib/clickhouse/ ; echo 'select Path from $(db_table) order by Path'| clickhouse client" | egrep -v -E '\.$$' -

.PHONY: heap_carbon-clickhouse
heap_carbon-clickhouse: scratch_dir ?= pprofs
heap_carbon-clickhouse: pprof_file ?= $@_$(shell date +%s).pprof
heap_carbon-clickhouse: ## Heap dump carbon-clickhouse
	@mkdir -p $(scratch_dir)
	cd $(scratch_dir) \
	&& curl -sK -vd http://localhost:8081/debug/pprof/heap > $(pprof_file) \
	&& go tool pprof -png $(pprof_file) > $(pprof_file).png 2>/dev/null \
	&& go tool pprof -top $(pprof_file) > $(pprof_file).top 2>/dev/null \
	&& go tool pprof -http=":" $(pprof_file)

.PHONY: carbon-relay-meta
carbon-relay-meta: ## Dump the relay meta spool file
	@echo '## crng_graphite-relay'
	@docker-compose exec crng_graphite-relay ash -c 'cat /var/spool/carbon-relay-ng/spool_*.meta.dat'
	@echo '## crng_clickhouse'
	@docker-compose exec crng_clickhouse ash -c 'cat /var/spool/carbon-relay-ng/spool_*.meta.dat'


## SOURCES output data into the stack

.PHONY: source-up
source-up: ## source up everything
	$(MAKE) envoy-up
	$(MAKE) play-up

.PHONY: source-down
source-down: ## source down everything
	-$(MAKE) play-down
	-$(MAKE) envoy-down

### envoy statsd metrics
ENVOY_COMPOSE = docker-compose.source_envoy.yaml
export ENVOY_IMAGE = $(ARTIFACTORY_FQDN)/aws-ecs-envoy:v1.12.3.0-prod-0.21.0

.PHONY: envoy-image
envoy-image: ## aws-ecs-envoy image pull from Artifactory
	docker image inspect -f '{{.Id}}' $(ENVOY_IMAGE) || { docker login $(ARTIFACTORY_FQDN) && docker pull $(ENVOY_IMAGE) ; }

.PHONY: envoy-up
envoy-up: envoy-image ## aws-ecs-envoy container up
	docker-compose -f $(ENVOY_COMPOSE) up -d

.PHONY: envoy-down
envoy-down: ## aws-ecs-envoy container down
	-docker-compose -f $(ENVOY_COMPOSE) down

### play metrics
PLAY_COMPOSE=docker-compose.source_platform-status-backend.yaml

.PHONY: play-up
play-up: ## platform-status-backend container up
	docker-compose -f $(PLAY_COMPOSE) up -d

.PHONY: envoy-down
play-down: ## platform-status-backend container down
	-docker-compose -f $(PLAY_COMPOSE) down
