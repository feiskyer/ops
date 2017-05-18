#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

OVN_ROOT=$(dirname "${BASH_SOURCE}")
source ${OVN_ROOT}/lib/ovn.sh


cleanup() {
    ovs-vsctl --if-exists del-port br-int lport1
    ovs-vsctl --if-exists del-port br-int lport2
    ovn-nbctl acl-del sw0
    ovn-nbctl acl-del sw1
    ovn-nbctl --if-exists destroy Address_Set sw0
    ovn-nbctl --if-exists ls-del sw0
    ovn-nbctl --if-exists ls-del sw1
    ip netns del lport1-ns
    ip netns del lport2-ns
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

# Add a logical router
ovn-nbctl lr-add lr0

# Add a gateway port for sw0.
ovn-nbctl lrp-add lr0 sw0gw 00:00:00:01:00:01 192.168.33.1/24
ovn-nbctl -- lsp-add sw0 sw0gw-attachment \
               -- set Logical_Switch_Port sw0gw-attachment \
                  type=router \
                  options:router-port=sw0gw \
                  addresses='"00:00:00:01:00:01 192.168.33.1"'

# Add a default route.
ovn-nbctl lr-route-add lr0 "0.0.0.0/0" 192.168.33.1

# TODO: FIXME fix external network.
# create snat-dnat rule for vm1 & apply to lr0.
ovn-nbctl -- --id=@nat create nat type="dnat_and_snat" logical_ip=172.16.255.130 \
          external_ip=192.168.33.30 -- add logical_router lr0 nat @nat

# create snat-dnat rule for vm2 & apply to lr0.
ovn-nbctl -- --id=@nat create nat type="dnat_and_snat" logical_ip=172.16.255.131 \
          external_ip=192.168.33.40 -- add logical_router lr0 nat @nat

# default drop
ovn-nbctl acl-add sw0 to-lport 900 "outport == \"sw0-port1\" && ip" drop
ovn-nbctl acl-add sw0 to-lport 900 "outport == \"sw0-port2\" && ip" drop

# allow all ip trafficand allowing related connections back in
ovn-nbctl acl-add sw0 from-lport 1000 "inport == \"sw0-port1\" && ip" allow-related
ovn-nbctl acl-add sw0 from-lport 1000 "inport == \"sw0-port2\" && ip" allow-related

# allow tcp 443 in and related connections back out
ovn-nbctl acl-add sw0 to-lport 1000 "outport == \"sw0-port1\" && tcp.dst == 443" allow-related
ovn-nbctl acl-add sw0 to-lport 1000 "outport == \"sw0-port2\" && tcp.dst == 443" allow-related

# create an address set for the sw0 servers. they fall within a common /31
ovn-nbctl create Address_Set name=sw0 addresses=\"172.16.255.130/31\"

# allow from sw0 on 3306
ovn-nbctl acl-add inside to-lport 1000 'outport == "inside-vm3" && ip4.src == $sw0 && tcp.dst == 3306' allow-related
ovn-nbctl acl-add inside to-lport 1000 'outport == "inside-vm4" && ip4.src == $sw0 && tcp.dst == 3306' allow-related

# default drop
ovn-nbctl acl-add inside to-lport 900 "outport == \"inside-vm3\" && ip" drop
ovn-nbctl acl-add inside to-lport 900 "outport == \"inside-vm4\" && ip" drop

# List acl rules on sw0.
ovn-nbctl acl-list sw0

# Now that we have ACLs configured.
ovn-sbctl lflow-list

echo "do cleanup"
cleanup