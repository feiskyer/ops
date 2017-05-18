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

    ip netns del lport1-ns
    ip netns del lport2-ns
}

echo "create a logical switch which has two logical ports:"
ls-create sw0
ls-add-port sw0 sw0-port1 00:00:00:00:00:01 192.168.33.10/24
ls-create sw1
ls-add-port sw1 sw1-port1 00:00:00:00:10:01 192.168.34.10/24

echo "add ovs ports and associates them to OVN logical ports:"
ovs-add-port br-int lport1 sw0-port1 192.168.33.1
ovs-add-port br-int lport2 sw1-port1 192.168.34.1

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

echo "do cleanup"
cleanup