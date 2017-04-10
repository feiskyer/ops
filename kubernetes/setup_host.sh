#!/bin/sh
#
# Setup host with go, docker and qemu.
#
set -e

command_exists() {
    command -v "$@" > /dev/null 2>&1
}

init_system_ubuntu() {
    apt-get update
    apt-get install -y build-essential qemu autoconf automake pkg-config libdevmapper-dev libsqlite3-dev libvirt-dev
}

init_system_centos() {
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64-unstable
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    setenforce 0
    yum install -y ceph-devel zlib-devel glib2-devel libtool qemu-kvm ceph-common libcap-devel libattr-devel fuse-devel yajl-devel libxml2-devel libpciaccess-devel libnl-devel git cmake gcc g++ autoconf automake device-mapper-devel sqlite-devel
}

docker_install_ubuntu() {
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
}

docker_install_centos() {
    yum install -y docker
    # sed -i 's/native.cgroupdriver=systemd/native.cgroupdriver=cgroupfs/g' /usr/lib/systemd/system/docker.service
    # systemctl daemon-reload
    systemctl enable docker
    systemctl start docker
}

go_install() {
    # install golang
    curl -sL https://storage.googleapis.com/golang/go1.7.5.linux-amd64.tar.gz | tar -C /usr/local -zxf -
    echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/local/go/bin/:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/go/bin"' >> /etc/environment
    echo 'GOPATH="/go"' >> /etc/environment
}

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

case "$lsb_dist" in

    ubuntu)
        init_system_ubuntu
        go_install
        docker_install_ubuntu
    ;;

    fedora|centos|redhat)
        init_system_centos
        go_install
        docker_install_centos
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
