#!/bin/bash
# Setup kubernetes with ovn-kubernetes plugin.

LOCAL_IP=$(hostname -I | awk '{print $1}')
CENTRAL_IP=${CENTRAL_IP:-$LOCAL_IP}
CLUSTER_CIDR=${CLUSTER_CIDR:-"10.244.0.0/16"}
CNI_VERSION=${CNI_VERSION:-"v0.6.0"}
KUBECONFIG=${KUBECONFIG:-"/var/run/kubernetes/admin.kubeconfig"}
ENABLE_TLS=${ENABLE_TLS:-false}

ovn-kubernetes-install() {
    # install ovn-kubernetes on all master and nodes
    git clone https://github.com/openvswitch/ovn-kubernetes $GOPATH/src/github.com/openvswitch/ovn-kubernetes
    cd $GOPATH/src/github.com/openvswitch/ovn-kubernetes
    pip install .
    cd go-controller
    make && make install
}

install-cni() {
    mkdir -p /etc/cni/net.d  /opt/cni/bin
    curl -sSL https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-amd64-${CNI_VERSION}.tgz -o cni.tgz
    tar zxvf cni.tgz -C /opt/cni/bin && rm -f cni.tgz
}

master-config() {
    # Config kubernetes master.
    # create a cluster wide logical router, a connected logical switch for the master
    # node and a logical port and a OVS internal interface named "k8s-$NODE_NAME"
    # with an IP address via which other nodes should be eventually able to reach
    # the daemons running on this node.
    if [[ "${ENABLE_TLS}" = false ]]; then
        ovnkube --init-master `hostname` \
        --apiserver "http://127.0.0.1:8080" \
        --cluster-subnet "${CLUSTER_CIDR}" \
        --ovn-north-db "tcp://${CENTRAL_IP}:6641" \
        --ovn-south-db "tcp://${CENTRAL_IP}:6642" \
        --net-controller \
        --token token
    else
        ovnkube --init-master `hostname` \
        --kubeconfig "${KUBECONFIG}" \
        --cluster-subnet "${CLUSTER_CIDR}" \
        --ovn-north-db "tcp://${CENTRAL_IP}:6641" \
        --ovn-south-db "tcp://${CENTRAL_IP}:6642" \
        --net-controller
    fi
}

node-config() {
    # Create a service account.
    kubectl create sa token
    # Install CNI plugins.
    install-cni
    # Configure kubernetes node.
    if [[ "${ENABLE_TLS}" = false ]]; then
        ovnkube --init-node `hostname` \
        --apiserver "http://127.0.0.1:8080" \
        --cluster-subnet "${CLUSTER_CIDR}" \
        --ovn-north-db "tcp://${CENTRAL_IP}:6641" \
        --ovn-south-db "tcp://${CENTRAL_IP}:6642" \
        --token token
    else
        ovnkube --init-node `hostname` \
        --kubeconfig "${KUBECONFIG}" \
        --ca-cert "/var/run/kubernetes/server-ca.crt" \
        --apiserver "https://localhost:6443" \
        --cluster-subnet "${CLUSTER_CIDR}" \
        --ovn-north-db "tcp://${CENTRAL_IP}:6641" \
        --ovn-south-db "tcp://${CENTRAL_IP}:6642" \
        --token token
    fi
}

gateway-config() {
    # Config ovn gateway.
    # Gateway nodes are needed for North-South connectivity. OVN has support for
    # multiple gateway nodes.
    ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="$CENTRAL_IP:8080"
    # Option 1: dedicated physical interface for gateway 
    ovn-k8s-overlay gateway-init \
      --cluster-ip-subnet="$CLUSTER_CIDR" \
      --physical-interface eth1 \
      --physical-ip "$PHYSICAL_IP/24" \
      --node-name="$NODE_NAME" \
      --default-gw "$EXTERNAL_GATEWAY"
    # Option 2: share a single network interface for both your management traffic
    # as well as the cluster's North-South traffic. 
    # ovn-k8s-util nics-to-bridge eth0
    # ovn-k8s-overlay gateway-init \
    #   --cluster-ip-subnet="$CLUSTER_CIDR" \
    #   --bridge-interface breth0 \
    #   --physical-ip "$PHYSICAL_IP" \
    #   --node-name="$NODE_NAME" \
    #   --default-gw "$EXTERNAL_GATEWAY"
    # ovn-k8s-gateway-helper --physical-bridge=breth0 --physical-interface=eth0 \
    #     --pidfile --detach
}

local-up-kubernetes() {
    export NET_PLUGIN="cni"
    export HOSTNAME_OVERRIDE=$(hostname)
    ! go get -d k8s.io/kubernetes
    cd $GOPATH/src/k8s.io/kubernetes
    hack/install-etcd.sh
    export PATH=$GOPATH/src/k8s.io/kubernetes/third_party/etcd:${PATH}
    hack/local-up-cluster.sh
}

ovn-kubernetes-install
master-config
node-config

# ovn-k8s-overlay master-init \
#   --cluster-ip-subnet="10.244.0.0/16" \
#   --master-switch-subnet="10.244.1.0/24" \
#   --node-name=$(hostname)
# ovn-k8s-overlay minion-init \
#   --cluster-ip-subnet="10.244.0.0/16" \
#   --minion-switch-subnet="10.244.2.0/24" \
#   --node-name=$(hostname)

# ovn-k8s-watcher \
#   --overlay \
#   --pidfile \
#   --log-file \
#   -vfile:info \
#   -vconsole:emer \
#   --detach

# ovn-k8s-overlay gateway-init \
#       --cluster-ip-subnet="10.244.0.0/16" \
#       --physical-interface ens5 \
#       --physical-ip "10.149.0.2/24" \
#       --node-name=$(hostname) \
#       --default-gw "10.149.0.1"
