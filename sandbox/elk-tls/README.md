# Elasticsearch Local Cluster with TLS

This folder contains a quick and dirty way to get an ELK stack running locally with TLS enabled and security audit
logging output to a RollingFile appender.

# Phase 0: Environment Variables

```bash
export COMPOSE_PROJECT_NAME=es
export CERTS_DIR=/usr/share/elasticsearch/config/certificates
export VERSION=7.6.0
```

# Phase 1: Generate certificates

```bash
docker-compose -f create-certs.yml run --rm create_certs
```

# Phase 2: Bring up cluster and generate passwords

```bash
docker-compose -f docker-compose.yml up -d

# When the cluster is up and running, run the following to extract passwords
docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords auto --batch --url https://es01:9200"

# Restart the cluster
docker-compose stop
docker-compose -f docker-compose.yml up -d

# Access Kibana using the _elastic_ username and password derived from above
# Don't use Chrome as it complains about the certificate and never lets you continue to the site
# https://localhost:5601
```

## References
[Run in Docker with TLS enabled](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-docker.html#get-started-docker-tls)
