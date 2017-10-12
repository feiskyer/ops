#!/bin/bash
local_ip=$(hostname -I | awk '{print $1}')
central_ip=${CENTRAL_IP:-$local_ip}
encap_type=${ENCAP_TYPE:-"vxlan"}

# systemctl restart openvswitch
# systemctl restart ovn-controller
# systemctl restart ovn-northd.service
# systemctl restart ovn-controller-vtep.service

# start ovsdb server
/usr/share/openvswitch/scripts/ovs-ctl start --system-id=random

if [ "$1" == "cs" ]; then
  # start ovn northd
  /usr/share/openvswitch/scripts/ovn-ctl start_northd
elif [ "$1" == "cns" ]; then
  # start ovn-controller and vtep
  /usr/share/openvswitch/scripts/ovn-ctl start_controller
  /usr/share/openvswitch/scripts/ovn-ctl start_controller_vtep
else
  # start both
  /usr/share/openvswitch/scripts/ovn-ctl start_northd
  /usr/share/openvswitch/scripts/ovn-ctl start_controller
  /usr/share/openvswitch/scripts/ovn-ctl start_controller_vtep
fi

# setup ovn
ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$central_ip:6642" external_ids:ovn-nb="tcp:$central_ip:6641" external_ids:ovn-encap-ip=$local_ip external_ids:ovn-encap-type="$encap_type"
ovn-nbctl set-connection ptcp:6641
ovn-sbctl set-connection ptcp:6642
