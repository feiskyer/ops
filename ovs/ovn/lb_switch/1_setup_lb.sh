#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-load-balancer.html
#

do_start_webserver () {
    set -e
    set -x
    VMNAME=$1
    NSNAME=$2
    
    mkdir -pv /tmp/www/${VMNAME}
    cd /tmp/www/${VMNAME}
    echo "i am ${VMNAME}" > ./index.html
    ip netns exec ${NSNAME} nohup /usr/bin/python -m SimpleHTTPServer 8000 >log.txt 2>&1 &
}

do_start_webserver -- vm1 ns1
do_start_webserver -- vm2 ns3

set -x

uuid=$(ovn-nbctl create load_balancer vips:172.16.255.62="172.16.255.130,172.16.255.131")
echo $uuid

ovn-nbctl set logical_switch inside load_balancer=$uuid
ovn-nbctl get logical_switch inside load_balancer
