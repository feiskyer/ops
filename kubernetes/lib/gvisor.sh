#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

GOVERSION="1.10.2"
CRIO_VERSION="1.10.1"
KUBERNTES_LIB_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_LIB_ROOT}/docker.sh

install-go() {
    # Install Golang if not installed yet.
    if ! which go > /dev/null 2>&1; then
        curl -sL https://storage.googleapis.com/golang/go$GOVERSION.linux-amd64.tar.gz | tar -C /usr/local -zxf -
        export GOPATH=/go
    fi
}

install-crio() {
    add-apt-repository -y ppa:alexlarsson/flatpak
    add-apt-repository -y ppa:projectatomic/ppa
    apt-get install -y \
        btrfs-tools \
        git \
        golang-go \
        libassuan-dev \
        libdevmapper-dev \
        libglib2.0-dev \
        libc6-dev \
        libgpgme11-dev \
        libgpg-error-dev \
        libseccomp-dev \
        libselinux1-dev \
        pkg-config \
        go-md2man \
        runc \
        skopeo-containers
    if [ ! -d $GOPATH/src/github.com/kubernetes-incubator/cri-o ]; then
        git clone https://github.com/kubernetes-incubator/cri-o $GOPATH/src/github.com/kubernetes-incubator/cri-o
    fi
    cd $GOPATH/src/github.com/kubernetes-incubator/cri-o
    git checkout v${CRIO_VERSION}
    make install.tools
    make && make install install.config
    cd -

    sed -i 's/\/usr\/bin\/runc/\/usr\/local\/sbin\/runc/g' /etc/crio/crio.conf
    cat <<EOF >/etc/systemd/system/crio.service
[Unit]
Description=CRI-O daemon
Documentation=https://github.com/kubernetes-incubator/cri-o

[Service]
ExecStart=/usr/local/bin/crio
Restart=always
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl restart crio
}

# Install gvisor from source code.
install-gvisor-src() {
    # Install Go
    install-go

    # Install Bazel
    apt-get install openjdk-8-jdk -y
    echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list
    curl https://bazel.build/bazel-release.pub.gpg | apt-key add -
    apt-get update && apt-get install bazel -y

    # Build gvisor
    if [ ! -d "/tmp/gvisor" ]; then
        git clone https://gvisor.googlesource.com/gvisor /tmp/gvisor
    fi
    cd /tmp/gvisor
    bazel build runsc
    cp -f ./bazel-bin/runsc/linux_amd64_pure_stripped/runsc /usr/local/bin
    cd -
}

# Install gvisor from nightly build.
install-gvisor() {
    wget https://storage.googleapis.com/gvisor/releases/nightly/latest/runsc
    chmod +x runsc
    mv runsc /usr/local/bin
}

