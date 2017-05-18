#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

OVN_ROOT=$(dirname "${BASH_SOURCE}")
source ${OVN_ROOT}/lib/ovn.sh

cleanup() {
    ovs-vsctl --if-exists del-port br-int lport1
    ovs-vsctl --if-exists del-port br-int lport2
    ovn-nbctl --if-exists ls-del provnet1-1
    ovn-nbctl --if-exists ls-del provnet1-2
    ovn-nbctl --if-exists ls-del provnet1-3
    ovn-nbctl --if-exists ls-del provnet1-4
    ovn-sbctl --if-exists chassis-del fakechassis
    ip netns del lport1-ns
    ip netns del lport2-ns
}


# While OVN is generally focused on the implementation of logical networks using
# overlays, it’s also possible to use OVN as a control plane to manage logically
# direct connectivity to networks that are locally accessible to each chassis.
#
# This example includes two hypervisors.  Both hypervisors have two ports on them.
# We want to use OVN to manage the connectivity of these ports to a network
# attached to each hypervisor that we will call “physnet1”.
#
# This scenario requires some additional configuration of `ovn-controller`.  We
# must configure a mapping between `physnet1` and a local OVS bridge that provides
# connectivity to that network.  We call these “bridge mappings”.
ovs-vsctl add-br br-eth1
ovs-vsctl set open .  external-ids:ovn-bridge-mappings=physnet1:br-eth1

ovn-sbctl chassis-add fakechassis vxlan 127.0.0.1

for n in 1 2 3 4; do
    ovn-nbctl ls-add provnet1-$n

    ovn-nbctl lsp-add provnet1-$n provnet1-$n-port1
    ovn-nbctl lsp-set-addresses provnet1-$n-port1 00:00:00:00:00:0$n
    ovn-nbctl lsp-set-port-security provnet1-$n-port1 00:00:00:00:00:0$n

    ovn-nbctl lsp-add provnet1-$n provnet1-$n-physnet1
    ovn-nbctl lsp-set-addresses provnet1-$n-physnet1 unknown
    # local port for connecting to physnet1.
    ovn-nbctl lsp-set-type provnet1-$n-physnet1 localnet
    ovn-nbctl lsp-set-options provnet1-$n-physnet1 network_name=physnet1
done

ovn-nbctl show

# Add ovs ports.
ovs-vsctl add-port br-int lport1 -- set interface lport1 type=internal -- set Interface lport1 external_ids:iface-id=provnet1-1-port1
ovs-vsctl add-port br-int lport2 -- set interface lport2 type=internal -- set Interface lport2 external_ids:iface-id=provnet1-2-port1

# Bind to fakechassis.
ovn-sbctl lsp-bind provnet1-3-port1 fakechassis
ovn-sbctl lsp-bind provnet1-4-port1 fakechassis

# This first trace shows a packet from `provnet1-1-port1` with a destination MAC
# address of `provnet1-2-port1`.  Despite both of these ports being on the same
# local switch (`lport1` and `lport2`), we expect all packets to be sent out to
# `br-eth1` (OpenFlow port 1).  We then expect the network to handle getting the
# packet to its destination.  In practice, this will be optimized at `br-eth1` and
# the packet won’t actually go out and back on the network.
ofport=$(ovs-vsctl list interface lport1 | awk '/ofport /{print $3}')
ovs-appctl ofproto/trace br-int in_port=$ofport,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:02 -generate

# This next trace is a continuation of the previous one.  This shows the packet
# coming back into `br-int` from `br-eth1`.  We now expect the packet to be output
# to `provnet1-2-port1`, which is OpenFlow port 4.
ofport=$(ovs-vsctl list interface patch-provnet1-1-physnet1-to-br-int | awk '/ofport /{print $3}')
ovs-appctl ofproto/trace br-int in_port=$ofport,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:03 -generate

# This next trace shows an example of a packet being sent to a destination on
# another hypervisor.  The source is `provnet1-2-port1`, but the destination is
# `provnet1-3-port1`, which is on the other fake chassis.  As usual, we expect the
# output to be to OpenFlow port 1, the patch port to `br-et1`.
ovs-appctl ofproto/trace br-int in_port=2,dl_src=00:00:00:00:00:01,dl_dst=ff:ff:ff:ff:ff:ff -generate

# This next test shows a broadcast packet.  The destination should still only be
# OpenFlow port 1.
# We use the LOCAL port of br-eth1 to simulate the port connected to network.
# expect to arrive on lport1 (ofport 2) and lport2 (ofport 4)
ovs-appctl ofproto/trace br-eth1 in_port=LOCAL,dl_src=00:00:00:00:00:03,dl_dst=ff:ff:ff:ff:ff:ff -generate

