#!/bin/bash
# 2 logical switches "foo" (192.168.1.0/24) and "bar" (172.16.1.0/24)
# connected to a router R1.
# foo has foo1, foo2, foo3 spread on 2 machines.
# bar has bar1, bar2, bar3 spread on 2 machines.
# 
# Loadbalancer rules in 30.0.0.0/24 network.

usage () {
    cat << EOF
usage: lb.sh COMMAND

Commands:
  host1 Run commands for host1. This host has northd running.
  host2 --db=tcp:IP:6640 Run commands for host2
EOF
}

host1 () {
    ./ovn-router.sh create-router R1
    ovn-nbctl ls-add foo
    ovn-nbctl ls-add bar
    ./ovn-router.sh connect-switch R1 foo 192.168.1.1/24
    ./ovn-router.sh connect-switch R1 bar 172.16.1.1/24

    ./ovn-port.sh add-port foo foo1 192.168.1.2/24 192.168.1.1
    ./ovn-port.sh add-port foo foo2 192.168.1.3/24 192.168.1.1

    ./ovn-port.sh add-port bar bar1 172.16.1.2/24 172.16.1.1

    # Config OVN load-balancer.
    uuid=`ovn-nbctl  create load_balancer vips:30.0.0.1="172.16.1.2,172.16.1.3,172.16.1.4"`
    ovn-nbctl set logical_switch foo load_balancer=$uuid
}

host2 () {
    case $1 in
      --db=*)
        DB=`expr X"$1" : 'X[^=]*=\(.*\)'`
            shift
            ;;
    esac

    if [ -z "$DB" ]; then
    echo "DB not given"
    exit 1
    fi

    ./ovn-port.sh add-port --db=$DB foo foo3 192.168.1.4/24 192.168.1.1
    ./ovn-port.sh add-port --db=$DB bar bar2 172.16.1.3/24 172.16.1.1
    ./ovn-port.sh add-port --db=$DB bar bar3 172.16.1.4/24 172.16.1.1
}


case $1 in
    "host1")
        shift
        host1
        exit 0
        ;;
    "host2")
        shift
        host2 "$@"
        exit 0
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo >&2 "$UTIL: unknown command \"$1\" (use --help for help)"
        exit 1
        ;;
esac
