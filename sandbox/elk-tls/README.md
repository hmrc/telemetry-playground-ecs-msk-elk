# Elasticsearch Local Cluster with TLS

This folder contains a quick and dirty way to get an ELK stack running locally with TLS enabled and security audit
logging output to a RollingFile appender.

**NOTE** Please allow a minimum of 4gb of memory in your local Docker setup.

## Phase 0: Environment Variables

```bash
export CA_DIR=/usr/share/elasticsearch/config/certificate-authorities
export CERTS_DIR=/usr/share/elasticsearch/config/certificates
export COMPOSE_PROJECT_NAME=es
export KEY_PASSPHRASE=superSecretPasswordForPrivateKeyAndStores
```

**WARNING**
There should be a matching directory for the value added to VERSION. This way we can keep configuration version specific.

### Version specific settings

[Version 6 discovery settings](https://www.elastic.co/guide/en/elasticsearch/reference/6.8/discovery-settings.html)
```bash
export VERSION=6.8.0
export SEED_HOSTS_ES01=discovery.zen.ping.unicast.hosts=es02.telemetry.internal,es03.telemetry.internal
export SEED_HOSTS_ES02=discovery.zen.ping.unicast.hosts=es01.telemetry.internal,es03.telemetry.internal
export SEED_HOSTS_ES03=discovery.zen.ping.unicast.hosts=es01.telemetry.internal,es02.telemetry.internal
```

[Version 7 discovery settings](https://www.elastic.co/guide/en/elasticsearch/reference/7.6/discovery-settings.html) 
```bash
export VERSION=7.6.0
export SEED_HOSTS_ES01=discovery.seed_hosts=es02.telemetry.internal,es03.telemetry.internal
export SEED_HOSTS_ES02=discovery.seed_hosts=es01.telemetry.internal,es03.telemetry.internal
export SEED_HOSTS_ES03=discovery.seed_hosts=es01.telemetry.internal,es02.telemetry.internal
```

### Java debug settings

[Java 8 debug settings](https://www.ibm.com/support/knowledgecenter/en/SSYKE2_8.0.0/com.ibm.java.security.component.80.doc/security-component/jsse2Docs/debug.html)

```bash
export ES_JAVA_OPTS="ES_JAVA_OPTS=-Xms512m -Xmx512m "

# If you wish to log extra debug information then you can set the ES_JAVA_OPTS as the following examples show
# export ES_JAVA_OPTS="-Xms512m -Xmx512m -Djavax.net.debug=all"
# export ES_JAVA_OPTS="-Xms512m -Xmx512m -Djavax.net.debug=ssl"
# export ES_JAVA_OPTS="-Xms512m -Xmx512m -Djavax.net.debug=ssl:handshake"
```

## Phase 1.0: Generate certificates

```bash
docker-compose -f create-certs.yml run --rm create_certs
```

## Phase 1.1: Import AWS certificates and configuration files into Docker volumes

```bash
docker-compose -f create-volumes.yml run --rm create_volumes
```

## Phase 2: Bring up cluster and generate passwords

```bash
docker-compose up -d

# When the cluster is up and running, run the following to extract passwords
docker exec es01 /bin/bash -c "bin/elasticsearch-setup-passwords auto --batch --url https://es01.telemetry.internal:9200" > es-passwords.txt

# Use the kibana password to replace the CHANGEME in the docker-compose.yml

# Restart the cluster
docker-compose stop
docker-compose up -d

# Access Kibana using the _elastic_ username and password derived from above
# If you use Chrome consider running chrome://flags/#allow-insecure-localhost to allow the page to load with self-signed certs
# https://localhost:5601
```

## Phase 2.1: Tidy up

If you need to bring your cluster down for a fresh start, run the following command

```bash
docker-compose -f docker-compose.yml down --volumes
```

## Phase 3: Testing audit logging

Once you have a cluster running into which you have authenticated, you should now see entries in your audit log. It is a
very good idea to navigate to the [sample data URL](https://localhost:5601/app/kibana#/home/tutorial_directory/sampleData)
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

## Useful commands

```bash
# Tear down Docker to start again
docker system prune --volumes -f

# Test a p12 file can be decrypted using a password
openssl pkcs12 -in truststore.p12 -out certificate.pem -nodes

# View that certificate
cat certificate.pem | openssl x509

# Create pem from pkcs12 without private key (for CA certs)
openssl pkcs12 -in path.p12 -out newfile.crt.pem -nokeys

# How to create pkcs12 truststore using openssl
openssl pkcs12 -export -nokeys -in certificate.cer -out pkcs12.pfx

# How to view the contents of a Certificate Signing Request
openssl req -noout -text -in req.csr

# How to view the contents of a certificate
openssl x509 -text -in ./es.telemetry.internal.crt
```

## References
* [Jira Ticket](https://jira.tools.tax.service.gov.uk/browse/TEL-1886)
* [Run in Docker with TLS enabled](https://www.elastic.co/guide/en/elastic-stack-get-started/current/get-started-docker.html#get-started-docker-tls)
* [Getting started guide](https://github.com/elastic/stack-docs/blob/master/docs/en/getting-started/get-started-docker.asciidoc)
* [TLS enabled stack original source code](https://github.com/elastic/stack-docs/blob/master/docs/en/getting-started/docker/elastic-docker-tls.yml)
* [Elasticsearch Encrypting Communications](https://www.elastic.co/guide/en/elasticsearch/reference/current/configuring-tls.html)
* [Elasticsearch configuring security](https://www.elastic.co/guide/en/elasticsearch/reference/current/configuring-security.html)
* [Elasticsearch configure TLS/SSL & PKI Authentication](https://www.elastic.co/blog/elasticsearch-security-configure-tls-ssl-pki-authentication)
* [Elasticsearch configure secure ELK and Beats](https://www.elastic.co/blog/configuring-ssl-tls-and-https-to-secure-elasticsearch-kibana-beats-and-logstash)
* [Elasticsearch auditing-settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/auditing-settings.html)
* [Elasticsearch security-settings](https://www.elastic.co/guide/en/elasticsearch/reference/current/security-settings.html)
* [Elasticsearch elasticsearch-certutil tool](https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html)
* [Elasticsearch elasticsearch-keystore tool](https://www.elastic.co/guide/en/elasticsearch/reference/current/elasticsearch-keystore.html)
* [Elasticsearch slowlog index reference](https://www.elastic.co/guide/en/elasticsearch/reference/7.0/index-modules-slowlog.html)
* [Elasticsearch fine tuning queries](https://www.elastic.co/blog/advanced-tuning-finding-and-fixing-slow-elasticsearch-queries)
* [Kibana Settings](https://www.elastic.co/guide/en/kibana/current/settings.html)
* [Kibana needs PEM files](https://discuss.elastic.co/t/why-does-elasticsearch-use-pkcs-12-while-kibana-needs-pem/161756/2)
* [Setting up Elasticsearch and Kibana on Docker with X-Pack security enabled](http://codingfundas.com/setting-up-elasticsearch-6-8-with-kibana-and-x-pack-security-enabled/index.html)
* [Learning to Love the Keystore](https://nicklang.com/posts/learning-to-love-the-keystore)
* [OpenSSL Man Page](https://www.openssl.org/docs/man1.1.1/man1/openssl.html)
