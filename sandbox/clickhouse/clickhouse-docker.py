#!/usr/bin/env python3
import argparse
import logging
import os
import shutil
import sys

from os import path

logging.basicConfig()

log = logging.getLogger("clickhouse-docker.py")
log.setLevel(os.environ.get("BOOTSTRAP_SCRIPT_LOGLEVEL", "INFO"))

ch_remote_servers_key = "/clickhouse.config.remote_servers"
init_dir = "/etc/mdtp_templates/clickhouse"
ch_conf_dir = "/etc/clickhouse-server/config.d"
sbin_dir = "/usr/local/sbin"
docker_ami_dir = "/var/lib/clickhouse-ami"
docker_tt_ch_shard_dir = "/var/lib/tt-clickhouse-shard"


aws_az = os.getenv("AWS_AVAILABILITY_ZONE", "eu-west-2a")
ch_shard_name = os.environ["AWS_TAG_SHARD_NAME"]

replica_prefix = "live"
instance_id = f"{replica_prefix}_{aws_az}"


parser = argparse.ArgumentParser()
parser.add_argument("command", help="the action to perform", nargs='?')
args = parser.parse_args()
command = args.command

# Produce the /etc/mdtp_templates/clickhouse/init.sql file(s) from the
# template(s) mounted from telemetry-terraform in /var/lib/clickhouse/telemetry
def docker_init_sql_ensure_exists():

    if path.exists(init_dir):
        log.debug(f"{init_dir} exists")
        shutil.rmtree(init_dir)
        # os.remove(f'{init_dir}/init-create')

    f = open(f"{docker_tt_ch_shard_dir}/clickhouse-init.tpl", "r")
    template = f.read()

    template = template.replace("${shard_name}", f"{ch_shard_name}")
    template = template.replace("${cluster_name}", "ua_cluster")
    template = template.replace("___REPLICA_INSTANCE_ID___", f"{instance_id}")

    os.makedirs(init_dir)

    attach = open(f"{init_dir}/init-attach", "a")
    attach.write(template.replace("${action}", "ATTACH"))
    attach.close()

    attach = open(f"{init_dir}/init-create", "a")
    attach.write(template.replace("${action}", "CREATE"))
    attach.close()


def docker_config_ensure_exists():

    log.info("docker_config_ensure_exists")

    log.info(
        "ensuring /etc/systemd/system/clickhouse-server.service.d/override.conf exists"
    )

    if not os.path.isdir("/etc/systemd/system/clickhouse-server.service.d"):
        os.mkdir("/etc/systemd/system/clickhouse-server.service.d")

    if os.path.exists(f"/etc/systemd/system/clickhouse-server.service.d/override.conf"):
        os.remove(f"/etc/systemd/system/clickhouse-server.service.d/override.conf")

    # # systemd uses a blank env - presume we're doing something smart in the AMI to make the info available to systemd
    docker_conf = open(
        f"/etc/systemd/system/clickhouse-server.service.d/override.conf", "w"
    )
    docker_conf.write(
        f'[Service]\nEnvironment="AWS_AVAILABILITY_ZONE={aws_az}"\nEnvironment="AWS_TAG_SHARD_NAME={ch_shard_name}"'
    )
    docker_conf.close()

    if os.path.exists(f"{sbin_dir}/clickhouse-sql-init.sh"):
        os.remove(f"{sbin_dir}/clickhouse-sql-init.sh")

    os.symlink(
        f"{docker_ami_dir}/clickhouse-server/sbin/clickhouse-sql-init.sh",
        f"{sbin_dir}/clickhouse-sql-init.sh",
    )

    if os.path.exists(f"{sbin_dir}/wait-for-it.sh"):
        os.remove(f"{sbin_dir}/wait-for-it.sh")

    os.symlink(
        f"{docker_ami_dir}/clickhouse-server/sbin/wait-for-it.sh",
        f"{sbin_dir}/wait-for-it.sh",
    )

    # symlink the python script into /root for use by systemd
    # if os.path.exists('/root/clickhouse_bootstrap'):
    #     os.remove('/root/clickhouse_bootstrap')

    # os.symlink(f'{docker_ami_dir}/clickhouse-server/mdtp_scripts/clickhouse_bootstrap', '/root/clickhouse_bootstrap')

    if os.path.exists(f"{ch_conf_dir}/graphite_rollup.xml"):
        os.remove(f"{ch_conf_dir}/graphite_rollup.xml")

    # This file needs to be enclosed in <yandex> tags
    f = open(f"{docker_ami_dir}/graphite-clickhouse/etc/rollup.xml", "r")
    rollup = f.read()
    f.close()

    rollup_dest = open(f"{ch_conf_dir}/graphite_rollup.xml", "a")
    rollup_dest.write(f"<yandex>\n{rollup}\n</yandex>")
    rollup_dest.close()


def docker_remote_servers_zk_ensure_exists():

    zk_connect()

    if not zk_exists(ch_remote_servers_key):
        log.info(f"creating simple {ch_remote_servers_key} zookeeper key")
        zk_create(ch_remote_servers_key, b"Some-config")
    exit()

def initialise_docker():

    # The clickhouse_bootstrap.main module isn't installed into docker atm - this is a bit of a hack to install it prior to using the other script
    os.system(
        "bash -c 'pushd /var/lib/clickhouse-ami/clickhouse-server/ && pip3 install -r requirements.txt && popd'"
    )

    # docker_remote_servers_zk_ensure_exists()
    docker_init_sql_ensure_exists()
    docker_config_ensure_exists()

# print(command)
if command == "create-remote-servers-node":

    from clickhouse_bootstrap.main import (
        zk_connect,
        zk_exists,
        zk_create
    )

    log.info("creating remote server node")
    docker_remote_servers_zk_ensure_exists()
    log.info("created zk node")
    exit()
else:
        
    log.info("running docker systemd initialisation code")
    log.info("initialising docker assets")
    initialise_docker()
    log.info("docker assets initialised")

    log.info("calling systemctl daemon-reload")
    os.system("systemctl daemon-reload")

    log.info("starting clickhouse-server with systemctl")
    os.system("systemctl start clickhouse-server")
    log.info("started clickhouse-server with systemctl")
