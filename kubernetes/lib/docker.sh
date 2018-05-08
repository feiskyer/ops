#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

docker-install-latest() {
    curl -fsSL https://get.docker.com/ | sh
    systemctl start docker
    iptables -P FORWARD ACCEPT
}

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

install-docker-v1.13-ubuntu() {
    sh -c 'echo "deb https://apt.dockerproject.org/repo ubuntu-$(lsb_release -cs) main" > /etc/apt/sources.list.d/docker.list'
    curl -fsSL https://apt.dockerproject.org/gpg | sudo apt-key add -
    apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D
    apt-get update
    apt-get -y install "docker-engine=1.13.1-0~ubuntu-$(lsb_release -cs)"
    # Enable forward for docker v1.13+
    iptables -P FORWARD ACCEPT
}

install-docker-v1.13-centos() {
 sudo tee /etc/yum.repos.d/docker.repo <<-'EOF'
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/$releasever/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF
  yum install -y docker-engine-1.13.1
  # Enable forward for docker v1.13+
  iptables -P FORWARD ACCEPT
}
