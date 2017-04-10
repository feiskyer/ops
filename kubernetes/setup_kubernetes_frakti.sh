#!/bin/sh
#
# Install and setup kubernetes all-in-one by kubeadm.
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
    curl -sL https://storage.googleapis.com/golang/go1.8.1.linux-amd64.tar.gz | tar -C /usr/local -zxf -
    echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/local/go/bin/:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/go/bin"' >> /etc/environment
    echo 'GOPATH="/go"' >> /etc/environment
    export PATH="$GOAPTH:/go/bin:/usr/local/go/bin/"
    export GOPATH="/go"
}

cni_install_ubuntu() {
    apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main
EOF
    apt-get update
    apt-get install -y kubernetes-cni
}

cni_install_centos() {
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
    yum install -y kubernetes-cni
}

cni_setup_bridge() {
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
        "subnet": "10.244.1.0/24",
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

kubelet_install_ubuntu() {
    apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial-unstable main
EOF
    apt-get update
    apt-get install -y kubelet kubeadm kubectl
}

kubelet_install_centos() {
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
    yum install -y kubelet kubeadm kubectl
}

hyperd_install_ubuntu() {
    # install from https://docs.hypercontainer.io/get_started/install/linux.html
    curl -k -sSL https://hypercontainer.io/install | bash
    echo -e "Hypervisor=libvirt\n\
Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config
    # TODO: remove this after a stable hyperd is released.
    curl https://hypercontainer-install.s3.amazonaws.com/hypercontainer_0.8.0-1_amd64.deb -o hypercontainer.deb
    curl https://hypercontainer-install.s3.amazonaws.com/hyperstart_0.8.0-1_amd64.deb -o hyperstart.deb
    dpkg -i hyperstart.deb hypercontainer.deb
    rm -f hyperstart.deb hypercontainer.deb

    # TODO: remove this after a stable hyperd is released.
    hyperd_install_src

    systemctl enable hyperd
    systemctl restart hyperd
}

hyperd_install_centos() {
    # install from https://docs.hypercontainer.io/get_started/install/linux.html
    curl -k -sSL https://hypercontainer.io/install | bash
    echo -e "Hypervisor=libvirt\n\
Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config

    # TODO: remove this after a stable hyperd is released.
    hyperd_install_src

    systemctl enable hyperd
    systemctl restart hyperd
}

hyperd_install_src() {
    mkdir -p $GOPATH/src/k8s.io $GOPATH/src/github.com/hyperhq
    git clone https://github.com/hyperhq/hyperstart $GOPATH/src/github.com/hyperhq/hyperstart
    git clone https://github.com/hyperhq/hyperd $GOPATH/src/github.com/hyperhq/hyperd
    cd $GOPATH/src/github.com/hyperhq/hyperstart
    ./autogen.sh && ./configure && make
    /bin/cp build/{hyper-initrd.img,kernel} /var/lib/hyper
    cd $GOPATH/src/github.com/hyperhq/hyperd
    ./autogen.sh && ./configure
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

kubelet_config() {
    sed -i '2 i\Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=/var/run/frakti.sock --feature-gates=AllAlpha=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    sytemctl daemon-reload
}

kubernetes_setup() {
    # Setting up the master node
    # export KUBE_HYPERKUBE_IMAGE=
    kubeadm init kubeadm init --pod-network-cidr 10.244.0.0/16 --kubernetes-version latest
    # Optional: enable schedule pods on the master
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl taint nodes --all node-role.kubernetes.io/master:NoSchedule-
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
        kubelet_install_ubuntu
        cni_install_ubuntu
        cni_setup_bridge
        hyperd_install_ubuntu
        frakti_install
        kubelet_config
        kubernetes_setup
    ;;

    fedora|centos|redhat)
        init_system_centos
        go_install
        docker_install_centos
        kubelet_install_centos
        cni_install_centos
        cni_setup_bridge
        hyperd_install_centos
        frakti_install
        kubelet_config
        kubernetes_setup
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
