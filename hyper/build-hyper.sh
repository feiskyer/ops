#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

lsb-dist() {
    lsb_dist=''
    if command_exists lsb_release; then
        lsb_dist="$(lsb_release -si)"
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
        lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
        lsb_dist='centos'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
        lsb_dist='redhat'
    fi
    if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
    fi

    lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
    echo ${lsb_dist}
}

dep-install-centos() {
    yum -y install git cmake gcc g++ autoconf automake device-mapper-devel sqlite-devel pcre-devel libsepol-devel libselinux-devel systemd-container-devel automake autoconf gcc make glibc-devel glibc-devel.i686 libvirt-devel
}

dep-install-ubuntu() {
    apt-get install -y -qq autoconf automake pkg-config libdevmapper-dev libsqlite3-dev libvirt-dev libvirt-bin aufs-tools wget libaio1 libpixman-1-0
}

build-hyperd() {
    if [ ! -d ${GOPATH}/src/github.com/hyperhq/hyperd ]; then
        git clone https://github.com/hyperhq/hyperd.git ${GOPATH}/src/github.com/hyperhq/hyperd
    fi
    cd ${GOPATH}/src/github.com/hyperhq/hyperd
    ./autogen.sh && ./configure && make && make install
}

build-hyperstart() {
    git clone https://github.com/hyperhq/hyperstart.git /tmp/hyperstart
    cd /tmp/hyperstart
    ./autogen.sh && ./configure && make
    /bin/cp build/{hyper-initrd.img,kernel} /var/lib/hyper/
    /bin/rm -rf /tmp/hyperstart
}


lsb_dist=$(lsb-dist)
case "$lsb_dist" in

    ubuntu)
        dep-install-ubuntu
    ;;

    fedora|centos|redhat)
        dep-install-centos
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac

build-hyperd
build-hyperstart
