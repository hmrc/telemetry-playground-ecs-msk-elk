
ecs-create ecs-up ecs-down ecs-svc-up ecs-svc-down:
	-cd kafka-manager && make $@ &
	-cd kafdrop && make $@ &
	-cd ksql && make $@ &
.PHONY: ecs-create ecs-up ecs-down ecs-svc-up ecs-svc-down
