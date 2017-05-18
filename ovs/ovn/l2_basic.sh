#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

OVN_ROOT=$(dirname "${BASH_SOURCE}")
source ${OVN_ROOT}/lib/ovn.sh

add-unknown-ports() {
    ovn-nbctl lsp-add sw0 sw0-port4
    ovn-nbctl lsp-add sw0 sw0-port5
    ovn-nbctl lsp-set-addresses sw0-port4 unknown
    ovn-nbctl lsp-set-addresses sw0-port5 unknown
    ovn-nbctl lsp-set-port-security sw0-port4 00:00:00:00:00:04 00:00:00:00:00:05
    ovn-nbctl lsp-set-port-security sw0-port5 00:00:00:00:00:04 00:00:00:00:00:05
    ovs-vsctl --may-exist add-port br-int lport4 -- set interface lport4 type=internal -- set Interface lport4 external_ids:iface-id=sw0-port4
    ovs-vsctl --may-exist add-port br-int lport5 -- set interface lport5 type=internal -- set Interface lport5 external_ids:iface-id=sw0-port5
}

add-ports-with-ip() {
    ovn-nbctl lsp-add sw0 sw0-port6
    ovn-nbctl lsp-add sw0 sw0-port7
    ovn-nbctl lsp-set-addresses sw0-port6 "00:00:00:00:00:06"
    ovn-nbctl lsp-set-addresses sw0-port7 "00:00:00:00:00:07"
    ovn-nbctl lsp-set-port-security sw0-port6 00:00:00:00:00:06 192.168.1.10/24
    ovn-nbctl lsp-set-port-security sw0-port7 00:00:00:00:00:07 192.168.1.20/24
    ovs-vsctl add-port br-int lport6 -- set Interface lport6 external_ids:iface-id=sw0-port6
    ovs-vsctl add-port br-int lport7 -- set Interface lport7 external_ids:iface-id=sw0-port7

    # Trace a packet from sw0-port6 to sw0-port7.
    ovs-appctl ofproto/trace br-int in_port=6,dl_type=0x0800,dl_src=00:00:00:00:00:06,dl_dst=00:00:00:00:00:07,nw_src=192.168.1.10,nw_dst=192.168.1.20  -generate
}

cleanup() {
    ovs-vsctl --if-exists del-port br-int lport1
    ovs-vsctl --if-exists del-port br-int lport2
    ovs-vsctl --if-exists del-port br-int lport3
    ovs-vsctl --if-exists del-port br-int lport4
    ovs-vsctl --if-exists del-port br-int lport5
    ovs-vsctl --if-exists del-port br-int lport6
    ovs-vsctl --if-exists del-port br-int lport7

    ovs-nbctl --if-exists ls-del sw0
}

echo "create a logical switch which has two logical ports:"
ls-create sw0
ls-add-port sw0 sw0-port1 00:00:00:00:00:01
ls-add-port sw0 sw0-port2 00:00:00:00:00:02

echo "overview of the logical topology:"
ovn-nbctl show

echo "add ovs ports and associates them to OVN logical ports:"
ovs-add-port br-int lport1 sw0-port1
ovs-add-port br-int lport2 sw0-port2

echo "show southbound ports states:"
ovn-sbctl show

echo "show logical flows created by OVN"
ovn-sbctl lflow-list

echo "show OpenFlow port numbers for each logical ports:"
ovs-ofctl show br-int

echo "show OpenFlow flows for bridge br-int:"
ovs-ofctl -O OpenFlow13 dump-flows br-int

echo "Trace a packet from sw0-port1 to sw0-port2. The packet arrives from port 1 and should be output to port 2."
ovs-appctl ofproto/trace br-int in_port=1,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:02 -generate

echo "Trace a broadcast packet from sw0-port1.  The packet arrives from port 1 and should be output to port 2."
ovs-appctl ofproto/trace br-int in_port=1,dl_src=00:00:00:00:00:01,dl_dst=ff:ff:ff:ff:ff:ff -generate

echo "Add another port"
ls-add-port sw0 sw0-port3 00:00:00:00:00:02
ovs-add-port br-int lport3 sw0-port3
echo "Trace broadcast now, it should be ouput on both port 2 and 3."
ovs-appctl ofproto/trace br-int in_port=1,dl_src=00:00:00:00:00:01,dl_dst=ff:ff:ff:ff:ff:ff -generate

echo "Trace a packet from sw0-port1 to an unknown mac and should be dropped"
ovs-appctl ofproto/trace br-int in_port=1,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:00:34 -generate

echo "do cleanup"
cleanup