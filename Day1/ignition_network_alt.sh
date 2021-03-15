NGINX_DIRECTORY="/var/www/html"
DOMAIN_NAME="hkn.lab"
CLUSTER_NAME="ocp4"

NET_INTERFACE="enp1s0"
NETMASK='255.255.0.0'
GATEWAY='172.24.0.1'
DNS1='172.16.0.9'
DNS2='172.24.0.1'

create_ifcfg(){
  cat > ${NGINX_DIRECTORY}/${HOST}-${NET_INTERFACE} << EOF
NAME=${NET_INTERFACE}
DEVICE=${NET_INTERFACE}
TYPE=Ethernet
BOOTPROTO=none
ONBOOT=yes
IPADDR=${IP}
NETMASK=${NETMASK}
GATEWAY=${GATEWAY}
DNS1=${DNS1}
DNS2=${DNS2}
DEFROUTE=yes
IPV6INIT=no
DOMAIN=${CLUSTER_NAME}.${DOMAIN_NAME}
EOF

  ENO1=$(cat ${NGINX_DIRECTORY}/${HOST}-${NET_INTERFACE} | base64 -w0)
  rm ${NGINX_DIRECTORY}/${HOST}-${NET_INTERFACE}
  cat > ${NGINX_DIRECTORY}/${HOST}-ifcfg-${NET_INTERFACE}.json << EOF
{
  "append" : false,
  "mode" : 420,
  "filesystem" : "root",
  "path" : "/etc/sysconfig/network-scripts/ifcfg-${NET_INTERFACE}",
  "contents" : {
    "source" : "data:text/plain;charset=utf-8;base64,${ENO1}",
    "verification" : {}
  },
  "user" : {
    "name" : "root"
  },
  "group": {
    "name": "root"
  }
}
EOF

cat > ${NGINX_DIRECTORY}/${HOST}-hostname << EOF
${CLUSTER_NAME}-${HOST}.${DOMAIN_NAME}
EOF
  HN=$(cat ${NGINX_DIRECTORY}/${HOST}-hostname | base64 -w0)
  rm ${NGINX_DIRECTORY}/${HOST}-hostname
  cat > ${NGINX_DIRECTORY}/${HOST}-hostname.json << EOF
{
  "append" : false,
  "mode" : 420,
  "filesystem" : "root",
  "path" : "/etc/hostname",
  "contents" : {
    "source" : "data:text/plain;charset=utf-8;base64,${HN}",
    "verification" : {}
  },
  "user" : {
    "name" : "root"
  },
  "group": {
    "name": "root"
  }
}
EOF
}

# Disable set hostname via reverse lookup
# Common to all hosts
cat > ${NGINX_DIRECTORY}/hostname-mode << EOF
[main]
hostname-mode=none
EOF
  HM=$(cat ${NGINX_DIRECTORY}/hostname-mode | base64 -w0)
  rm ${NGINX_DIRECTORY}/hostname-mode
  cat > ${NGINX_DIRECTORY}/hostname-mode.json << EOF
{
  "append" : false,
  "mode" : 420,
  "filesystem" : "root",
  "path" : "/etc/NetworkManager/conf.d/hostname-mode.conf",
  "contents" : {
    "source" : "data:text/plain;charset=utf-8;base64,${HM}",
    "verification" : {}
  },
  "user" : {
    "name" : "root"
  },
  "group": {
    "name": "root"
  }
}
EOF

modify_ignition(){
  cp -u ${NGINX_DIRECTORY}/${TYPE}.ign ${NGINX_DIRECTORY}/${HOST}.ign.orig
  jq '.storage.files += [inputs]' ${NGINX_DIRECTORY}/${HOST}.ign.orig ${NGINX_DIRECTORY}/${HOST}-hostname.json ${HOST}-ifcfg-${NET_INTERFACE}.json ${NGINX_DIRECTORY}/hostname-mode.json > ${NGINX_DIRECTORY}/${HOST}.ign
  rm -f ${NGINX_DIRECTORY}/${HOST}-hostname.json ${HOST}-ifcfg-${NET_INTERFACE}.json
}

TYPE="bootstrap"
HOST="bootstrap"
IP=172.24.10.19
create_ifcfg
modify_ignition

TYPE="master"
HOST=master1
IP=172.24.10.21
create_ifcfg
modify_ignition

HOST=master2
IP=172.24.10.22
create_ifcfg
modify_ignition

HOST=master3
IP=172.24.10.23
create_ifcfg
modify_ignition

TYPE="worker"
HOST=worker1
IP=172.24.10.24
create_ifcfg
modify_ignition

HOST=worker2
IP=172.24.10.25
create_ifcfg
modify_ignition

HOST=worker3
IP=172.24.10.26
create_ifcfg
modify_ignition

