#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

OVN_ROOT=$(dirname "${BASH_SOURCE}")
source ${OVN_ROOT}/lib/ovn.sh

cleanup() {
    ovs-vsctl --if-exists del-port br-int lport1
    ovs-vsctl --if-exists del-port br-int lport2
    ovs-vsctl --if-exists del-port br-int lport3
    ovs-vsctl --if-exists del-port br-int lport4
    ovn-nbctl --if-exists ls-del sw0
    ovn-nbctl --if-exists ls-del sw1
    ip netns del lport1-ns
    ip netns del lport2-ns
    ip netns del lport3-ns
    ip netns del lport4-ns
}

packet-out() {
    # import binascii
    # from scapy.all import *
    # a=Ether(dst="00:00:00:00:00:02",src="00:00:00:00:00:01")/IP(dst="192.168.33.20",src="192.168.33.10", ttl=10)/ICMP()
    # print binascii.hexlify(str(a))
    ofport=$(ovs-vsctl list interface lport1 | awk '/ofport /{print $3}')
    ovs-ofctl packet-out br-int $ofport "normal" 00000000000200000000000108004500001c000100000a01ed71c0a8210ac0a821140800f7ff00000000
}

echo "create first logical switch which has two logical ports:"
ls-create sw0
ls-add-port sw0 sw0-port1 00:00:00:00:00:01 192.168.33.10/24
ls-add-port sw0 sw0-port2 00:00:00:00:00:02 192.168.33.20/24

echo "create second logical switch which has also two logical ports:"
ls-create sw1
ls-add-port sw1 sw1-port1 00:00:00:00:00:03 192.168.33.30/24
ls-add-port sw1 sw1-port2 00:00:00:00:00:04 192.168.33.40/24

echo "add ovs ports and associates them to OVN logical ports:"
ovs-add-port br-int lport1 sw0-port1
ovs-add-port br-int lport2 sw0-port2
ovs-add-port br-int lport3 sw1-port1
ovs-add-port br-int lport4 sw1-port2

echo "show southbound ports states:"
ip netns exec lport1-ns ip addr
ip netns exec lport2-ns ip addr
ip netns exec lport3-ns ip addr
ip netns exec lport4-ns ip addr

echo "check connectivity of two vms on same switch, which should be connected"
ip netns exec lport1-ns ping -c3 192.168.33.20
ofport=$(ovs-vsctl list interface lport1 | awk '/ofport /{print $3}')
ovs-appctl ofproto/trace br-int in_port=$ofport,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:02 -generate

echo "check connectivity of two vms on different swith, which should be non-reachable"
ip netns exec lport1-ns ping -c3 192.168.33.30
ovs-appctl ofproto/trace br-int in_port=$ofport,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:03 -generate

echo "packet out, show get the icmp request in lport2-ns"
packet-out

echo "do cleanup"
cleanup