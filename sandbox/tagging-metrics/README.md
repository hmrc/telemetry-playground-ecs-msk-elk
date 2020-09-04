# TEL-1287-playground
[TEL-1287](https://jira.tools.tax.service.gov.uk/browse/TEL-1287) docker-compose tagging telemetry metrics. Prototype and demo to the team.

# Usage
`make` is used to manage the stack:

|Target|Description|
|:-|:-|
|all-down|  all down everything|
|all-up|  all up everything|
|carbon-relay-meta|  Dump the relay meta spool file|
|clean|  Remove data/ and pprofs/|
|clickhouse-client|  Invoke clickhose-client|
|clickhouse_metric_paths|  Dump concrete metric paths (default is 'db_table=graphite.graphite_tree')|
|envoy-down|  aws-ecs-envoy container down|
|envoy-image|  aws-ecs-envoy image pull from Artifactory|
|envoy-up|  aws-ecs-envoy container up|
|heap_carbon-clickhouse|  Heap dump carbon-clickhouse|
|help|  Help on targets|
|lazydocker|  lazydocker the stack|
|play-down|  platform-status-backend container down|
|play-up|  platform-status-backend container up|
|recycle|  Recycle a service (set 'svc' to recycle)|
|scale|  Scale a 'svc' by 'size'|
|scope-launch|  [scope](https://www.weave.works/oss/scope/) launch|
|scope-stop|  scope stop|
|source-down|  source down everything|
|source-up|  source up everything|
|stack-down|  Stack down (stop and remove containers, networks, images, and volumes)|
|stack-network|  Stack network inspect|
|stack-tail|  Stack tail logs (set 'svc' to filter services)|
|stack-up|  Stack up and scale (set 'svc' to filter services)|
|wireshark|  Wireshark the metrics stack network bridge|
|yamllint|  YML lint docker-compose YAML|

# Vanilla carbon-relay-ng metrics
Enable vanilla `carbon-relay-ng` configuration as follows:

```
make clean stack-up -e CRNG_VARIANT=.vanilla
```

Once the stack is up you can dump the metrics via:

```
docker exec clickhouse bash -c "export HOME=/var/lib/clickhouse/ ; echo 'select Path from graphite.graphite_tree order by Path'| clickhouse client" | egrep -v -E '\.$' - > METRICS_CRNG_VARIANT_vanilla.md
```

# Manual Steps
If you want to use the targets `play-up` and `play-down` ensure you've followed the steps detailed in [docker-compose.source_platform-status-backend.setup.md](docker-compose.source_platform-status-backend.setup.md)

# See also
* [clickhouse tags](https://groups.google.com/forum/#!searchin/clickhouse/tags%7Csort:date)
* [carbon-relay-ng tags](https://github.com/grafana/carbon-relay-ng/search?q=tag&unscoped_q=tag)
* [InfluxDB templates](https://docs.influxdata.com/influxdb/v1.7/supported_protocols/graphite/#templates)
* [Getting started with tags](https://docs.datadoghq.com/tagging/)

# Useful Tools
* [ctop](https://github.com/bcicen/ctop)
* [DBeaver](https://dbeaver.io/download/)
* [lazydocker](https://github.com/jesseduffield/lazydocker)
* [scope](https://www.weave.works/docs/scope/latest/installing/#docker-single-node)
* [wireshark](https://www.wireshark.org/)

# Related
Repositories that inspired this playground
* https://graphite.readthedocs.io/en/latest/tags.html
* https://github.com/lomik/graphite-clickhouse-tldr
* https://github.com/vimagick/dockerfiles
