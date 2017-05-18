#!/bin/bash
#

#
# Ref: http://blog.spinhirne.com/2016/09/the-ovn-load-balancer.html
#

do_poke_webserver () {
    ITER_ID=$1
    VIP=$2
    TCP_PORT=$3
    
    # set -x
    echo -n "Iteration $ITER_ID: "
    curl --silent ${VIP}:${TCP_PORT}
}

for x in $(seq 10) ; do
    do_poke_webserver -- $x 10.10.0.254 8000
done
