# playground-ecs-msk-elk

Play with the AWS MSK service. Produce and consume a topic via logstash and ingest to Elasticsearch.

The following services and associated ECS tasks are deployed:

| Service | docker compose |
|---:|:---|
| [elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/6.8/index.html) | [elk/elasticsearch/docker-compose.yml](elk/elasticsearch/docker-compose.yml) |
| [kibana](https://www.elastic.co/guide/en/kibana/6.8/index.html) | [elk/kibana/docker-compose.yml](elk/kibana/docker-compose.yml) |
| [logstash-consumer](https://www.elastic.co/guide/en/logstash/6.8/index.html) | [elk/logstash/consumer/docker-compose.yml](elk/logstash/consumer/docker-compose.yml) |
| [logstash-producer](https://www.elastic.co/guide/en/logstash/6.8/index.html) | [elk/logstash/producer/docker-compose.yml](elk/logstash/producer/docker-compose.yml) |
| [kafka-manager](https://github.com/yahoo/kafka-manager) | [kafka/kafka-manager/docker-compose.yml](kafka/kafka-manager/docker-compose.yml) |
| [kafdrop](https://github.com/obsidiandynamics/kafdrop) | [kafka/kafdrop/docker-compose.yml](kafka/kafdrop/docker-compose.yml) |
| [ksql](https://github.com/confluentinc/ksql) | [kafka/ksql/docker-compose.yml](kafka/ksql/docker-compose.yml) |


| Task | docker compose |
|---:|:---|
| [haggar](https://github.com/gorsuch/haggar) | [metrics/haggar/docker-compose.yml](metrics/haggar/docker-compose.yml) |

NOTE: If external resource changes (for example MSK cluster) you'll need to re-deploy since service configurations are baked into ECS task and service definitions.

## Set-up

* Install [ecs-cli](https://github.com/aws/amazon-ecs-cli)
* Install [jq](https://github.com/stedolan/jq)
* Install [kafka](https://kafka.apache.org/downloads) [2.12-2.3.1](https://www.apache.org/dyn/closer.cgi?path=/kafka/2.3.1/kafka_2.12-2.3.1.tgz)
* Clone this repository
* Enable [Task Networking](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html#task-networking-considerations)

```
make ecs-task-networking
```

NOTE: Ensure you `aws-profile` wrap any invocation of `make`

## Uploading artifacts to ECR

Do the following to build and upload images to ECR:
* `cd elk/logstash`
* `make ecr-repo # Do this if ECR repsoitories don't exist`
* `make build ecr-tag ecr-login ecr-push`

## Managing stack

Do the following to create the stack:
* `make ecs-svc-up # Bring the ECS services up (includes service discovery)`
* `make ecs-svc-down # Bring the ECS services down`

TODO: Automate SG rule to allow ECS to access MSK

## Managing metric source

Do the following to manage the metrics source workflow:
* `cd metrics/haggar`
* `make ecs-create # Create the metrics task`
* `make ecs-up # Run the metrics task with default prefix 'haggar'`
* `make ecs-down # Stop the metrics task`

To set a custom prefix for haggar use:
* `cd metrics/haggar`
* `make ecs-up -e METRIC_ROOT=gonzo # Run the metrics task with custom prefix 'gonzo'`

## SSH tunnel to ECS EC2 host

To set up the port mappings from your localhost to the ECS cluster, Zookeeper and Kafka broker run:
```
make ecs-tunnel-up
```

Open listed URI's in a browser to validate the port mappings.

To connect to KSQL run the following:
```
docker run --network host -it confluentinc/cp-ksql-cli:latest http://localhost:38088
```

To check Zookeeper connectivity run:
```
echo ruok | nc localhost 32181
```

To check kafka connectivity run:
```
nc -zv localhost 39092
```

To take down the port mappings run:
```
make ecs-tunnel-down
```

## Standard make targets

| Target | Description |
|---:|:---|
| build | Build images |
| ecr-login | Login to ECR |
| ecr-push | Push locally built images to ECR |
| ecr-repo | Create ECR repository |
| ecr-tag | Tag locally built images for ECR |
| ecs-config | Dump configured docker-compose.yml |
| ecs-create | Create ECS task |
| ecs-down | Take down ECS task |
| ecs-svc-down | Taked down ECS service |
| ecs-svc-up | Bring up ECS service |
| ecs-tunnel-down | Take down the ssh port mappings to ECS services | 
| ecs-tunnel-up | Set up the ssh port mappings to ECS services |
| ecs-up | Bring up ECS task |
| msk-topic-create | Create and configure playground kafka topic NOTE: Run only if `make ecs-tunnel-up ecs-tunnel-check` is OK |
| var-dump | Dump the make variables set for AWS/ECS/MSK |

## Restarting a service

```bash
aws-profile -p <profile> \
    aws ecs --cluster=telemetry update-service --force-new-deployment --service=<service-name>
```

## Troubleshooting

### AssumeRoleTokenProviderNotSetError: assume role with MFA enabled, but AssumeRoleTokenProvider session option not set.

If the following command is run `ecs-cli ps --cluster telemetry` and the above error is produced, it should be
confirmed with `env | grep AWS` that you do not have `AWS_PROFILE` environment variable set. If the variable *is* set then
run `unset AWS_PROFILE` to remove the variable. The issue is that currently the tool does not support MFA role profiles.

Further information: 
[amazon-ecs-cli credentials order of precedence](https://github.com/aws/amazon-ecs-cli/blob/3970a6c1f38bc750ff9c068f53220aa177c7df54/ecs-cli/modules/config/config_v1.go#L108)

### MSK can not be reached

* Check the MSK security group rules by running `make msk-dump-sg`
* Check the SSH tunnel by running `make ecs-tunnel-check`
