include ../../common.mk

IMAGE_NAME=telemetry-log-proxy
IMAGE_TAG=$(IMAGE_NAME):latest
IMAGE_TAG_ECR=$(AWS_ECR_REG)/$(IMAGE_NAME)
export KAFKA_METRICS_TOPIC=tel-1753-metrics
export KAFKA_LOGS_TOPIC=tel-1753-logs
export MSK_BOOTSTRAP_BROKERS=b-2.msk-cluster.j74qvp.c4.kafka.eu-west-2.amazonaws.com:9092,b-1.msk-cluster.j74qvp.c4.kafka.eu-west-2.amazonaws.com:9092,b-3.msk-cluster.j74qvp.c4.kafka.eu-west-2.amazonaws.com:9092
export KAFKA_BROKER_1=b-1.msk-cluster.j74qvp.c4.kafka.eu-west-2.amazonaws.com:9092
export KAFKA_BROKER_2=b-2.msk-cluster.j74qvp.c4.kafka.eu-west-2.amazonaws.com:9092
export KAFKA_BROKER_3=b-3.msk-cluster.j74qvp.c4.kafka.eu-west-2.amazonaws.com:9092

DC_ENV_VARS=KAFKA_BROKER_1=$(KAFKA_BROKER_1) KAFKA_BROKER_2=$(KAFKA_BROKER_1) KAFKA_BROKER_3=$(KAFKA_BROKER_1) MSK_BOOTSTRAP_BROKERS=$(MSK_BOOTSTRAP_BROKERS) KAFKA_METRICS_TOPIC=${KAFKA_METRICS_TOPIC} KAFKA_LOGS_TOPIC=${KAFKA_LOGS_TOPIC}

all: build ecr-tag

dc-up:
	env $(DC_ENV_VARS) docker-compose up
.PHONY: dc-up

dc-down:
	docker-compose down
.PHONY: dc-down
