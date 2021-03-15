#!/usr/bin/bash

SCRIPT_DIR=$(dirname $0)

NGINX_DIRECTORY="/var/www/html"
DOMAIN_NAME="hkn.lab"
CLUSTER_NAME="ocp4"

NET_INTERFACE='enp1s0'
NETMASK='255.255.0.0'
GATEWAY='172.24.0.1'
DNS1='172.16.0.9'
DNS2='172.24.0.1'

create_ifcfg(){
    # Set the Node's Networking
    jq -n -f ${SCRIPT_DIR}/templates/interface.json \
        --arg IP ${IP} \
        --arg GATEWAY ${GATEWAY} \
        --arg IFACE ${NET_INTERFACE} \
        --arg DNS1 ${DNS1} \
        --arg DNS2 ${DNS2} \
        > $(pwd)/${HOST}-${NET_INTERFACE}.json

    # Set the Node's Hostname
    jq -n -f ${SCRIPT_DIR}/templates/hostname.json \
        --arg HN $(echo "${HOST}.${CLUSTER_NAME}.${DOMAIN_NAME}" | base64 -w0) \
        > $(pwd)/${HOST}-hostname.json

    # Disable set hostname via reverse lookup
    # Common to all hosts
    jq -n -f ${SCRIPT_DIR}/templates/hostmode.json \
        --arg HM $(echo -e "[main]\nhostname-mode=none" | base64 -w0) \
        > $(pwd)/hostmode.json
}


modify_ignition(){
    cp -u $(pwd)/${TYPE}.ign $(pwd)/${HOST}.ign.orig1

    jq '.storage.files += [inputs]' \
        $(pwd)/${HOST}.ign.orig1 \
        $(pwd)/${HOST}-hostname.json \
        $(pwd)/hostmode.json \
        > $(pwd)/${HOST}.ign.orig2
    
    jq '.networkd.units += [inputs]' \
        $(pwd)/${HOST}.ign.orig2 \
        $(pwd)/${HOST}-${NET_INTERFACE}.json \
        > $(pwd)/${HOST}.ign.orig3
    
    #jq '.storage += {"disks": []}' \
    #    $(pwd)/${HOST}.ign.orig3 \
    #    > $(pwd)/${HOST}.ign.orig4 
    
    #jq '.storage.disks += [inputs]' \
    #    $(pwd)/${HOST}.ign.orig4 \
    #    ${SCRIPT_DIR}/templates/wipefs.json \
    #    > ${NGINX_DIRECTORY}/${HOST}.ign

    cp $(pwd)/${HOST}.ign.orig3 ${NGINX_DIRECTORY}/${HOST}.ign
}


TYPE="bootstrap"
HOST="bootstrap"
IP=172.24.10.19
create_ifcfg
modify_ignition

TYPE="master"
HOST="master1"
IP=172.24.10.21
create_ifcfg
modify_ignition

HOST="master2"
IP=172.24.10.22
create_ifcfg
modify_ignition

HOST="master3"
IP=172.24.10.23
create_ifcfg
modify_ignition

TYPE="worker"
HOST=worker1
IP=172.24.10.24
create_ifcfg
modify_ignition

HOST="worker2"
IP=172.24.10.25
create_ifcfg
modify_ignition

HOST="worker3"
IP=172.24.10.26
create_ifcfg
modify_ignition

rm $(pwd)/*.orig? $(pwd)/*.json

