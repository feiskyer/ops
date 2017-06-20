#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

FRAKTI_VERSION=${FRAKTI_VERSION:-"v0.2"}
KUBERNTES_LIB_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_LIB_ROOT}/util.sh

install-hyperd-ubuntu() {
    if ! command_exists hyperd; then
        apt-get update && apt-get install -y qemu libvirt-bin
        curl -sSL https://hypercontainer.io/install | bash
        echo -e "Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config
    fi
    systemctl enable hyperd
    systemctl restart hyperd
}

install-hyperd-centos() {
    if ! command_exists hyperd; then
        curl -sSL https://hypercontainer.io/install | bash
        echo -e "Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config
    fi
    systemctl enable hyperd
    systemctl restart hyperd
}

install-hyperd-src() {
    apt-get update && apt-get install -y qemu autoconf automake pkg-config libdevmapper-dev libsqlite3-dev libvirt-dev libvirt-bin aufs-tools wget libaio1 libpixman-1-0
    mkdir -p $GOPATH/src/github.com/hyperhq
    git clone https://github.com/hyperhq/hyperstart $GOPATH/src/github.com/hyperhq/hyperstart
    git clone https://github.com/hyperhq/hyperd $GOPATH/src/github.com/hyperhq/hyperd
    cd $GOPATH/src/github.com/hyperhq/hyperstart
    ./autogen.sh && ./configure && make
    mkdir -p /var/lib/hyper /var/log/hyper
    /bin/cp build/hyper-initrd.img /var/lib/hyper
    /bin/cp build/kernel /var/lib/hyper
    cd $GOPATH/src/github.com/hyperhq/hyperd
    ./autogen.sh && ./configure && make
    /bin/cp -f hyperd /usr/bin/hyperd
    /bin/cp -f hyperctl /usr/bin/hyperctl
    # sed -i -e '/unix_sock_rw_perms/d' -e '/unix_sock_admin_perms/d' -e '/clear_emulator_capabilities/d' \
    # -e '/unix_sock_group/d' -e '/auth_unix_ro/d' -e '/auth_unix_rw/d' /etc/libvirt/libvirtd.conf
    # echo unix_sock_rw_perms=\"0777\" >> /etc/libvirt/libvirtd.conf
    # echo unix_sock_admin_perms=\"0777\" >> /etc/libvirt/libvirtd.conf
    # echo unix_sock_group=\"root\" >> /etc/libvirt/libvirtd.conf
    # echo unix_sock_ro_perms=\"0777\" >> /etc/libvirt/libvirtd.conf
    # echo auth_unix_ro=\"none\" >> /etc/libvirt/libvirtd.conf
    # echo auth_unix_rw=\"none\" >> /etc/libvirt/libvirtd.conf
    # sed -i -e '/^clear_emulator_capabilities =/d' -e '/^user =/d' -e '/^group =/d' /etc/libvirt/qemu.conf
    # echo clear_emulator_capabilities=0 >> /etc/libvirt/qemu.conf
    # echo user=\"root\" >> /etc/libvirt/qemu.conf
    # echo group=\"root\" >> /etc/libvirt/qemu.conf

    mkdir -p /etc/hyper
    echo -e "Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config

    cat <<EOF > /lib/systemd/system/hyperd.service
[Unit]
Description=hyperd
Documentation=http://docs.hypercontainer.io
After=network.target
Requires=

[Service]
ExecStart=/usr/bin/hyperd --log_dir=/var/log/hyper
MountFlags=shared
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable hyperd
    systemctl restart hyperd
}

install-frakti() {
    if ! command_exists frakti; then
        curl -sSL https://github.com/kubernetes/frakti/releases/download/${FRAKTI_VERSION}/frakti -o /usr/bin/frakti
        chmod +x /usr/bin/frakti
    fi
    cgroup_driver=$(docker info | awk '/Cgroup Driver/{print $3}')
    cat <<EOF > /lib/systemd/system/frakti.service
[Unit]
Description=Hypervisor-based container runtime for Kubernetes
Documentation=https://github.com/kubernetes/frakti
After=network.target
[Service]
ExecStart=/usr/bin/frakti --v=3 \
          --log-dir=/var/log/frakti \
          --logtostderr=false \
          --cgroup-driver=${cgroup_driver} \
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
    systemctl enable frakti
    systemctl start frakti
}

config-kubelet-frakti() {
    sed -i '2 i\Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=/var/run/frakti.sock --feature-gates=AllAlpha=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    systemctl daemon-reload
}


kubelet_config_docker() {
    if [ -f /etc/systemd/system/kubelet.service.d/10-kubeadm.conf ]; then
        sed -i '/frakti/d' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
        systemctl daemon-reload
    else
        echo "Kubelet is not managed by kubeadm"
    fi
}

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

install-frakti-src() {
    mkdir -p $GOPATH/src/k8s.io
    git clone https://github.com/kubernetes/frakti.git $GOPATH/src/k8s.io/frakti
    cd $GOPATH/src/k8s.io/frakti
    make && make install
    cgroup_driver=$(docker info | awk '/Cgroup Driver/{print $3}')
    cat <<EOF > /lib/systemd/system/frakti.service
[Unit]
Description=Hypervisor-based container runtime for Kubernetes
Documentation=https://github.com/kubernetes/frakti
After=network.target
[Service]
ExecStart=/usr/bin/frakti --v=3 \
          --log-dir=/var/log/frakti \
          --logtostderr=false \
          --cgroup-driver=${cgroup_driver} \
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
    systemctl enable frakti
    systemctl start frakti
}
