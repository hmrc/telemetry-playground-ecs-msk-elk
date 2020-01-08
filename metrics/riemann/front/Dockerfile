FROM riemannio/riemann:0.3.5

ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.vcs-url=$VCS_URL
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL maintainer="service_telemetry.dog+bristol@digital.hmrc.gov.uk"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.vendor="HMRC Telemetry"

COPY riemann-front.config /etc/riemann.config

ENTRYPOINT ["/bin/riemann"]