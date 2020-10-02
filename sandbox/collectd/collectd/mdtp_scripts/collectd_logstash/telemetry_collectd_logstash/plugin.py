try:
    import collectd

except ImportError:
    import dummy_collectd as collectd

import requests
import logging
import functools

logging.basicConfig(level=logging.INFO)

PLUGIN_NAME = 'telemetry-collectd-logstash'
DATAPOINT_COUNT = 0
NOTIFICATION_COUNT = 0
ENDPOINT = 'http://logstash:9600'

def is_number(n):
    return isinstance(n, int) or isinstance(n, float)

def reduce_by_name(memo, item):
    flat = flatten_json(item)
    
    for a in flat:
        if is_number(flat[a]):
            if item['name'] + '_' + a not in memo:
                memo[item['name'] + '_' + a] = 0
            memo[item['name'] + '_' + a] += flat[a]

    return memo


def flatten_json(y):
    
    out = {}

    def flatten(x, name=''):
        if type(x) is dict:
            for a in x:
                flatten(x[a], name + a + '_')
        elif type(x) is list:
            out[name[:-1] + '_count'] = len(x)

            if len(x) > 0 and 'name' in x[0]:
                by_name = functools.reduce(reduce_by_name, x, {})
                
                flatten(by_name, name[:-1] + '_')
            else:
                log('no name field found')
            
        elif is_number(x):
            out[name[:-1]] = x

    flatten(y)
    return out


def pretty(d, indent=0):
   for key, value in d.items():
       print('\t' * indent + str(key) + ' : ' + str(value))

       
def read():
    """
    This method has been registered as the read callback and will be called every polling interval
    to dispatch metrics.  We emit three metrics: one gauge, a sine wave; two counters for the
    number of datapoints and notifications we've seen.
    :return: None
    """
    
    log("Plugin %s reading..." % PLUGIN_NAME)

    read_node_stats()
                
def read_node_stats():
    url = '%s/_node/stats' % ENDPOINT

    response = requests.get(url, timeout=1)

    if response.status_code == 200:

        body = response.json()
        metrics = flatten_json(body)

        for key in metrics:
            # log("Plugin %s %s = %s..." % (PLUGIN_NAME, key, metrics[key]))

            collectd.Values(plugin=PLUGIN_NAME,
                            type_instance=key,
                            type="gauge",
                            values=[metrics[key]]).dispatch()
        
        return metrics

    else:
        log("Plugin %s unexpected http status code %s..." % (PLUGIN_NAME, response.status_code))

def log(param):
    """
    Log messages to either collectd or stdout depending on how it was called.
    :param param: the message
    :return:  None
    """

    if __name__ != '__main__':
        collectd.info("%s: %s" % ( PLUGIN_NAME, param))
    else:
        sys.stderr.write("%s\n" % param)


def config(conf):
    """
    This method has been registered as the configure callback; this gives the plugin a way to read config from the .conf
    file.  We'll just log a message.
    :return: None
    """

    log("Plugin %s configuring..." % PLUGIN_NAME)

    for kv in conf.children:
        if kv.key == 'Endpoint':
            global ENDPOINT
            ENDPOINT = kv.values[0]

    log("Plugin %s configured... Endpoint %s" % (PLUGIN_NAME, ENDPOINT))

def init():
    """
    This method has been registered as the init callback; this gives the plugin a way to do startup
    actions.  We'll just log a message.
    :return: None
    """

    log("Plugin %s initializing..." % PLUGIN_NAME)

def flush(timeout, identifier):
    """
    This method has been registered as the flush callback.  Log the two params it is given.
    :param timeout: indicates that only data older than timeout seconds is to be flushed
    :param identifier: specifies which values are to be flushed
    :return: None
    """

    log("Plugin %s flushing timeout %s and identifier %s" % PLUGIN_NAME, timeout, identifier)


def write(values):
    """
    This method has been registered as the write callback. Let's count the number of datapoints
    and emit that as a metric.
    :param values: Values object for datapoint
    :return: None
    """

    # log("Plugin %s writing %s" % (PLUGIN_NAME, values))

    global DATAPOINT_COUNT
    DATAPOINT_COUNT += len(values.values)

def log_cb(severity, message):
    """
    This method has been registered as the log callback. Don't emit log messages from within this
    as you will cause a loop.
    :param severity: an integer and small for important messages and high for less important messages
    :param message: a string without a newline at the end
    :return: None
    """

    pass

def notification(notif):
    """
    This method has been regstered as the notification callback. Let's count the notifications
    we receive and emit that as a metric.
    :param notif: a Notification object.
    :return: None
    """

    global NOTIFICATION_COUNT
    NOTIFICATION_COUNT += 1

def shutdown():
    """
    This method has been registered as the shutdown callback. this gives the plugin a way to clean
    up after itself before shutting down.  We'll just log a message.
    :return: None
    """

    log("Plugin %s shutting down..." % PLUGIN_NAME)

if __name__ != "__main__":
    # when running inside plugin register each callback
    collectd.register_config(config)
    collectd.register_read(read)
    collectd.register_init(init)
    collectd.register_shutdown(shutdown)
    collectd.register_write(write)
    collectd.register_flush(flush)
    collectd.register_notification(notification)
else:
    # outside plugin just collect the info
    read()
    if len(sys.argv) < 2:
        while True:
            time.sleep(10)
            read()