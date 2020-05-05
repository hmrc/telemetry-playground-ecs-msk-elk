# Elasticsearch Local Cluster with TLS

This folder contains a quick and dirty way to get an ELK stack running locally with TLS enabled and security audit
logging output to a RollingFile appender.

**NOTE** Please allow a minimum of 4gb of memory in your local Docker setup.

## Phase 0: Environment Variables

```bash
export COMPOSE_PROJECT_NAME=es
export CERTS_DIR=/usr/share/elasticsearch/config/certificates
export KEY_PASSPHRASE=supersecretpassword
export VERSION=7.6.0
```

## Phase 1.0: Generate certificates

```bash
docker-compose -f create-certs.yml run --rm create_certs
```

## Phase 1.1: Generate keystore (assuming use of AWS private certificates)

If you do not wish to generate new certs and have some AWS ACM private certificates to use then you can the following
to generate a keystore

```bash
docker-compose -f create-keystore.yml run --rm create_keystore
```

## Phase 2: Bring up cluster and generate passwords

```bash
docker-compose up -d

# When the cluster is up and running, run the following to extract passwords
docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords auto --batch --url https://es01.telemetry.internal:9200"

# Restart the cluster
docker-compose stop
docker-compose up -d

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

## Phase 4: Testing slow running searches with artificially low threshold

```
GET /kibana_sample_data_logs/_settings

PUT /kibana_sample_data_logs/_settings
{
"index.search.slowlog.threshold.query.warn": "10ms",
"index.search.slowlog.threshold.query.info": "10ms",
"index.search.slowlog.threshold.query.debug": "10ms",
"index.search.slowlog.threshold.query.trace": "10ms",
"index.search.slowlog.threshold.fetch.warn": "10ms",
"index.search.slowlog.threshold.fetch.info": "10ms",
"index.search.slowlog.threshold.fetch.debug": "10ms",
"index.search.slowlog.threshold.fetch.trace": "10ms",
"index.indexing.slowlog.threshold.index.warn": "10ms",
"index.indexing.slowlog.threshold.index.info": "10ms",
"index.indexing.slowlog.threshold.index.debug": "10ms",
"index.indexing.slowlog.threshold.index.trace": "10ms",
"index.indexing.slowlog.level": "warn",
"index.indexing.slowlog.source": "10000"
}
```

## References
* [Jira Ticket](https://jira.tools.tax.service.gov.uk/browse/TEL-1886)
* [Run in Docker with TLS enabled](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-docker.html#get-started-docker-tls)
* [TLS enabled stack source code](https://github.com/elastic/stack-docs/blob/master/docs/en/getting-started/docker/elastic-docker-tls.yml)
* [Elasticsearch auditing-settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/auditing-settings.html)
* [Elasticsearch fine tuning queries](https://www.elastic.co/blog/advanced-tuning-finding-and-fixing-slow-elasticsearch-queries)
* [Elasticsearch slowlog index reference](https://www.elastic.co/guide/en/elasticsearch/reference/7.0/index-modules-slowlog.html)
