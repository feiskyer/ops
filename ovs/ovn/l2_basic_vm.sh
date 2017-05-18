#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

OVN_ROOT=$(dirname "${BASH_SOURCE}")
source ${OVN_ROOT}/lib/ovn.sh

cleanup() {
    ovs-vsctl --if-exists del-port br-int lport1
    ovs-vsctl --if-exists del-port br-int lport2
    ovn-nbctl --if-exists ls-del sw0
    ip netns del lport1-ns
    ip netns del lport2-ns
}

packet-out() {
    # import binascii
    # from scapy.all import *
    # a=Ether(dst="00:00:00:00:00:02",src="00:00:00:00:00:01")/IP(dst="192.168.33.20",src="192.168.33.10", ttl=10)/ICMP()
    # print binascii.hexlify(str(a))
    ofport=$(ovs-vsctl list interface lport1 | awk '/ofport /{print $3}')
    ovs-ofctl packet-out br-int $ofport "normal" 00000000000200000000000108004500001c000100000a01ed71c0a8210ac0a821140800f7ff00000000
}

echo "create a logical switch which has two logical ports:"
ls-create sw0
ls-add-port sw0 sw0-port1 00:00:00:00:00:01 192.168.33.10/24
ls-add-port sw0 sw0-port2 00:00:00:00:00:02 192.168.33.20/24

echo "overview of the logical topology:"
ovn-nbctl show

echo "add ovs ports and associates them to OVN logical ports:"
ovs-add-port br-int lport1 sw0-port1
ovs-add-port br-int lport2 sw0-port2

echo "show southbound ports states:"
ovn-sbctl show
ip netns exec lport1-ns ip addr
ip netns exec lport2-ns ip addr

echo "check connectivity of two vms"
ip netns exec lport1-ns ping -c3 192.168.33.20

echo "packet out, show get the icmp request in lport2-ns"
packet-out

echo "do cleanup"
cleanup