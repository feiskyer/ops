#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

OVN_ROOT=$(dirname "${BASH_SOURCE}")
source ${OVN_ROOT}/lib/ovn.sh

cleanup() {
    ovs-vsctl --if-exists del-port br-int lport1
    ovs-vsctl --if-exists del-port br-int lport2
    ovs-vsctl --if-exists del-port br-int lport5
    ovs-vsctl --if-exists del-port br-int lport6
    for n in 1 2 3 4 5 6 7 8; do
        if [ $n -gt 4 ] ; then
            ls_name="provnet1-$n-101"
            lsp_name="$ls_name-port1"
        else
            ls_name="provnet1-$n"
        fi
        ovn-nbctl --if-exists ls-del $ls_name
    done
    ovn-sbctl --if-exists chassis-del fakechassis
    ip netns del lport1-ns
    ip netns del lport2-ns
}


# While OVN is generally focused on the implementation of logical networks using
# overlays, it’s also possible to use OVN as a control plane to manage logically
# direct connectivity to networks that are locally accessible to each chassis.
#
# Instead of having the new ports directly
# connected to `physnet1` as before, we indicate that we want them on VLAN 101 of
# `physnet1`.  This shows how `localnet` ports can be used to provide connectivity
# to either a flat network or a VLAN on that network.
#
# This scenario requires some additional configuration of `ovn-controller`.  We
# must configure a mapping between `physnet1` and a local OVS bridge that provides
# connectivity to that network.  We call these “bridge mappings”.
ovs-vsctl add-br br-eth1
ovs-vsctl set open .  external-ids:ovn-bridge-mappings=physnet1:br-eth1

ovn-sbctl chassis-add fakechassis vxlan 127.0.0.1

for n in 1 2 3 4 5 6 7 8; do
    if [ $n -gt 4 ] ; then
        ls_name="provnet1-$n-101"
        lsp_name="$ls_name-port1"
    else
        ls_name="provnet1-$n"
    fi
    ovn-nbctl ls-add $ls_name

    lsp_name="$ls_name-port1"
    ovn-nbctl lsp-add $ls_name $lsp_name
    ovn-nbctl lsp-set-addresses $lsp_name 00:00:00:00:00:0$n
    ovn-nbctl lsp-set-port-security $lsp_name 00:00:00:00:00:0$n

    if [ $n -gt 4 ] ; then
        lsp_name="provnet1-$n-physnet1-101"
        ovn-nbctl lsp-add $ls_name $lsp_name "" 101
    else
        lsp_name="provnet1-$n-physnet1"
        ovn-nbctl lsp-add $ls_name $lsp_name
    fi
    ovn-nbctl lsp-set-addresses $lsp_name unknown
    ovn-nbctl lsp-set-type $lsp_name localnet
    ovn-nbctl lsp-set-options $lsp_name network_name=physnet1
done

# Add ovs ports.
ovs-vsctl add-port br-int lport1 -- set Interface lport1 external_ids:iface-id=provnet1-1-port1
ovs-vsctl add-port br-int lport2 -- set Interface lport2 external_ids:iface-id=provnet1-2-port1
ovs-vsctl add-port br-int lport5 -- set Interface lport5 external_ids:iface-id=provnet1-5-101-port1
ovs-vsctl add-port br-int lport6 -- set Interface lport6 external_ids:iface-id=provnet1-6-101-port1

# Bind to fakechassis.
ovn-sbctl lsp-bind provnet1-3-port1 fakechassis
ovn-sbctl lsp-bind provnet1-4-port1 fakechassis
ovn-sbctl lsp-bind provnet1-7-101-port1 fakechassis
ovn-sbctl lsp-bind provnet1-8-101-port1 fakechassis


# input from local vif, lport5 (ofport 6)
# destination MAC is lport6
# expect to go out via localnet port (ofport 7) and lport6 (ofport 8)
ovs-appctl ofproto/trace br-int in_port=6,dl_src=00:00:00:00:00:05,dl_dst=00:00:00:00:00:06 -generate

# We use the LOCAL port of br-eth1 to simulate the port connected to network.
# expect to arrive on lport5 (ofport 6) and lport6 (ofport 8)
ovs-appctl ofproto/trace br-eth1 in_port=LOCAL,dl_src=00:00:00:00:00:07,dl_dst=ff:ff:ff:ff:ff:ff,dl_vlan=101 -generate

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

