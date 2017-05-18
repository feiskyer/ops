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

echo "create a logical switch which has two logical ports:"
ls-create sw0
ls-add-port sw0 sw0-port1 00:00:00:00:00:01 192.168.33.10/24
ls-add-port sw0 sw0-port2 00:00:00:00:00:02 192.168.33.20/24

echo "overview of the logical topology:"
ovn-nbctl show

echo "add ovs ports and associates them to OVN logical ports:"
ovs-add-port br-int lport1 sw0-port1
ovs-add-port br-int lport2 sw0-port2

# A common use case would be the following policy applied for `sw0-port1`:
#
# * Allow outbound IP traffic and associated return traffic.
# * Allow incoming ICMP requests and associated return traffic.
# * Allow incoming SSH connections and associated return traffic.
# * Drop other incoming IP traffic.
#
ovn-nbctl acl-add sw0 from-lport 1002 "inport == \"sw0-port1\" && ip" allow-related
ovn-nbctl acl-add sw0 to-lport 1002 "outport == \"sw0-port1\" && ip && icmp" allow-related
ovn-nbctl acl-add sw0 to-lport 1002 "outport == \"sw0-port1\" && ip && tcp && tcp.dst == 22" allow-related
ovn-nbctl acl-add sw0 to-lport 1001 "outport == \"sw0-port1\" && ip" drop

# List acl rules on sw0.
ovn-nbctl acl-list sw0

# ICMP to port1 is allowed now.
ip netns exec lport2-ns ping -c3 192.168.33.10

# Let's add another rule dropping icmp to port1.
ovn-nbctl acl-add sw0 to-lport 1003 "outport == \"sw0-port1\" && ip && icmp" drop
# ICMP to port1 is dropped now.
ip netns exec lport2-ns ping -c3 192.168.33.10

# Now that we have ACLs configured, there are new entries in the logical flow
# table in the stages `switch_in_pre_acl`, `switch_in_acl`, `switch_out_pre_acl`,
# and `switch_out_acl`.
# 
# * In `switch_out_pre_acl`, we match IP traffic and put it through the connection
#   tracker.  This populates the connection state fields so that we can apply policy
#   as appropriate.
# * In `switch_out_acl`, we allow packets associated with existing connections.  We
#   drop packets that are deemed to be invalid (such as non-SYN TCP packet not
#   associated with an existing connection).
# * For new connections, we apply our configured ACL policy to decide whether to
#   allow the connection or not.  In this case, we’ll allow ICMP or SSH.  Otherwise,
#   we’ll drop the packet.
# * When using ACLs, the default policy is to allow and track IP connections.  Based
#   on our above policy, IP traffic directed at `sw0-port1` will never hit this flow
#   at priority 1.
# * Note that conntrack integration is not yet supported in ovs-sandbox, so the
#   OpenFlow flows will not represent what you’d see in a real environment.  The
#   logical flows described above give a very good idea of what the flows look like,
#   though.
#
ovn-sbctl lflow-list

echo "do cleanup"
cleanup