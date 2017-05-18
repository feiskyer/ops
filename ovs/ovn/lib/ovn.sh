#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

ls-create() {
    switch=$1
    if [ -z "$switch" ]; then
        echo "usage: ls-create switch"
        exit 1
    fi

    # Create a logical switch.
    ovn-nbctl --may-exist ls-add $switch
}

ls-add-port() {
    switch=$1
    port=$2
    mac=$3
    cidr=$4

    # Create a logical port on the switch.
    ovn-nbctl --may-exist lsp-add $switch $port

    # Set a MAC address the logical port.
    ovn-nbctl lsp-set-addresses $port $mac

    # Set up port security the logical port.  This ensures that
    # the logical port mac address we have configured is the only allowed
    # source and destination mac address for these ports.
    ovn-nbctl lsp-set-port-security $port $mac $cidr
}

ovs-add-port() {
    bridge=$1
    port=$2
    lport=$3
    gateway=$4

    # Create ports on the local OVS bridge and associates it with OVN logical
    # ports. ovn-controller will then set up the flows necessary for these ports
    # to be able to communicate each other as defined by logical ports.
    ip netns add $port-ns
    ovs-vsctl --may-exist add-port $bridge $port -- set interface $port type=internal
    if [ ! -z "$lport" ]; then
        ovs-vsctl set Interface $port external_ids:iface-id=$lport
    fi

    pscount=$(ovn-nbctl lsp-get-port-security $lport | wc -l)
    if [ $pscount = 2 ]; then
        mac=$(ovn-nbctl lsp-get-port-security $lport | head -n 1)
        cidr=$(ovn-nbctl lsp-get-port-security $lport | tail -n 1)
        ip link set $port netns $port-ns
        # ip netns exec $port-ns ip link set dev $port name eth0
        ip netns exec $port-ns ip link set $port address $mac
        ip netns exec $port-ns ip addr add $cidr dev $port
        ip netns exec $port-ns ip link set $port up
        if [ ! -z "$gateway" ]; then
            ip netns exec $port-ns ip route add default via $gateway
        fi
    fi
}

ovs-add-port-dhcp() {
    bridge=$1
    port=$2
    lport=$3

    # Create ports on the local OVS bridge and associates it with OVN logical
    # ports. ovn-controller will then set up the flows necessary for these ports
    # to be able to communicate each other as defined by logical ports.
    ip netns add $port-ns
    ovs-vsctl --may-exist add-port $bridge $port -- set interface $port type=internal
    if [ ! -z "$lport" ]; then
        ovs-vsctl set Interface $port external_ids:iface-id=$lport
    fi

    mac=$(ovn-nbctl lsp-get-port-security $lport | head -n 1)
    ip link set $port netns $port-ns
    # ip netns exec $port-ns ip link set dev $port name eth0
    ip netns exec $port-ns ip link set $port address $mac
    ip netns exec $port-ns ip link set $port up
    ip netns exec $port-ns dhclient $port
}
