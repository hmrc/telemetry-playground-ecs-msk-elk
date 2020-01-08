
ecs-create ecs-up ecs-down ecs-svc-up ecs-svc-down ecs-svc-redeploy:
	-cd front && make $@ &
	-cd back && make $@ &
.PHONY: ecs-create ecs-up ecs-down ecs-svc-up ecs-svc-down ecs-svc-redeploy

 build ecr-login ecr-repo ecr-tag ecr-push:
	-cd front && make $@
	-cd back && make $@
.PHONY: build ecr-login ecr-repo ecr-tag ecr-push
