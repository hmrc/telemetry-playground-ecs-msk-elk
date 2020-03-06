IMAGE_NAME=logs-proxy
IMAGE_TAG=$(IMAGE_NAME):latest
IMAGE_TAG_ECR=$(AWS_ECR_REG)/$(IMAGE_NAME)

include ../../common.mk

all: build ecr-tag ecr-push

ECS_ENV_VARS=MSK_BOOTSTRAP_BROKERS=$(MSK_BOOTSTRAP_BROKERS) IMAGE_TAG=$(AWS_ECR_REG)/$(IMAGE_TAG)
ECS_CLI_ARGS= --cluster $(ECS_CLUSTER_NAME) --project-name $(IMAGE_NAME)

ecs-create:
	env $(ECS_ENV_VARS) ecs-cli compose $(ECS_CLI_ARGS) create
.PHONY: ecs-create

ecs-up:
	env $(ECS_ENV_VARS) ecs-cli compose $(ECS_CLI_ARGS) up
.PHONY: ecs-up

ecs-down:
	ecs-cli compose $(ECS_CLI_ARGS) down
.PHONY: ecs-down

ecs-config:
	@env $(ECS_ENV_VARS) docker-compose config
.PHONY: ecs-config

ecs-svc-up:
	env $(ECS_ENV_VARS) ecs-cli compose $(ECS_CLI_ARGS) service up $(ECS_SVC_DISCOVER)
.PHONY: ecs-svc-up

ecs-svc-down:
	ecs-cli compose $(ECS_CLI_ARGS) service down
.PHONY: ecs-svc-down
