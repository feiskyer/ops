#!/bin/sh
#
# Setup and install hyperd.
#
set -e

check_hyperd() {
    which hyperd>/dev/null
    if [[ $? != 0 ]]; then
        echo "Please install hyperd from hypercontainer.io"
        exit 1
    fi
}

check_go() {
    which go>/dev/null
    if [[ $? != 0 ]]; then
        echo "Please install go from golang.org"
        exit 1
    fi
}

frakti_install() {
    curl -sSL https://github.com/kubernetes/frakti/releases/download/v0.1/frakti -o /usr/bin/frakti
    chmod +x /usr/bin/frakti
    cat <<EOF > /lib/systemd/system/frakti.service
[Unit]
Description=Hypervisor-based container runtime for Kubernetes
Documentation=https://github.com/kubernetes/frakti
After=network.target
[Service]
ExecStart=/usr/bin/frakti --v=3 \
          --log-dir=/var/log/frakti \
          --logtostderr=false \
          --listen=/var/run/frakti.sock \
          --streaming-server-addr=%H \
          --hyper-endpoint=127.0.0.1:22318
MountFlags=shared
TasksMax=8192
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
Restart=on-abnormal
[Install]
WantedBy=multi-user.target
EOF

    frakti_build
    systemctl enable frakti
    systemctl start frakti
}

frakti_build() {
    mkdir -p $GOPATH/src/k8s.io
    git clone https://github.com/kubernetes/frakti.git $GOPATH/src/k8s.io/frakti
    cd $GOPATH/src/k8s.io/frakti
    make && make install
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

check_hyperd
check_go
lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
case "$lsb_dist" in

    ubuntu)
        frakti_install
    ;;

    fedora|centos|redhat)
        frakti_install
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
