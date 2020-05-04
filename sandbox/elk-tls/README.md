# Elasticsearch Local Cluster with TLS

This folder contains a quick and dirty way to get an ELK stack running locally with TLS enabled and security audit
logging output to a RollingFile appender.

**NOTE** Please allow a minimum of 4gb of memory in your local Docker setup.

## Phase 0: Environment Variables

```bash
export COMPOSE_PROJECT_NAME=es
export CERTS_DIR=/usr/share/elasticsearch/config/certificates
export VERSION=7.6.0
```

## Phase 1: Generate certificates

```bash
docker-compose -f create-certs.yml run --rm create_certs
```

## Phase 2: Bring up cluster and generate passwords

```bash
docker-compose -f docker-compose.yml up --detach

# When the cluster is up and running, run the following to extract passwords
docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords auto --batch --url https://es01:9200"

# Restart the cluster
docker-compose stop
docker-compose -f docker-compose.yml up --detach

# Access Kibana using the _elastic_ username and password derived from above
# Don't use Chrome as it complains about the certificate and never lets you continue to the site
# https://localhost:5601
```

## Phase 2.1: Tidy up

If you need to bring you cluster down to restart, run the following command

```bash
docker-compose -f docker-compose.yml down --volumes
```

## Phase 3: Testing audit logging

Once you have a cluster running into which you have authenticated, you should now see entries in your audit log. It is a
very good idea to navigate to the sample data URL https://localhost:5601/app/kibana#/home/tutorial_directory/sampleData
and load the web logs in order to have indices with which to investigate.

## Phase 4: Testing slow running searches

```
PUT /kibana_sample_data_logs/_settings
{
"index.search.slowlog.threshold.query.warn": "0s"
"index.search.slowlog.threshold.query.info": "5s",
"index.search.slowlog.threshold.query.debug": "2s",
"index.search.slowlog.threshold.query.trace": "500ms",
"index.search.slowlog.threshold.fetch.warn": "0s"
"index.search.slowlog.threshold.fetch.info": "800ms",
"index.search.slowlog.threshold.fetch.debug": "500ms",
"index.search.slowlog.threshold.fetch.trace": "200ms",
"index.indexing.slowlog.threshold.index.warn": "0s"
"index.indexing.slowlog.threshold.index.info": "5s",
"index.indexing.slowlog.threshold.index.debug": "2s",
"index.indexing.slowlog.threshold.index.trace": "500ms",
"index.indexing.slowlog.level": "trace",
"index.indexing.slowlog.source": "100"
}
```

## References
[Run in Docker with TLS enabled](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-docker.html#get-started-docker-tls)
