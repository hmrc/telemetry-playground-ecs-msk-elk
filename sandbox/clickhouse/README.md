# Working locally with ClickHouse in Docker

## Requirements

* [Docker](https://docs.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)

## Getting started

For scenarios where it's desirable to work with [ClickHouse](https://clickhouse.tech/) locally, we use [sonych/clickhouse-cluster](https://github.com/sonych/clickhouse-cluster). I've forked it and made a few changes here [craigedmunds/clickhouse-cluster](https://github.com/craigedmunds/clickhouse-cluster).

In order to configure this generic repository to be a _"Telemetry ClickHouse"_ cluster, we modify the compose stack using a `docker-compose-override.xml`,
which bootstraps the `ch` containers using a Python script.

```bash
$ docker-compose \
    -f clickhouse-cluster/docker-compose.yml \
    -f dev-docker-compose-override.yml \
    build
$ docker-compose \
    -f clickhouse-cluster/docker-compose.yml \
    -f dev-docker-compose-override.yml \
    up
```

Wait for all 4 data nodes to show _"waiting for zk clickhouse.config.remote_servers, sleeping..."_ and then run the following command (simulating the lambda function has created the zk config):

```bash
$ for i in `seq 1 4`; do docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml exec -d "ch$i" clickhouse-docker.py; done

# Wait ~30 seconds for the command above to complete then:
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml exec ch1 clickhouse-docker.py create-remote-servers-node
```

Insert some simple data:

```bash
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml exec ch1 clickhouse-client -q "insert into graphite.graphite_tree (Date, Level, Path, Deleted, Version) values (toDate(now()), 1, '/metric/name', 0, 1);"
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml exec ch2 clickhouse-client -q "insert into graphite.graphite (Path, Value, Time, Date, Timestamp) values ('/metric/name', 1, now(), toDate(now()), toUnixTimestamp(now()));"
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml exec ch3 clickhouse-client -q "insert into graphite.graphite (Path, Value, Time, Date, Timestamp) values ('/metric/name', 2, now(), toDate(now()), toUnixTimestamp(now()));"
```

And then attempt to query data from the `_distributed` tables:

```bash
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml exec ch4 clickhouse-client -q 'select * from graphite.graphite_tree_distributed'
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml exec ch4 clickhouse-client -q 'select * from graphite.graphite_distributed'
```

### Troubleshooting

To help diagnose issues with the boot process, comment out the ExecStartPost command in clickhouse-server.service:

```bash
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml up ch1 zoonavigator
$ docker-compose exec ch1 bash
```

On the node:

```bash
clickhouse-bootstrap.sh node-status
clickhouse-bootstrap.sh create-remote-servers-node
clickhouse-bootstrap.sh systemd-bootstrap
```

Also useful is the Zookeeper CLI (uncomment the service in the `dev-docker-compose-override.yml` file first):

```bash
$ docker-compose -f docker-compose.yml -f ../telemetry-terraform/modules/clickhouse/docker/dev-docker-compose-override.yml run --entrypoint ash zookeepercli
$ zookeepercli --servers zookeeper -c ls /  
$ zookeepercli --servers zookeeper -c ls /clickhouse/tables/shard\_1/graphite\_tree
```

### Stop and shutdown the cluster

To bring down the cluster and ensure there's no state carried into a new cluster:

```bash
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml down && rm -rf ch*_volume/
```
## Recreate common failure scenarios

### Recover from a single node outage

To recover from a single node outage (assumes `ch1`):

```bash
$ NODE=ch1
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml stop $NODE
$ ls -la "${NODE}_volume"
$ rm -rf "${NODE}_volume"
$ docker-compose -f clickhouse-cluster/docker-compose.yml -f dev-docker-compose-override.yml up $NODE
$ docker-compose exec ch1 clickhouse-docker.py
```

### Simulate a replicated state issue

To simulate a replicated table state issue (as per https://confluence.tools.tax.service.gov.uk/display/TEL/Recover+from+loss+of+state+in+Zookeeper):

> TODO: need to figure this out!

To recover from the replicated table state issue:

> TODO: need to figure this out!
