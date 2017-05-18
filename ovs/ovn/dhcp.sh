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
    ovn-nbctl --if-exists ls-del sw1
    ovn-nbctl --if-exists lr-del lr0
    ovn-nbctl dhcp-options-list | xargs -I % ovn-nbctl dhcp-options-del %

    ip netns del lport1-ns
    ip netns del lport2-ns
}

echo "create a logical switch which has two logical ports:"
ls-create sw0
ls-add-port sw0 sw0-port1 00:00:00:00:00:01
ls-create sw1
ls-add-port sw1 sw1-port1 00:00:00:00:10:01

# Add a logical router
ovn-nbctl lr-add lr0

# Add a gateway port for sw0.
ovn-nbctl lrp-add lr0 sw0gw 00:00:00:01:00:01 192.168.33.1/24
ovn-nbctl -- lsp-add sw0 sw0gw-attachment \
               -- set Logical_Switch_Port sw0gw-attachment \
                  type=router \
                  options:router-port=sw0gw \
                  addresses='"00:00:00:01:00:01 192.168.33.1"'

# Add a gateway port for sw1.
ovn-nbctl lrp-add lr0 sw1gw 00:00:00:01:00:02 192.168.34.1/24
ovn-nbctl -- lsp-add sw1 sw1gw-attachment \
               -- set Logical_Switch_Port sw1gw-attachment \
                  type=router \
                  options:router-port=sw1gw \
                  addresses='"00:00:00:01:00:02 192.168.34.1"'

# Setup dhcp options for each logical ports.
sw0DHCP="$(ovn-nbctl create DHCP_Options cidr=192.168.33.10/24 \
options="\"server_id\"=\"192.168.33.10\" \"server_mac\"=\"00:00:00:00:00:01\" \
\"lease_time\"=\"3600\" \"router\"=\"192.168.33.1\"")" 
sw1DHCP="$(ovn-nbctl create DHCP_Options cidr=192.168.34.10/24 \
options="\"server_id\"=\"192.168.34.10\" \"server_mac\"=\"00:00:00:00:10:01\" \
\"lease_time\"=\"3600\" \"router\"=\"192.168.34.1\"")"
ovn-nbctl dhcp-options-list

ovn-nbctl lsp-set-dhcpv4-options sw0-port1 $sw0DHCP
ovn-nbctl lsp-get-dhcpv4-options sw0-port1

ovn-nbctl lsp-set-dhcpv4-options sw1-port1 $sw1DHCP
ovn-nbctl lsp-get-dhcpv4-options sw1-port1

echo "add ovs ports and associates them to OVN logical ports:"
# TODO: FIXME dhclient blocked and can't get IP.
ovs-add-port-dhcp br-int lport1 sw0-port1
ovs-add-port-dhcp br-int lport2 sw1-port1

echo "do cleanup"
cleanup