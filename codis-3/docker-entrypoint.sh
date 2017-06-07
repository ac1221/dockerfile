#!/bin/bash

set -e

echo "CODIS_TYPE: $CODIS_TYPE"

if [ $CODIS_TYPE = "codis_dashboard" ];
then

echo "coordinator_name : ${coord_name}"
echo "coordinator_addr : ${coord_list}"
echo "product_name : ${prd_name}"
echo "product_auth : ${prd_auth}"

cat > /opt/local/codis/config/dashboard.toml << EOF
##################################################
#                                                #
#                  Codis-Dashboard               #
#                                                #
##################################################

# Set Coordinator, only accept "zookeeper" & "etcd" & "filesystem".
coordinator_name = "${coord_name}"
coordinator_addr = "${coord_list}"

# Set Codis Product Name/Auth.
product_name = "${prd_name}"
product_auth = "${prd_auth}"

# Set bind address for admin(rpc), tcp only.
admin_addr = "0.0.0.0:18080"

# Set configs for redis sentinel.
sentinel_quorum = 2
sentinel_parallel_syncs = 1
sentinel_down_after = "10s"
sentinel_failover_timeout = "10m"
sentinel_notification_script = "/opt/local/codis/script/sentinel_notify.sh"
sentinel_client_reconfig_script = "/opt/local/codis/script/sentinel_reconfig.sh"
EOF
 
echo "-------------------------------------------------------------------------------"
echo "dashboard.toml file"
cat /opt/local/codis/config/dashboard.toml
echo "-------------------------------------------------------------------------------"

CMD="/opt/local/codis/bin/codis-dashboard --ncpu=4 --config=/opt/local/codis/config/dashboard.toml --log=/opt/local/codis/logs/dashboard.log --log-level=WARN"

elif [ $CODIS_TYPE = "codis_proxy" ];
then

echo "product_name : ${prd_name}"
echo "product_auth : ${prd_auth}"
echo "jodis_name : ${coord_name}"
echo "jodis_addr : ${coord_list}"

cat > /opt/local/codis/config/proxy.toml << EOF
##################################################
#                                                #
#                  Codis-Proxy                   #
#                                                #
##################################################

# Set Codis Product Name/Auth.
product_name = "${prd_name}"
product_auth = "${prd_auth}"

# Set bind address for admin(rpc), tcp only.
admin_addr = "0.0.0.0:11080"

# Set bind address for proxy, proto_type can be "tcp", "tcp4", "tcp6", "unix" or "unixpacket".
proto_type = "tcp4"
proxy_addr = "0.0.0.0:19000"

# Set jodis address & session timeout, only accept "zookeeper" & "etcd".
jodis_name = "${coord_name}"
jodis_addr = "${coord_list}"
jodis_timeout = "20s"
jodis_compatible = false

# Set datacenter of proxy.
proxy_datacenter = ""

# Set max number of alive sessions.
proxy_max_clients = 1000

# Set max offheap memory size. (0 to disable)
proxy_max_offheap_size = "1024mb"

# Set heap placeholder to reduce GC frequency.
proxy_heap_placeholder = "256mb"

# Proxy will ping backend redis (and clear 'MASTERDOWN' state) in a predefined interval. (0 to disable)
backend_ping_period = "5s"

# Set backend recv buffer size & timeout.
backend_recv_bufsize = "128kb"
backend_recv_timeout = "30s"

# Set backend send buffer & timeout.
backend_send_bufsize = "128kb"
backend_send_timeout = "30s"

# Set backend pipeline buffer size.
backend_max_pipeline = 1024

# Set backend never read replica groups, default is false
backend_primary_only = false

# Set backend parallel connections per server
backend_primary_parallel = 1
backend_replica_parallel = 1

# Set backend tcp keepalive period. (0 to disable)
backend_keepalive_period = "75s"

# If there is no request from client for a long time, the connection will be closed. (0 to disable)
# Set session recv buffer size & timeout.
session_recv_bufsize = "128kb"
session_recv_timeout = "30m"

# Set session send buffer size & timeout.
session_send_bufsize = "64kb"
session_send_timeout = "30s"

# Make sure this is higher than the max number of requests for each pipeline request, or your client may be blocked.
# Set session pipeline buffer size.
session_max_pipeline = 1024

# Set session tcp keepalive period. (0 to disable)
session_keepalive_period = "75s"

# Set session to be sensitive to failures. Default is false, instead of closing socket, proxy will send an error response to client.
session_break_on_failure = false

# Set metrics server (such as http://localhost:28000), proxy will report json formatted metrics to specified server in a predefined period.
metrics_report_server = ""
metrics_report_period = "1s"

# Set influxdb server (such as http://localhost:8086), proxy will report metrics to influxdb.
metrics_report_influxdb_server = ""
metrics_report_influxdb_period = "1s"
metrics_report_influxdb_username = ""
metrics_report_influxdb_password = ""
metrics_report_influxdb_database = ""
EOF

echo "-------------------------------------------------------------------------------"
echo "------------------------------proxy.toml file----------------------------------"
cat /opt/local/codis/config/proxy.toml
echo "-------------------------------------------------------------------------------"

CMD="/opt/local/codis/bin/codis-proxy --ncpu=4 --config=/opt/local/codis/config/proxy.toml --log=/opt/local/codis/logs/proxy.log --log-level=WARN"

elif [ $CODIS_TYPE = "codis_server" ];
then
echo "maxmemory : ${MAXMEMORY}"

sed -i "s/^maxmemory.*$/maxmemory ${MAXMEMORY}/g" /opt/local/codis/config/redis.conf

echo "-------------------------------------------------------------------------------"
echo "-----------------------------redis.conf file-----------------------------------"
cat /opt/local/codis/config/redis.conf
echo "-------------------------------------------------------------------------------"

CMD="/opt/local/codis/bin/codis-server /opt/local/codis/config/redis.conf"

elif [ $CODIS_TYPE = "codis_sentinel" ];
then

cat > /opt/local/codis/config/sentinel.conf << EOF
bind 0.0.0.0
protected-mode yes
port 26380
logfile "/opt/local/codis/logs/sentinel.log"
EOF

echo "-------------------------------------------------------------------------------"
echo "-----------------------------sentinel.conf file--------------------------------"
cat /opt/local/codis/config/sentinel.conf
echo "-------------------------------------------------------------------------------"

CMD="/opt/local/codis/bin/codis-server /opt/local/codis/config/sentinel.conf --sentinel"

elif [ $CODIS_TYPE = "codis_fe" ];
then

echo "zookeeper : ${coord_list}"

CMD="/opt/local/codis/bin/codis-fe --ncpu=4 --log=/opt/local/codis/logs/fe.log --log-level=WARN --zookeeper=${coord_list} --listen=0.0.0.0:8080"

else
  echo " [Error] CODIS_TYPE Null OR MAXMEMORY Null"
fi

exec $CMD
