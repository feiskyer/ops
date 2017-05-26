#!/bin/bash
STACKUBE_ROOT=$(dirname "${BASH_SOURCE}")

function configure_cni {
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

function install_docker {
    if is_ubuntu; then
        apt-get update
        apt-get install -y docker.io
        systemctl enable docker
        systemctl start docker
    elif is_fedora; then
        yum install -y docker
        systemctl enable docker
        systemctl start docker
    else
        exit_distro_not_supported
    fi
}

function install_hyper {
    if is_ubuntu; then
        apt-get update && apt-get install -y qemu libvirt-bin
    elif is_fedora; then
        yum install -y libvirt
    fi

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

function install_frakti {
    if command -v /usr/bin/frakti > /dev/null 2>&1; then
        rm -f /usr/bin/frakti
    fi
    curl -sSL https://github.com/kubernetes/frakti/releases/download/${FRAKTI_VERSION}/frakti -o /usr/bin/frakti
    chmod +x /usr/bin/frakti
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

function install_kubelet {
    if is_fedora; then
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
        sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
        yum install -y kubernetes-cni kubelet kubeadm kubectl
    elif is_ubuntu; then
        apt-get update && apt-get install -y apt-transport-https
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
        apt-get update
        apt-get install -y kubernetes-cni kubelet kubeadm kubectl
    else
        exit_distro_not_supported
    fi
}

function install_master {
    kubeadm init kubeadm init --pod-network-cidr ${CLUSTER_CIDR} --config ${STACKUBE_ROOT}/kubeadm.yaml
    # Enable schedule pods on the master for testing.
    export KUBECONFIG=/etc/kubernetes/admin.conf
    kubectl taint nodes --all node-role.kubernetes.io/master-
}

function install_node {
    if [ "${KUBEADM_TOKEN}" = "" ]; then
        echo "KUBEADM_TOKEN must be set for node"
        exit 1
    fi
    kubeadm join --token "${KUBEADM_TOKEN}" ${KUBERNETES_MASTER_IP}:${KUBERNETES_MASTER_PORT}
}

function configure_kubelet {
    sed -i '2 i\Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --container-runtime-endpoint=/var/run/frakti.sock --feature-gates=AllAlpha=true"' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
    systemctl daemon-reload
}

function remove_kubernetes {
    kubeadm reset
    systemctl stop kubelet

    if is_fedora; then
        yum remove -y qemu-hyper hyperstart hyper-container libvirt
        yum remove -y kubernetes-cni kubelet kubeadm kubectl docker
    elif is_ubuntu; then
        apt-get remove -y hyperstart hyper-container qemu libvirt-bin
        apt-get remove -y kubernetes-cni kubelet kubeadm kubectl docker
    fi

    rm -rf /usr/bin/frakti /etc/cni/net.d /lib/systemd/system/frakti.service
}

function install_stackube {
    install_docker
    install_hyper
    install_kubelet
}

function init_stackube {
    if is_service_enabled kubernetes_master; then
        install_master
    else is_service_enabled kubernetes_node; then
        install_node
    fi
}

function configure_stackube {
    configure_cni
    configure_kubelet
}

# check for service enabled
if is_service_enabled stackube; then

    if [[ "$1" == "stack" && "$2" == "install" ]]; then
        echo_summary "Installing stackube"
        install_stackube

    elif [[ "$1" == "stack" && "$2" == "post-config" ]]; then
        echo_summary "Configuring stackube"
        configure_stackube

    elif [[ "$1" == "stack" && "$2" == "extra" ]]; then
        # Initialize and start the stackube service
        echo_summary "Initializing stackube"
        init_stackube
    fi

    if [[ "$1" == "unstack" ]]; then
        remove_kubernetes
    fi

    if [[ "$1" == "clean" ]]; then
        echo ''
    fi
fi