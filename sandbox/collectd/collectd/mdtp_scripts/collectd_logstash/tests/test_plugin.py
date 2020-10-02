import sys

from telemetry_collectd_logstash import plugin
from dummy_collectd import Config

def test_catbind():
    print(plugin.PLUGIN_NAME)

def test_read_node_stats():
    
    # TODO : this assumes the test is running from a docker container, connecting to the logstash mock bound to the host
    endpoint = Config(key='Endpoint', values=['http://host.docker.internal:9600'])
    config = Config(children=[endpoint])

    plugin.config(config)
    response = plugin.read_node_stats()
    plugin.pretty(response)
    
    print('keys : %s' % len(response.keys()))

    assert len(response) == 156
    assert response['jvm_threads_count'] == 83