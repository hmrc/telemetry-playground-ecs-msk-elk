FROM docker.elastic.co/logstash/logstash:7.3.1

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.vcs-url=$VCS_URL
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL maintainer="service_telemetry.dog+bristol@digital.hmrc.gov.uk"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vendor="HMRC Telemetry"

ADD kafka-consumer.conf /usr/share/logstash/pipeline/
