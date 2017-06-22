#!/usr/bin/env bash

RELEASE=${RELEASE:-"CentOS7Atomic"}
CLEAN_SYSTEM=${CLEAN_SYSTEM:-"Y"}
DOCKERFILE_NAME=${DOCKERFILE_NAME:-"Dockerfile"}
KICKSTART="https://raw.githubusercontent.com/kbsingh/atomic-container/master/centos-docker-base-minimal.ks";
VM_DOMAIN=${VM_DOMAIN-"centos_atomic_image"};
VM_NETWORK=${VM_NETWORK-"default"};
IMAGE_TAR_NAME=${IMAGE_TAR_NAME-"centos_atomic.tar"};
CENTOS_INSTALL_SOURCE_URL=${CENTOS_INSTALL_SOURCE_URL-"http://mirror.centos.org/centos/7/os/x86_64"};

install_pkgs(){
    INSTALL_PKGS1="libvirt-*";
    INSTALL_PKGS2="virt-install libguestfs";
}
gen_dockerfile(){
cat >${1} <<EOF
FROM scratch

ADD ./${IMAGE_TAR_NAME} /

LABEL name="CentOS Atomic Base Image" \
    vendor="CentOS" \
    license="GPLv2"

CMD ["/bin/bash"]
EOF
}

if [ ${CLEAN_SYSTEM} == "Y" ]; then
    # Install necessary packages
    install_pkgs;
fi

# Enable and start libvirtd
systemctl enable libvirtd && systemctl start libvirtd;

if [ -d "./${RELEASE}" -o -f "./${RELEASE}" ]; then
    rm -rf "./${RELEASE}"
fi

virt-install --name ${VM_DOMAIN} --noreboot --memory 4096 --vcpus 1,cpuset=auto \
     --disk size=2,sparse=no,format=raw --network network=${VM_NETWORK} \
     --graphics=none --console pty,target_type=serial \
     --location ${CENTOS_INSTALL_SOURCE_URL} --extra-args "console=ttyS0,115200n8 serial ks=${KICKSTART}";

virt-tar-out -d "${VM_DOMAIN}" / "${RELEASE}/${IMAGE_TAR_NAME}";
gen_dockerfile "./${RELEASE}/${IMAGE_TAR_NAME}"