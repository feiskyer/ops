#!/bin/bash
#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-gateway-router.html
#

# create router edge1
# the gatway router will be bound to a specific chassis (get by ovn-sbctl show)
ovn-nbctl create Logical_Router name=edge1 options:chassis=0e298c83-a63d-4ea9-adae-1b97eb7c4ab4

# create router tenant1
ovn-nbctl lr-add tenant1

# create a new logical switch for connecting the edge1 and tenant1 routers
ovn-nbctl ls-add transit

# edge1 to the transit switch
ovn-nbctl lrp-add edge1 edge1-transit 02:ac:10:ff:00:01 172.16.255.1/30
ovn-nbctl lsp-add transit transit-edge1
ovn-nbctl lsp-set-type transit-edge1 router
ovn-nbctl lsp-set-addresses transit-edge1 02:ac:10:ff:00:01
ovn-nbctl lsp-set-options transit-edge1 router-port=edge1-transit

# tenant1 to the transit switch
ovn-nbctl lrp-add tenant1 tenant1-transit 02:ac:10:ff:00:02 172.16.255.2/30
ovn-nbctl lsp-add transit transit-tenant1
ovn-nbctl lsp-set-type transit-tenant1 router
ovn-nbctl lsp-set-addresses transit-tenant1 02:ac:10:ff:00:02
ovn-nbctl lsp-set-options transit-tenant1 router-port=tenant1-transit

# add static routes
ovn-nbctl lr-route-add edge1 "172.16.255.128/25" 172.16.255.2
ovn-nbctl lr-route-add tenant1 "0.0.0.0/0" 172.16.255.1

ovn-sbctl show
