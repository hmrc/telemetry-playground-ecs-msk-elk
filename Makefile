include common.mk

ecs-create ecs-up ecs-down ecs-svc-down:
	-cd kafka && make $@ &
	-cd elk && make $@ &
.PHONY: ecs-create ecs-up ecs-down ecs-svc-down

ecs-svc-up:
	-cd kafka && make $@ &
	-cd elk && make $@ &
.PHONY: ecs-svc-up
