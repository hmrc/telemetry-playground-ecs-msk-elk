
ecs-create ecs-up ecs-down ecs-svc-up ecs-svc-down:
	-cd producer && make $@ &
	-cd consumer && make $@ &
.PHONY: ecs-create ecs-up ecs-down ecs-svc-up ecs-svc-down

 build ecr-login ecr-repo ecr-tag ecr-push:
	-cd producer && make $@
	-cd consumer && make $@
.PHONY: build ecr-login ecr-repo ecr-tag ecr-push
