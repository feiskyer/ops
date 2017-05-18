#!/bin/bash
#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

# With OVN there are 3 types of NAT which may be configured:

#   DNAT – used to translate requests to an externally visible IP to an internal
#          IP
#   SNAT – used to translate requests from one or more internal IPs to an
#          externally visible IP
#   SNAT-DNAT – used to create a “static NAT” where an external IP is mapped to
#          an internal IP, and vice versa
#
# Since we don’t need (or want) the public network to be able to directly access
# our internal VMs, lets focus on allowing outbound SNAT from our VMs. In order
# to create NAT rules we’ll need to manipulate the OVN northbound database
# directly.

# create snat rule which will nat to the edge1-outside interface
# this command is creating an entry in the “nat” table of the northbound
# database, storing the resulting UUID within the ovsdb variable “@nat”,
# and then adding the UUID stored in @nat to the “nat” field of the “edge1”
# entry in the “logical_router” table of the northbound database.

ovn-nbctl -- --id=@nat create nat type="snat" logical_ip=172.16.255.128/25 \
          external_ip=10.10.0.100 -- add logical_router edge1 nat @nat

# add a default route to edge1 router
# the default gateway will connect edge1 to its nexhop outside the OVN
# topology. In the diag at the datanet, that would be 10.127.0.128 instead
# of 10.10.0.1
ovn-nbctl lr-route-add edge1 "0.0.0.0/0" 10.10.0.1


# Testing connectivity from vm1:
ip netns exec vm1 ping 10.127.0.130 -c3
