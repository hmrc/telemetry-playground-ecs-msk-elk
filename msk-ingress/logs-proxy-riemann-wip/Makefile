include ../../common.mk

export KAFKA_METRICS_TOPIC=tel-1753-metrics
export KAFKA_LOGS_TOPIC=logs

DC_ENV_VARS=MSK_BOOTSTRAP_BROKERS=$(MSK_BOOTSTRAP_BROKERS) KAFKA_METRICS_TOPIC=${KAFKA_METRICS_TOPIC} KAFKA_LOGS_TOPIC=${KAFKA_LOGS_TOPIC}

dc-up:
	env $(DC_ENV_VARS) docker-compose up --build
.PHONY: dc-up

dc-down:
	docker-compose down
.PHONY: dc-down
