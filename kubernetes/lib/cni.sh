#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}
CNI_VERSION=${CNI_VERSION:-"v0.5.2"}

install-cni() {
    mkdir -p /etc/cni/net.d  /opt/cni/bin
    curl -sSL https://github.com/containernetworking/cni/releases/download/${CNI_VERSION}/cni-amd64-${CNI_VERSION}.tgz -o cni.tgz
    tar zxvf cni.tgz -C /opt/cni/bin
}

cni_install_ubuntu() {
    apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update
    apt-get install -y kubernetes-cni
}

cni_install_centos() {
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://yum.kubernetes.io/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    setenforce 0
    yum install -y kubernetes-cni
}

install-cni-src() {
    mkdir -p /opt/cni/bin
    git clone https://github.com/containernetworking/plugins $GOPATH/src/github.com/containernetworking/plugins
    cd $GOPATH/src/github.com/containernetworking/plugins
    ./build.sh
    cp bin/* /opt/cni/bin/
}

config-cni() {
    # Ensure CNI forward
    iptables -A FORWARD -i cni0 -j ACCEPT
    iptables -A FORWARD -o cni0 -j ACCEPT

    mkdir -p /etc/cni/net.d
    cat >/etc/cni/net.d/10-mynet.conf <<-EOF
{
    "cniVersion": "0.3.0",
    "name": "mynet",
    "type": "bridge",
    "bridge": "cni0",
    "isGateway": true,
    "ipMasq": true,
    "ipam": {
        "type": "host-local",
        "subnet": "${CONTAINER_CIDR}",
        "routes": [
            { "dst": "0.0.0.0/0"  }
        ]
    }
}
EOF
    cat >/etc/cni/net.d/99-loopback.conf <<-EOF
{
    "cniVersion": "0.3.0",
    "type": "loopback"
}
EOF
}

config-cni-list() {
    # Ensure CNI forward
    iptables -A FORWARD -i cni0 -j ACCEPT
    iptables -A FORWARD -o cni0 -j ACCEPT
    mkdir -p /etc/cni/net.d
    cat >/etc/cni/net.d/10-mynet.conflist <<-EOF
{
    "cniVersion": "0.3.1",
    "name": "mynet",
    "plugins": [
        {
            "type": "bridge",
            "bridge": "cni0",
            "isGateway": true,
            "ipMasq": true,
            "ipam": {
                "type": "host-local",
                "subnet": "10.30.0.0/16",
                "routes": [
                    { "dst": "0.0.0.0/0"   }
                ]
            }
        },
        {
            "type": "portmap",
            "capabilities": {"portMappings": true},
            "snat": true
        }
    ]
}
EOF
    cat >/etc/cni/net.d/99-loopback.conf <<-EOF
{
    "cniVersion": "0.3.1",
    "type": "loopback"
}
EOF
}
