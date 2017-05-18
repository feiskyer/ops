#!/bin/bash

set -o xtrace

# This is an adptation of the NAT test in system-ovn.at
# ref: https://github.com/openvswitch/ovs/commit/cc08428b191517293a5f1d1ee19467c3fa290e9a

# Logical network:
# Two LRs - R1 and R2 that are connected to each other via LS "join"
# in 20.0.0.0/24 network. R1 has switchess foo (192.168.1.0/24) and
# bar (192.168.2.0/24) connected to it. R2 has alice (172.16.1.0/24) connected
# to it.  R2 is a gateway router on which we add NAT rules.
#
#    foo (compute1) -- R1 -- join -- R2 (compute2) -- alice (compute2)
#                      |
#    bar (compute1) ----

sudo ovn-nbctl create Logical_Router name=R1
sudo ovn-nbctl create Logical_Router name=R2 options:chassis=compute2

for n in foo bar alice join ; do
    sudo ovn-nbctl ls-add $n
done

# Connect foo to R1
sudo ovn-nbctl lrp-add R1 foo 00:00:01:01:02:03 192.168.1.1/24
sudo ovn-nbctl lsp-add foo rp-foo -- set Logical_Switch_Port rp-foo \
    type=router options:router-port=foo addresses=\"00:00:01:01:02:03\"

# Connect bar to R1
sudo ovn-nbctl lrp-add R1 bar 00:00:01:01:02:04 192.168.2.1/24
sudo ovn-nbctl lsp-add bar rp-bar -- set Logical_Switch_Port rp-bar \
    type=router options:router-port=bar addresses=\"00:00:01:01:02:04\"

# Connect alice to R2
sudo ovn-nbctl lrp-add R2 alice 00:00:02:01:02:03 172.16.1.1/24
sudo ovn-nbctl lsp-add alice rp-alice -- set Logical_Switch_Port rp-alice \
    type=router options:router-port=alice addresses=\"00:00:02:01:02:03\"

# Connect R1 to join
sudo ovn-nbctl lrp-add R1 R1_join 00:00:04:01:02:03 20.0.0.1/24
sudo ovn-nbctl lsp-add join r1-join -- set Logical_Switch_Port r1-join \
    type=router options:router-port=R1_join addresses='"00:00:04:01:02:03"'

# Connect R2 to join
sudo ovn-nbctl lrp-add R2 R2_join 00:00:04:01:02:04 20.0.0.2/24
sudo ovn-nbctl lsp-add join r2-join -- set Logical_Switch_Port r2-join \
    type=router options:router-port=R2_join addresses='"00:00:04:01:02:04"'

# Static routes.
sudo ovn-nbctl lr-route-add R1 172.16.1.0/24 20.0.0.2
sudo ovn-nbctl lr-route-add R2 192.168.0.0/16 20.0.0.1

# Logical port 'foo1' in compute1, switch 'foo'.
/vagrant/scripts/create-ns-port.sh compute1 foo1 f0:00:00:01:02:03 192.168.1.2/24 192.168.1.1
sudo ovn-nbctl lsp-add foo foo1 \
   -- lsp-set-addresses foo1 "f0:00:00:01:02:03 192.168.1.2"

# Logical port 'alice1' in compute2 switch 'alice'.
/vagrant/scripts/create-ns-port.sh compute2 alice1 f0:00:00:01:02:04 172.16.1.2/24 172.16.1.1
sudo ovn-nbctl lsp-add alice alice1 \
   -- lsp-set-addresses alice1 "f0:00:00:01:02:04 172.16.1.2"

# Logical port 'bar1' in compute1 switch 'bar'.
/vagrant/scripts/create-ns-port.sh compute1 bar1 f0:00:00:01:02:05 192.168.2.2/24 192.168.2.1
sudo ovn-nbctl lsp-add bar bar1 \
   -- lsp-set-addresses bar1 "f0:00:00:01:02:05 192.168.2.2"

# Add a DNAT rule.
sudo ovn-nbctl -- --id=@nat create nat type="dnat" logical_ip=192.168.1.2 \
    external_ip=30.0.0.2 -- add logical_router R2 nat @nat

# Add a SNAT rule
sudo ovn-nbctl -- --id=@nat create nat type="snat" logical_ip=192.168.2.2 \
    external_ip=30.0.0.1 -- add logical_router R2 nat @nat
