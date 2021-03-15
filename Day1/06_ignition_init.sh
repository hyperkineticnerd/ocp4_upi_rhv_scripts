#!/usr/bin/bash

SCRIPT_DIR="$(dirname $0)"

NGINX_DIRECTORY="/var/www/html"

CLUSTER_NAME="ocp4"
DOMAIN_NAME="hkn.lab"
FIPS="true"

PULL_SECRET="$(cat $HOME/ocp4-pull-secret.json)"
SSH_KEY="$(cat $HOME/.ssh/id_rsa_rhcos.pub)"

LOCAL_REGISTRY="nexus.developer.hkn.lab:5000"
TRUST_BUNDLE="" # $(cat /etc/ipa/ca.crt)"

INSTALLER="${SCRIPT_DIR}/openshift-install"

if [ ! -f "$(pwd)/install-config.yaml.bak" ]; then
cat > $(pwd)/install-config.yaml.bak << EOF 
apiVersion: v1
baseDomain: ${DOMAIN_NAME}
compute:
- hyperthreading: Enabled   
  name: worker
  replicas: 0 
controlPlane:
  hyperthreading: Enabled   
  name: master 
  replicas: 3 
metadata:
  name: ${CLUSTER_NAME}
networking:
  clusterNetwork:
  - cidr: 10.128.0.0/14 
    hostPrefix: 23 
  networkType: OpenShiftSDN
  serviceNetwork: 
  - 172.30.0.0/16
platform:
  none: {} 
fips: ${FIPS} 
pullSecret: '${PULL_SECRET}' 
sshKey: '${SSH_KEY}' 
#additionalTrustBundle: | 
#  ${TRUST_BUNDLE}
#imageContentSources: 
#- mirrors:
#  - ${LOCAL_REGISTRY}/openshift-release-dev/ocp-release
#  source: quay.io/openshift-release-dev/ocp-release
#- mirrors:
#  - ${LOCAL_REGISTRY}/openshift-release-dev/ocp-release
#  source: registry.svc.ci.openshift.org/ocp/release
#- mirrors:
#  - ${LOCAL_REGISTRY}/openshift-release-dev/ocp-v4.0-art-dev
#  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
EOF
fi

ln -sf $(pwd)/install-config.yaml.bak $(pwd)/install-config.yaml

${INSTALLER} --log-level=debug create ignition-configs

#./network.sh
#./network2.sh

