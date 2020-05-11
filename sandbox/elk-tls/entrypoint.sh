#!/usr/bin/env bash

# Add custom startup functionality here

# yum -y install openssl ca-certificates
# update-ca-trust force-enable
# cp /usr/share/elasticsearch/config/certificates/ca.crt /etc/pki/ca-trust/source/anchors/ca.crt
# update-ca-trust
# env
/usr/local/bin/docker-entrypoint.sh
