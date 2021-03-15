#!/usr/bin/bash

NGINX_DIRECTORY="/var/www/html"
ARCH="x86_64"
RHCOSVERSION="4.5.6"
CLUSTER_NAME="ocp4"
DOMAIN_NAME="hkn.lab"

BASTION_IP=""
GATEWAY="172.24.0.1"
NETMASK="255.255.0.0"
NET_INTERFACE="enp1s0"
URL="http://${BASTION_IP}:8080"
DNS1="172.16.0.9"
DNS2="172.24.0.1"

DISK_ISO="rhcos-${RHCOSVERSION}-${ARCH}-installer.${ARCH}.iso"
DISK_RAW="rhcos-${RHCOSVERSION}-${ARCH}-metal.${ARCH}.raw.gz"
DISK_INSTALL_DEV="sda"

export VOLID=$(isoinfo -d -i ${NGINX_DIRECTORY}/${DISK_ISO} | awk '/Volume id/ { print $3 }')
TEMPDIR=$(mktemp -d)

cd ${TEMPDIR}
# Extract the ISO content using guestfish (to avoid sudo mount)
guestfish -a ${NGINX_DIRECTORY}/${DISK_ISO} -m /dev/sda tar-out / - | tar xvf -

for FILE in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
    cp ${FILE} $(pwd)/${FILE##*/}.orig
done

# Helper function to modify the config files
modify_cfg(){
    RHCOS_BOOT=""
    RHCOS_BOOT+=" coreos.inst.install_dev=${DISK_INSTALL_DEV}"
    RHCOS_BOOT+=" coreos.inst.image_url=${URL}/${DISK_RAW}"
    RHCOS_BOOT+=" coreos.inst.ignition_url=${URL}/${NODE}.ign"
    RHCOS_BOOT+=" ip=${IP}::${GATEWAY}:${NETMASK}:${NODE}.${CLUSTER_NAME}.${DOMAIN_NAME}:${NET_INTERFACE}:none"
    RHCOS_BOOT+=" nameserver=${DNS1} nameserver=${DNS2}"

    for FILE in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
        # Append the proper image and ignition urls
        sed -e '/coreos.inst=yes/s|$| '"${RHCOS_BOOT}"'|' \
            $(pwd)/${FILE##*/}.orig > $(pwd)/${NODE}_${FILE##*/}
        # Boot directly in the installation
        sed -i \
            -e 's/default vesamenu.c32/default linux/g' \
            -e 's/timeout 600/timeout 10/g' \
            $(pwd)/${NODE}_${FILE##*/}
    done
}

generate_iso(){
    # Generate the images, one per node as the IP configuration is different...
    # https://github.com/coreos/coreos-assembler/blob/master/src/cmd-buildextend-installer#L97-L103

    # Overwrite the grub.cfg and isolinux.cfg files for each node type
    for FILE in "EFI/redhat/grub.cfg" "isolinux/isolinux.cfg"; do
        cp $(pwd)/${NODE}_${FILE##*/} ${FILE}
    done
    # As regular user!
    genisoimage -verbose -rock -J -joliet-long -volset ${VOLID} \
        -eltorito-boot isolinux/isolinux.bin -eltorito-catalog isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -eltorito-alt-boot -efi-boot images/efiboot.img -no-emul-boot \
        -o ${NGINX_DIRECTORY}/${NODE}.iso .
}

# BOOTSTRAP
TYPE="bootstrap"
NODE="bootstrap"
IP=172.24.10.19
modify_cfg
generate_iso

# MASTERS
TYPE="master"
# MASTER-1
NODE="master1"
IP=172.24.10.21
modify_cfg
generate_iso

# MASTER-2
NODE="master2"
IP=172.24.10.22
modify_cfg
generate_iso

# MASTER-3
NODE="master3"
IP=172.24.10.23
modify_cfg
generate_iso

# WORKERS
TYPE="worker"
# WORKER-1
NODE="worker1"
IP=172.24.10.24
modify_cfg
generate_iso

# WORKER-2
NODE="worker2"
IP=172.24.10.25
modify_cfg
generate_iso

# WORKER-3
NODE="worker3"
IP=172.24.10.26
modify_cfg
generate_iso

# Optionally, clean up
# cd
# rm -Rf ${TEMPDIR}
