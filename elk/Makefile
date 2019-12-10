
ecs-create ecs-up ecs-down ecs-svc-down:
	-cd elasticsearch && make $@ &
	-cd kibana && make $@ &
	-cd logstash && make $@ &
.PHONY: ecs-create ecs-up ecs-down ecs-svc-down

ecs-svc-up:
	-cd elasticsearch && make $@
	-cd kibana && make $@
	-cd logstash && make $@
.PHONY: ecs-svc-up
