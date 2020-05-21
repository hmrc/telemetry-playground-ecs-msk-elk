COMMON_MK_DIR=$(dir $(realpath $(lastword $(MAKEFILE_LIST))))

# Check that aws-profile variable set
ifndef AWS_SECRET_ACCESS_KEY
  $(error AWS_SECRET_ACCESS_KEY not set)
endif

# Use 'bash' and not 'sh'
export SHELL = /bin/bash

export KAFKA_TOPIC=logs
export ES_PORT?=9200

# image LABEL's
export VCS_REF := $(if $(VCS_REF),$(VCS_REF),$(shell git rev-parse --short HEAD))
export VCS_URL := $(if $(VCS_URL),$(VCS_URL),$(shell git ls-remote --get-url origin))
BUILD_DATE=$(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
BUILD_ARGS=--build-arg BUILD_DATE=$(BUILD_DATE) --build-arg VCS_REF=$(VCS_REF) --build-arg VCS_URL=$(VCS_URL)

# AWS dependent variables. Invocations of awscli kept to a minimum.
# Terraform state files are used to set variables.
export AWS_ACCOUNT_ID := $(if $(AWS_ACCOUNT_ID),$(AWS_ACCOUNT_ID),$(shell aws sts get-caller-identity --query Account --output text))
export AWS_ECR_REG := $(if $(AWS_ECR_REG),$(AWS_ECR_REG),$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com)

# Attempt to get terraform state (check for meta-module then per module)
export S3_BUCKET := $(if $(S3_BUCKET),$(S3_BUCKET),$(shell aws s3 ls 2>/dev/null| awk 'match($$3,/^tfstate-telemetry-internal/) { print $$NF }'))
ifeq ($(S3_BUCKET),)
  $(error S3_BUCKET: not set)
else
  $(info S3_BUCKET: $(S3_BUCKET))
endif

MSK_TFSTATE_TMP := $(COMMON_MK_DIR).msk-tfstate.tmp
$(info MSK_state file: $(MSK_TFSTATE_TMP))
ECS_TFSTATE_TMP := $(COMMON_MK_DIR).ecs-tfstate.tmp
$(info ECS state file: $(ECS_TFSTATE_TMP))
SGS_TFSTATE_TMP := $(COMMON_MK_DIR).sgs-tfstate.tmp
$(info security-groups state file: $(SGS_TFSTATE_TMP))

$(shell aws s3 cp s3://$(S3_BUCKET)/common/msk/terraform.tfstate - > $(MSK_TFSTATE_TMP))
$(shell aws s3 cp s3://$(S3_BUCKET)/common/ecs/terraform.tfstate - > $(ECS_TFSTATE_TMP))
$(shell aws s3 cp s3://$(S3_BUCKET)/core/security-groups/terraform.tfstate - > $(SGS_TFSTATE_TMP))

export MSK_BOOTSTRAP_BROKERS := $(if $(MSK_BOOTSTRAP_BROKERS),$(MSK_BOOTSTRAP_BROKERS),$(shell jq -r '.resources[]|select(.type=="aws_msk_cluster")|.instances[].attributes.bootstrap_brokers' < <(cat $(MSK_TFSTATE_TMP))))
export MSK_CLUSTER_NAME := $(if $(MSK_CLUSTER_NAME),$(MSK_CLUSTER_NAME),$(shell jq -r '.resources[]|select(.type=="aws_msk_cluster")|.instances[].attributes.cluster_name' < <(cat $(MSK_TFSTATE_TMP))))
export MSK_CLUSTER_ARN := $(if $(MSK_CLUSTER_ARN),$(MSK_CLUSTER_ARN),$(shell jq -r '.resources[]|select(.type=="aws_msk_cluster")|.instances[].attributes.arn' < <(cat $(MSK_TFSTATE_TMP))))
export MSK_ZK := $(if $(MSK_ZK),$(MSK_ZK),$(shell jq -r '.resources[]|select(.type=="aws_msk_cluster")|.instances[].attributes.zookeeper_connect_string' < <(cat $(MSK_TFSTATE_TMP))))
export MSK_SG := $(if $(MSK_SG),$(MSK_SG),$(shell jq -r '.resources[]|select(.name=="msk_cluster")|.instances[]|.attributes.id' < <(cat $(SGS_TFSTATE_TMP))))
export ECS_CLUSTER_NAME := $(if $(ECS_CLUSTER_NAME),$(ECS_CLUSTER_NAME),$(shell jq -r '.resources[]|select(.type=="aws_ecs_cluster")|.instances[].attributes.name' < <(cat $(ECS_TFSTATE_TMP))))
export ECS_SEC_GROUP := $(if $(ECS_SEC_GROUP),$(ECS_SEC_GROUP),$(shell jq -r '.resources[]|select(.name=="ecs_node")|.instances[].attributes.id' < <(cat $(SGS_TFSTATE_TMP))))
export ECS_SUBNET_1 := $(if $(ECS_SUBNET_1),$(ECS_SUBNET_1),$(shell jq -r '.resources[]|select(.name=="ecs_nlb")|.instances[].attributes.subnets[0]' < <(cat $(ECS_TFSTATE_TMP))))
export ECS_SUBNET_2 := $(if $(ECS_SUBNET_2),$(ECS_SUBNET_2),$(shell jq -r '.resources[]|select(.name=="ecs_nlb")|.instances[].attributes.subnets[1]' < <(cat $(ECS_TFSTATE_TMP))))
export ECS_SUBNET_3 := $(if $(ECS_SUBNET_3),$(ECS_SUBNET_3),$(shell jq -r '.resources[]|select(.name=="ecs_nlb")|.instances[].attributes.subnets[2]' < <(cat $(ECS_TFSTATE_TMP))))
export ECS_EC2_IPS := $(if $(ECS_EC2_IPS),$(ECS_EC2_IPS),$(shell aws ec2 describe-instances --filters "Name=instance.group-id,Values=$(ECS_SEC_GROUP)" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text | sort))
export ECS_EC2_IP := $(if $(ECS_EC2_IP),$(ECS_EC2_IP),$(shell echo $(ECS_EC2_IPS) | cut -d' ' -f1))
export ECS_VPC := $(if $(ECS_VPC),$(ECS_VPC),$(shell jq -r '.resources[]|select(.name=="ecs_node_sg")|.instances[].attributes.vpc_id' < <(cat $(ECS_TFSTATE_TMP))))
export ECS_DNS_NAMESPACE?=playground
export ECS_SVC_DISCOVER?=--private-dns-namespace $(ECS_DNS_NAMESPACE) --vpc $(ECS_VPC) --enable-service-discovery

## Targets

build:
	docker build -t $(IMAGE_TAG) $(BUILD_ARGS) .
.PHONY: build

ecr-login:
	eval `aws ecr get-login --region $(AWS_REGION) --no-include-email`
.PHONY: ecr-login

ecr-tag:
	-docker rmi $(IMAGE_TAG_ECR)
	docker tag `docker images --filter=reference=$(IMAGE_TAG) --format "{{.ID}}"` $(IMAGE_TAG_ECR)
.PHONY: ecr-tag

ecr-repo:
	-aws ecr create-repository --repository-name $(IMAGE_NAME)
.PHONY: ecr-repo

ecr-push: ecr-login
	docker push $(AWS_ECR_REG)/$(IMAGE_NAME)
.PHONY: ecr-push

ecs-tunnel-up: DNS_ELASTICSEARCH=elasticsearch.$(ECS_DNS_NAMESPACE)
ecs-tunnel-up: DNS_KIBANA=kibana.$(ECS_DNS_NAMESPACE)
ecs-tunnel-up: DNS_KAFKA_MANAGER=kafka-manager.$(ECS_DNS_NAMESPACE)
ecs-tunnel-up: DNS_KAFDROP=kafdrop.$(ECS_DNS_NAMESPACE)
ecs-tunnel-up: DNS_KSQL=ksql.$(ECS_DNS_NAMESPACE)
ecs-tunnel-up: DNS_ZK=$(shell echo $(MSK_ZK) | tr "," "\n" | sort | head -1 | cut -d: -f1 )
ecs-tunnel-up: DNS_BROKER=$(shell echo $(MSK_BOOTSTRAP_BROKERS) | tr "," "\n" | sort | head -1 | cut -d: -f1 )
ecs-tunnel-up:
	@echo "INFO: Bring up port mappings"
	@echo "http://localhost:35601 kibana"
	@echo "http://localhost:39200 elasticsearch"
	@echo "http://localhost:39000 kafka-manager"
	@echo "http://localhost:39001 kafdrop"
	@echo "http://localhost:38088 ksql"
	@echo "localhost:32181 zookeeper"
	@echo "localhost:39092 kafka PLAINTEXT"
	ssh  $(ECS_EC2_IP) -L 35601:$(DNS_KIBANA):5601 -L 39200:$(DNS_ELASTICSEARCH):9200 -L 39000:$(DNS_KAFKA_MANAGER):9000  -L 39001:$(DNS_KAFDROP):9000 -L 38088:$(DNS_KSQL):8088 -L 39092:$(DNS_BROKER):9092 -L 32181:$(DNS_ZK):2181
.PHONY: ssh_tunnel_ec2

ecs-tunnel-down: DNS_ELASTICSEARCH=elasticsearch.$(ECS_DNS_NAMESPACE)
ecs-tunnel-down: DNS_KIBANA=kibana.$(ECS_DNS_NAMESPACE)
ecs-tunnel-down: DNS_KAFKA_MANAGER=kafka-manager.$(ECS_DNS_NAMESPACE)
ecs-tunnel-down: DNS_KAFDROP=kafdrop.$(ECS_DNS_NAMESPACE)
ecs-tunnel-down: DNS_KSQL=ksql.$(ECS_DNS_NAMESPACE)
ecs-tunnel-down: DNS_ZK=$(shell echo $(MSK_ZK) | tr "," "\n" | sort | head -1 | cut -d: -f1 )
ecs-tunnel-down: DNS_BROKER=$(shell echo $(MSK_BOOTSTRAP_BROKERS) | tr "," "\n" | sort | head -1 | cut -d: -f1 )
ecs-tunnel-down:
	@echo "INFO: Take down port mappings"
	ssh  $(ECS_EC2_IP) -L 35601:$(DNS_KIBANA):5601 -L 39200:$(DNS_ELASTICSEARCH):9200 -L 39000:$(DNS_KAFKA_MANAGER):9000  -L 39001:$(DNS_KAFDROP):9000 -L 38088:$(DNS_KSQL):8088 -L 39092:$(DNS_BROKER):9092 -L 32181:$(DNS_ZK):2181 -O cancel
.PHONY: ssh_tunnel_ec2

ecs-task-networking:
	aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com
.PHONY: ecs-task-networking

msk-dump-sg: MSK_SG=$(shell aws kafka describe-cluster --cluster-arn $(MSK_CLUSTER_ARN) --query 'ClusterInfo.BrokerNodeGroupInfo.SecurityGroups' --output text)
msk-dump-sg:
	aws ec2 describe-security-groups --group-ids $(MSK_SG)
.PHONY: msk-dump-sg

ecs-tunnel-check:
	@echo `nc -w 5 -zv localhost 39092` localhost:39092 kafka PLAINTEXT
	@echo `echo ruok | nc -w 5 localhost 32181` localhost:32181 zookeeper
	@echo `curl -s -o /dev/null --max-time 5 -w "%{http_code}" http://localhost:35601` http://localhost:35601 kibana
	@echo `curl -s -o /dev/null --max-time 5 -w "%{http_code}" http://localhost:39200` http://localhost:39200 elasticsearch
	@echo `curl -s -o /dev/null --max-time 5 -w "%{http_code}" http://localhost:39000` http://localhost:39000 kafka-manager
	@echo `curl -s -o /dev/null --max-time 5 -w "%{http_code}" http://localhost:39001` http://localhost:39001 kafdrop
	@echo `curl -s -o /dev/null --max-time 5 -w "%{http_code}" http://localhost:38088` http://localhost:38088 ksql
.PHONY: ecs-tunnel-check

var-dump:
	@env | egrep -v '_TFSTATE|^AWS_SECRET_ACCESS_KEY|^AWS_SESSION_TOKEN|^AWS_ACCESS_KEY_ID' | egrep '^AWS_|^ECS_|^MSK_|^S3_' | sort
.PHONY: var-dump

msk-topic-create:
	-kafka-topics.sh --create --bootstrap-server localhost:39092 --replication-factor 1 --partitions 3 --topic $(KAFKA_TOPIC)
	-kafka-topics.sh --zookeeper localhost:32181 --alter --config retention.ms=3600000 --topic $(KAFKA_TOPIC)
	-kafka-topics.sh --bootstrap-server localhost:39092 --describe --topic $(KAFKA_TOPIC)
.PHONY: kafka-topic-create
