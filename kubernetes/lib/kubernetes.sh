#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CONTAINER_CIDR=${CONTAINER_CIDR:-"10.244.1.0/24"}
CONTAINER_RUNTIME=${CONTAINER_RUNTIME:-"docker"}

KUBERNTES_LIB_ROOT=$(dirname "${BASH_SOURCE}")
source ${KUBERNTES_LIB_ROOT}/containerd.sh
source ${KUBERNTES_LIB_ROOT}/hyper.sh
source ${KUBERNTES_LIB_ROOT}/util.sh
source ${KUBERNTES_LIB_ROOT}/docker.sh
source ${KUBERNTES_LIB_ROOT}/gvisor.sh

setup-kubelet-infra-container-image() {
    cat > /etc/systemd/system/kubelet.service.d/20-pod-infra-image.conf <<EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--pod-infra-container-image=crproxy.trafficmanager.net:6000/google_containers/pause-amd64:3.1"
EOF
    systemctl daemon-reload
}

install-kubelet-centos() {
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    yum install -y kubernetes-cni kubelet kubeadm kubectl
}

install-kubelet-centos-mirror() {
    cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
    yum install -y kubernetes-cni kubelet kubeadm kubectl
    setup-kubelet-infra-container-image
}

install-kubelet-ubuntu() {
    apt-get update && apt-get install -y apt-transport-https
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF > /etc/apt/sources.list.d/kubernetes.list
deb http://apt.kubernetes.io/ kubernetes-xenial main
EOF
    apt-get update
    # kubernetes-cni will be installed automatically with kubelet
    apt-get install -y kubernetes-cni kubelet kubeadm kubectl
}

install-kubelet-ubuntu-mirror() {
    apt-get update && apt-get install -y apt-transport-https
    curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
    cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
    apt-get update
    apt-get install -y kubernetes-cni kubelet kubeadm kubectl
    setup-kubelet-infra-container-image
}

setup-container-runtime() {
    lsb_dist=$(lsb-dist)

    case "${CONTAINER_RUNTIME}" in

        docker)
            if [ "$lsb_dist" = "ubuntu" ]; then
                install-docker-ubuntu
            else
                install-docker-centos
            fi
            rm -f /etc/systemd/system/kubelet.service.d/11-container-runtime.conf
            ;;

        containerd)
            install-containerd
            cat <<EOF >/etc/systemd/system/kubelet.service.d/11-container-runtime.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///run/containerd/containerd.sock"
EOF
            ;;

        cri-o)
            #docker-install-latest
            install-crio
            cat <<EOF >/etc/systemd/system/kubelet.service.d/11-container-runtime.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///var/run/crio/crio.sock"
EOF
            ;;

        gvisor)
            #docker-install-latest
            install-crio
            install-gvisor
            sed -i 's/runtime_untrusted_workload = ""/runtime_untrusted_workload = "\/usr\/local\/bin\/runsc"/g' /etc/crio/crio.conf
            cat <<EOF >/etc/systemd/system/kubelet.service.d/11-container-runtime.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///var/run/crio/crio.sock"
EOF
            ;;

        frakti)
            cat <<EOF >/etc/systemd/system/kubelet.service.d/11-container-runtime.conf
[Service]
Environment="KUBELET_EXTRA_ARGS=--container-runtime=remote --runtime-request-timeout=15m --container-runtime-endpoint=unix:///var/run/frakti.sock"
EOF
            ;;

        *)
            echo "Container runtime ${CONTAINER_RUNTIME} not supported"
            exit 1
            ;;
    esac

    systemctl daemon-reload
}

setup-master() {
    # Sometime /var/lib/kubelet is not empty after kubelet installation.
    rm -rf /var/lib/kubelet
    # Setup mirror
    if [ ! -z "$USE_MIRROR" ]; then
        sed -i 's/imageRepository: ""/imageRepository: crproxy.trafficmanager.net:6000\/google_containers/' ${KUBERNTES_LIB_ROOT}/kubeadm.yaml
    fi
    # Setup master
    kubeadm init --config ${KUBERNTES_LIB_ROOT}/kubeadm.yaml --ignore-preflight-errors all
    # create default host-path storage class
    # kubectl create -f ${KUBERNTES_LIB_ROOT}/storage-class.yaml
    # Also enable schedule pods on the master for allinone.
    mkdir -p $HOME/.kube
    sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    kubectl taint nodes --all node-role.kubernetes.io/master-

    # approve kubelet csr because all alpha features are enabled.
    # see https://kubernetes.io/docs/admin/kubelet-tls-bootstrapping/
    if [ $(kubectl get csr | awk '/^csr/{print $1}' | wc -l) -gt 0 ]; then
      kubectl certificate approve $(kubectl get csr | awk '/^csr/{print $1}')
    fi
}

setup-node() {
    if [[ $# < 2 ]]; then
        echo "Usage: setup-node token master_ip [port]"
        exit 1
    fi

    token="$1"
    master_ip="$2"
    port="6443"
    if [[ $# == 3 ]]; then
        port="$3"
    fi

    # join master on worker nodes
    kubeadm join --ignore-preflight-errors all --discovery-token-unsafe-skip-ca-verification --token $token ${master_ip}:$port
}
