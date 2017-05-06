#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

install-docker-ubuntu() {
    apt-get update
    apt-get install -y docker.io
    systemctl enable docker
    systemctl start docker
}

install-docker-centos() {
    yum install -y docker
    systemctl enable docker
    systemctl start docker
}

install-docker-v1.13() {
    sh -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -cs) main" > /etc/apt/sources.list.d/docker.list'
    curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
    apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D
    apt-get update
    apt-get -y install "docker-engine=1.13.1-0~ubuntu-$(lsb_release -cs)"
}
