#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}
CNI_VERSION=${CNI_VERSION:-"v0.6.0"}

install-flannel() {
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
}

install-azure-vnet() {
    wget https://github.com/Azure/azure-container-networking/releases/download/v1.0.0/azure-vnet-cni-linux-amd64-v1.0.0.tgz
    gunzip azure-vnet-cni-linux-amd64-v1.0.0.tgz
    tar xvf azure-vnet-cni-linux-amd64-v1.0.0.tar
    mkdir -p /opt/cni/bin/ /etc/cni/net.d/
    mv azure-vnet azure-vnet-ipam /opt/cni/bin/
    mv 10-azure.conf /etc/cni/net.d/
}

install-calico() {
    curl -O -L https://docs.projectcalico.org/v3.0/getting-started/kubernetes/installation/hosted/kubeadm/1.7/calico.yaml
    sed -i -e 's/192\.168/10.244/' calico.yaml
    kubectl apply -f calico.yaml
}

install-weave() {
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
}

install-cni() {
    mkdir -p /etc/cni/net.d  /opt/cni/bin
    curl -sSL https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz -o cni.tgz
    tar zxvf cni.tgz -C /opt/cni/bin && rm -f cni.tgz
}

install-cni-frakti() {
    mkdir -p /etc/cni/net.d  /opt/cni/bin
    curl -sSL https://github.com/kubernetes/frakti/releases/download/v1.0/cni-amd64-v0.6.0-rc1.tgz -o cni.tgz
    tar zxvf cni.tgz -C /opt/cni/bin && rm -f cni.tgz
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
    cd -
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
                "subnet": "${CONTAINER_CIDR}",
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
