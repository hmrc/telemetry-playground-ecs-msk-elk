#!/usr/bin/env bash

# Add custom startup functionality here
echo n | ./bin/elasticsearch-keystore create
for KEY in xpack.security.http.ssl.keystore.secure_password \
           xpack.security.http.ssl.keystore.secure_key_password \
           xpack.security.http.ssl.truststore.secure_password \
           xpack.security.transport.ssl.keystore.secure_password \
           xpack.security.transport.ssl.keystore.secure_key_password \
           xpack.security.transport.ssl.truststore.secure_password; do
  echo ${KEY_PASSPHRASE} | ./bin/elasticsearch-keystore add ${KEY}
done
./bin/elasticsearch-keystore list
cp -p /usr/share/elasticsearch/config-tmp/* /usr/share/elasticsearch/config
/usr/local/bin/docker-entrypoint.sh
