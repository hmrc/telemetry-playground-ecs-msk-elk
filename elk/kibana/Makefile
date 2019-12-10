include ../../common.mk

ecs-create:
	env ES_HOST=elasticsearch.$(ECS_DNS_NAMESPACE) ecs-cli compose --cluster $(ECS_CLUSTER_NAME) create
.PHONY: ecs-create

ecs-up:
	env ES_HOST=elasticsearch.$(ECS_DNS_NAMESPACE) ecs-cli compose --cluster $(ECS_CLUSTER_NAME) up
.PHONY: ecs-up

ecs-down:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) down
.PHONY: ecs-down

ecs-config:
	@env ES_HOST=elasticsearch.$(ECS_DNS_NAMESPACE) docker-compose config
.PHONY: ecs-config

ecs-svc-up:
	env ES_HOST=elasticsearch.$(ECS_DNS_NAMESPACE) ecs-cli compose --cluster $(ECS_CLUSTER_NAME) service up $(ECS_SVC_DISCOVER)
.PHONY: ecs-svc-up

ecs-svc-down:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) service down
.PHONY: ecs-svc-down

ecs-index-default:
	./ecs-default-index.sh
.PHONY: ecs-index-default
