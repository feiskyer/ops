#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

USE_MIRROR=${USE_MIRROR:-""}

docker-install-latest() {
    curl -fsSL https://get.docker.com/ | sh
    systemctl start docker
    iptables -P FORWARD ACCEPT
}

install-docker-ubuntu() {
    apt-get update
    # apt-get install -y docker.io
    apt-get install -y ca-certificates curl gnupg lsb-release
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

install-docker-centos() {
    yum install -y yum-utils device-mapper-persistent-data lvm2
    if [ "$USE_MIRROR" = "" ]; then
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    else
        yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
    fi
    yum install -y yum install docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
}
