FROM evenlights/collectd
RUN python --version
RUN pip --version
RUN ls -la
RUN mkdir /src
COPY telemetry-pkgs/collectd_logstash /src/collectd_logstash
RUN ls -la /src
RUN pip install --upgrade /src/collectd_logstash