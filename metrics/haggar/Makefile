include ../../common.mk

METRIC_ROOT:=$(if $(METRIC_ROOT),$(METRIC_ROOT),haggar)
RIEMANN_PRODUCER_DNS:=$(if $(RIEMANN_PRODUCER_DNS),$(RIEMANN_PRODUCER_DNS),riemann-front.telemetry.internal)
RIEMANN_PRODUCER_PORT:=$(if $(RIEMANN_PRODUCER_PORT),$(RIEMANN_PRODUCER_PORT),3003)

ENV_VARS=METRIC_ROOT=$(METRIC_ROOT) RIEMANN_PRODUCER_DNS=$(RIEMANN_PRODUCER_DNS) RIEMANN_PRODUCER_PORT=$(RIEMANN_PRODUCER_PORT)

ecs-create:
	env $(ENV_VARS) ecs-cli compose --cluster $(ECS_CLUSTER_NAME) create
.PHONY: ecs-create

ecs-up:
	env $(ENV_VARS) ecs-cli compose --cluster $(ECS_CLUSTER_NAME) up
.PHONY: ecs-up

ecs-down:
	ecs-cli compose --cluster $(ECS_CLUSTER_NAME) down
.PHONY: ecs-down

ecs-config:
	@env $(ENV_VARS) docker-compose config
.PHONY: ecs-config
