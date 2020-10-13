FROM evenlights/collectd
RUN apt-get update && apt-get install -y collectd-utils
RUN mkdir /src
COPY telemetry-pkgs/collectd_logstash /src/collectd_logstash
RUN ls -la /src
RUN pip install --upgrade /src/collectd_logstash