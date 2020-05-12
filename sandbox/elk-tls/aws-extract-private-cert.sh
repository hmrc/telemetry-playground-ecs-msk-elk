#!/bin/bash

LAB=$(echo ${AWS_PROFILE} | sed -e 's/telemetry-internal-//g')
CA_COMMON_NAME="internal-${LAB}.telemetry.internal"
DOMAIN_NAME="elasticsearch.telemetry.internal"

CA_CERTIFICATE_ARN=$(aws acm-pca list-certificate-authorities \
  --query 'CertificateAuthorities[].[{arn:Arn,status:Status,cn:CertificateAuthorityConfiguration.Subject.CommonName}]' | \
  jq -r --arg cn ${CA_COMMON_NAME} '.[][] | select(.cn==$cn) | .arn')

CERTIFICATE_ARN=$(aws acm list-certificates \
  --certificate-statuses ISSUED \
  --query 'CertificateSummaryList[].[{arn:CertificateArn,dn:DomainName}]' | \
  jq -r --arg dn ${DOMAIN_NAME} '.[][] | select(.dn==$dn) | .arn')

# You can't use the same pipe to jq here like you can with acm export-certificate because AWS CLI inconsistencies abound
# If you do use jq -r '"\(.Certificate)\(.CertificateChain)"' you end up with -----END CERTIFICATE----------BEGIN CERTIFICATE-----
# on the same line which is clearly an invalid certificate *deep sigh*
aws acm-pca get-certificate-authority-certificate --certificate-authority-arn ${CA_CERTIFICATE_ARN} \
                                                  --output text \
                                                  --query 'Certificate' > ./certs/aws/elastic.ca.crt

aws acm-pca get-certificate-authority-certificate --certificate-authority-arn ${CA_CERTIFICATE_ARN} \
                                                  --output text \
                                                  --query 'CertificateChain' >> ./certs/aws/elastic.ca.crt

openssl pkcs12 -export \
               -in ./certs/aws/elastic.ca.crt \
               -nokeys \
               -out ./certs/truststore.p12 \
               -passout pass:${KEY_PASSPHRASE}

aws acm export-certificate \
        --certificate-arn ${CERTIFICATE_ARN} \
        --passphrase fileb://passphrase \
        | jq -r '"\(.Certificate)\(.CertificateChain)"' > ./certs/aws/elastic.instance.crt

aws acm export-certificate \
        --certificate-arn ${CERTIFICATE_ARN} \
        --passphrase fileb://passphrase \
        | jq -r '"\(.PrivateKey)"' > ./certs/aws/elastic.instance.key

openssl pkcs12 -export \
               -in ./certs/aws/elastic.instance.crt \
               -inkey ./certs/aws/elastic.instance.key \
               -passin pass:${KEY_PASSPHRASE} \
               -out ./certs/keystore.p12 \
               -passout pass:${KEY_PASSPHRASE}

cp ./certs/aws/elastic.ca.crt ./certs/ca.crt
chmod 0600 ./certs/ca.crt
chmod 0600 ./certs/keystore.p12
chmod 0600 ./certs/truststore.p12
