#!/bin/bash
#
# Setup kubelet with ovn plugin
#

K8S_API_SERVER_IP='127.0.0.1'
CLUSTER_IP_SUBNET="10.244.0.0/16"
MASTER_SWITCH_SUBNET="10.244.0.1/24"
# all-in-one, so same with master
MINION_SWITCH_SUBNET="10.244.0.1/24"

ovn-kubernetes-install() {
	# install ovn-kubernetes on all master and nodes
	git clone https://github.com/openvswitch/ovn-kubernetes $GOPATH/src/github.com/openvswitch/ovn-kubernetes
	cd $GOPATH/src/github.com/openvswitch/ovn-kubernetes
	apt install python-pip -y
	pip install .
}

master-config() {
	# k8s master node init
	# create a cluster wide logical router, a connected logical switch for the master
	# node and a logical port and a OVS internal interface named "k8s-$NODE_NAME"
	# with an IP address via which other nodes should be eventually able to reach
	# the daemons running on this node.
	ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="127.0.0.1:8080"
	ovn-k8s-overlay master-init \
	  --cluster-ip-subnet=$CLUSTER_IP_SUBNET \
	  --master-switch-subnet="$MASTER_SWITCH_SUBNET" \
	  --node-name="$(hostname)"
	ovn-k8s-watcher \
	  --overlay \
	  --pidfile \
	  --log-file \
	  -vfile:info \
	  -vconsole:emer \
	  --detach
}

node-config() {
	# k8s minion node init
	# ovs-vsctl set Open_vSwitch . \
	#   external_ids:k8s-api-server="https://$K8S_API_SERVER_IP" \
	#   external_ids:k8s-ca-certificate="$CA_CRT" \
	#   external_ids:k8s-api-token="$API_TOKEN"
	ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="$K8S_API_SERVER_IP:8080"
	# remove old cni network config
	rm -f /etc/cni/net.d/*.conf
	# setup cni for kubelet
	ovn-k8s-overlay minion-init \
	  --cluster-ip-subnet="$CLUSTER_IP_SUBNET" \
	  --minion-switch-subnet="$MINION_SWITCH_SUBNET" \
	  --node-name="$(hostname)"
}

gateway-config() {
	# k8s gateway node init
	# Gateway nodes are needed for North-South connectivity. OVN has support for
	# multiple gateway nodes.
	ovs-vsctl set Open_vSwitch . external_ids:k8s-api-server="$K8S_API_SERVER_IP:8080"
	# Option 1: dedicated physical interface for gateway 
	# ovn-k8s-overlay gateway-init \
	#   --cluster-ip-subnet="$CLUSTER_IP_SUBNET" \
	#   --physical-interface eth1 \
	#   --physical-ip "$PHYSICAL_IP/24" \
	#   --node-name="$NODE_NAME" \
	#   --default-gw "$EXTERNAL_GATEWAY"
	# Option 2: share a single network interface for both your management traffic
	# as well as the cluster's North-South traffic. 
	ovn-k8s-util nics-to-bridge eth0
	ovn-k8s-overlay gateway-init \
	  --cluster-ip-subnet="$CLUSTER_IP_SUBNET" \
	  --bridge-interface breth0 \
	  --physical-ip "$PHYSICAL_IP" \
	  --node-name="$NODE_NAME" \
	  --default-gw "$EXTERNAL_GATEWAY"
	ovn-k8s-gateway-helper --physical-bridge=breth0 --physical-interface=eth0 \
	    --pidfile --detach
}

ovn-kubernetes-install
master-config
node-config

