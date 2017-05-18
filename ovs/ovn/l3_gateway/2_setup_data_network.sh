#!/bin/bash
#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

# We’re going to use the eth1 interface of ubuntu1 as our connection point between
# the edge1 router and the “data” network. In order to accomplish this we’ll need
# to set up OVN to used the eth1 interface directly through a dedicated OVS bridge.
# This type of connection is known as a “localnet” in OVN.

# create new port on router 'edge1'
ovn-nbctl lrp-add edge1 edge1-outside 02:0a:7f:00:01:29 10.127.0.129/25

# create new logical switch and connect it to edge1
ovn-nbctl ls-add outside
ovn-nbctl lsp-add outside outside-edge1
ovn-nbctl lsp-set-type outside-edge1 router
ovn-nbctl lsp-set-addresses outside-edge1 02:0a:7f:00:01:29
ovn-nbctl lsp-set-options outside-edge1 router-port=edge1-outside

# create a bridge for eth1
ovs-vsctl add-br br-eth1

# create bridge mapping for eth1. map network name "dataNet" to br-eth1
ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=dataNet:br-eth1

# create localnet port on 'outside'. set the network name to "dataNet"
ovn-nbctl lsp-add outside outside-localnet
ovn-nbctl lsp-set-addresses outside-localnet unknown
ovn-nbctl lsp-set-type outside-localnet localnet
ovn-nbctl lsp-set-options outside-localnet network_name=dataNet

# connect eth1 to br-eth1
ovs-vsctl add-port br-eth1 eth1

# Giving the Ubuntu Hosts Access to the “data” Network
# On host1
ip addr add 10.127.0.130/24 dev br-eth1
ip link set br-eth1 up
# On other Hosts
ip addr add 10.127.0.131/24 dev eth1
ip link set eth1 up