# OVN Tutorial

- [Simple two-port setup](l2_basic.sh): demonstrates a logical switch which has two logical ports.
- [Simple two-vm setup](l2_basic_vm.sh): demonstrates a logical switch which has two logical ports connected with two vms.
- [Simple two-switch setup](l2_switch.sh): demonstrates two switches setup and each switch has two logical ports.
- [Simple (fake) chassis setup](l2_switch_fakechassis.sh): demonstrates a logical switch which has four logical ports, two on local ovs and two on the fake chassis.
- [Locally attached networks](l2_network.sh): demonstrates OVN as a control plane to manage logically direct connectivity to networks that are locally accessible to each chassis.
- [Locally attached networks with VLANs](l2_network_vlan.sh): demonstrates OVN as a control plane to manage logically direct connectivity to networks with VLAN 101 that are locally accessible to each chassis.
- [Stateful ACLs basics](acl_basic.sh): ACLs provide a way to do distributed packet filtering for OVN networks. ACLs are implemented using conntrack integration with OVS.
- [L3 router setup](l3_basic.sh): demonstrates a router connected with two switches.
- [ACLs advanced setup](acl_advanced.sh): demonstrates advanced acls, including nat and address sets.
