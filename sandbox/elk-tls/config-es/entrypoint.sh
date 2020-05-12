#!/usr/bin/env bash

# Load the key and keystore passwords into the elasticsearch-keystore
echo n | ./bin/elasticsearch-keystore create
for KEY in xpack.security.http.ssl.keystore.secure_password \
           xpack.security.http.ssl.keystore.secure_key_password \
           xpack.security.http.ssl.truststore.secure_password \
           xpack.security.transport.ssl.keystore.secure_password \
           xpack.security.transport.ssl.keystore.secure_key_password \
           xpack.security.transport.ssl.truststore.secure_password; do
  ./bin/elasticsearch-keystore list | grep ${KEY}
  # If key not present i.e. non-zero status code, then add key
  if [[ $? -ne 0 ]]; then
    echo ${KEY_PASSPHRASE} | ./bin/elasticsearch-keystore add ${KEY}
  fi
done
./bin/elasticsearch-keystore list

# Copy the version specific files that were loaded into the config volume to their correct location
cp -p /usr/share/elasticsearch/config-tmp/* /usr/share/elasticsearch/config

# Run the official entrypoint script
/usr/local/bin/docker-entrypoint.sh
