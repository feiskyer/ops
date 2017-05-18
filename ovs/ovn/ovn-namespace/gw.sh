#!/bin/bash

## Create the new logical router. Be sure to substitute {chassis_id} with a valid UUID
## get by command "ovn-sbctl show".

# create router edge1
ovn-nbctl create Logical_Router name=edge1 options:chassis={chassis_uuid}

# create a new logical switch for connecting the edge1 and tenant1 routers
ovn-nbctl ls-add transit

# edge1 to the transit switch
ovn-nbctl lrp-add edge1 edge1-transit 02:ac:10:ff:00:01 172.16.255.1/30
ovn-nbctl lsp-add transit transit-edge1
ovn-nbctl lsp-set-type transit-edge1 router
ovn-nbctl lsp-set-addresses transit-edge1 02:ac:10:ff:00:01
ovn-nbctl lsp-set-options transit-edge1 router-port=edge1-transit

# tenant1 to the transit switch
ovn-nbctl lrp-add tenant1 tenant1-transit 02:ac:10:ff:00:02 172.16.255.2/30
ovn-nbctl lsp-add transit transit-tenant1
ovn-nbctl lsp-set-type transit-tenant1 router
ovn-nbctl lsp-set-addresses transit-tenant1 02:ac:10:ff:00:02
ovn-nbctl lsp-set-options transit-tenant1 router-port=tenant1-transit

# add static routes
ovn-nbctl lr-route-add edge1 "172.16.255.128/25" 172.16.255.2
ovn-nbctl lr-route-add tenant1 "0.0.0.0/0" 172.16.255.1

ovn-sbctl show

## We’re going to use the eth1 interface of ubuntu1 as our connection point
## between the edge1 router and the “data” network. In order to accomplish
## this we’ll need to set up OVN to used the eth1 interface directly through
## a dedicated OVS bridge. This type of connection is known as a “localnet”
## in OVN.

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
ip addr add 10.127.0.130/24 dev br-eth1
ip link set br-eth1 up

# create bridge mapping for eth1. map network name "dataNet" to br-eth1
ovs-vsctl set Open_vSwitch . external-ids:ovn-bridge-mappings=dataNet:br-eth1

# create localnet port on 'outside'. set the network name to "dataNet"
ovn-nbctl lsp-add outside outside-localnet
ovn-nbctl lsp-set-addresses outside-localnet unknown
ovn-nbctl lsp-set-type outside-localnet localnet
ovn-nbctl lsp-set-options outside-localnet network_name=dataNet

# connect eth1 to br-eth1
ovs-vsctl add-port br-eth1 eth1

## With OVN there are 3 types of NAT which may be configured:
# 
# DNAT – used to translate requests to an externally visible IP to an internal IP
# SNAT – used to translate requests from one or more internal IPs to an externally visible IP
# SNAT-DNAT – used to create a “static NAT” where an external IP is mapped to an internal IP, and vice versa
# create snat rule which will nat to the edge1-outside interface
ovn-nbctl -- --id=@nat create nat type="snat" logical_ip=172.16.255.128/25 \
external_ip=10.127.0.129 -- add logical_router edge1 nat @nat
