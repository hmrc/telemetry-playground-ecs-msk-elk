include ../../common.mk

ecs-create:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) create
.PHONY: ecs-create

ecs-up:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) up
.PHONY: ecs-up

ecs-down:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) down
.PHONY: ecs-down

ecs-config:
	@docker-compose config
.PHONY: ecs-config

ecs-svc-up:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) service up $(ECS_SVC_DISCOVER)
.PHONY: ecs-svc-up

ecs-svc-down:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) service down
.PHONY: ecs-svc-down
