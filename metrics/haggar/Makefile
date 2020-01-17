include ../../common.mk

METRIC_ROOT:=haggar

ecs-create:
	env METRIC_ROOT=$(METRIC_ROOT) ecs-cli compose --cluster $(ECS_CLUSTER_NAME) create
.PHONY: ecs-create

ecs-up:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) up
.PHONY: ecs-up

ecs-down:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) down
.PHONY: ecs-down

ecs-config:
	@env METRIC_ROOT=$(METRIC_ROOT) docker-compose config
.PHONY: ecs-config
