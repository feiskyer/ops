#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

OVN_ROOT=$(dirname "${BASH_SOURCE}")
source ${OVN_ROOT}/lib/ovn.sh

cleanup() {
    ovn-sbctl --if-exists chassis-del fakechassis
    ovs-vsctl --if-exists del-port br-int lport1
    ovs-vsctl --if-exists del-port br-int lport2
    ovs-vsctl --if-exists del-port br-int lport3
    ovs-vsctl --if-exists del-port br-int lport4
    ovn-nbctl --if-exists ls-del sw0
    ip netns del lport1-ns
    ip netns del lport2-ns
}


echo "create a logical switch which has four logical ports:"
ls-create sw0
ls-add-port sw0 sw0-port1 00:00:00:00:00:01 192.168.33.10/24
ls-add-port sw0 sw0-port2 00:00:00:00:00:02 192.168.33.20/24
ls-add-port sw0 sw0-port3 00:00:00:00:00:03 192.168.33.30/24
ls-add-port sw0 sw0-port4 00:00:00:00:00:04 192.168.33.40/24

echo "overview of the logical topology:"
ovn-nbctl show

echo "add ovs ports and associates them to OVN logical ports:"
ovs-add-port br-int lport1 sw0-port1
ovs-add-port br-int lport2 sw0-port2

# Create a fake remote chassis.
ovn-sbctl chassis-add fakechassis vxlan 127.0.0.1

# Bind sw0-port3 and sw0-port4 to the fake remote chassis.
ovn-sbctl lsp-bind sw0-port3 fakechassis
ovn-sbctl lsp-bind sw0-port4 fakechassis

# Show southbound ports states
ovn-sbctl show

# Packets to remote host shoud be sent via kernel tunnel
ofport=$(ovs-vsctl list interface lport1 | awk '/ofport /{print $3}')
ovs-appctl ofproto/trace br-int in_port=$ofport,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:03 -generate

# This trace simulates a packet arriving over a Geneve tunnel from a remote OVN
# chassis.  The fields are as follows:
#
# tun_id -
#    The logical datapath (or logical switch) ID.  In this case, we only
#    have a single logical switch and its ID is 1.
#
# tun_metadata0 -
#     This field holds 2 pieces of metadata.  The low 16 bits hold the logical
#     destination port (1 in this case).  The upper 16 bits hold the logical
#     source port (3 in this case.
#
ofport=$(ovs-vsctl list interface ovn-fakech-0 | awk '/ofport /{print $3}')
ovs-appctl ofproto/trace br-int in_port=$ofport,dl_src=00:00:00:00:00:03,dl_dst=00:00:00:00:00:01,tun_id=0xe,tun_metadata0=$[77 + $[$ofport << 16]] -generate

echo "do cleanup"
cleanup