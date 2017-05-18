# Logical network:
# 2 LRs - R1, R2 that are connected to each other via LS "join"
# in 20.0.0.0/24 network. R1 has switchess foo (192.168.1.0/24)
# and bar (192.168.2.0/24) connected to it. R2 has alice (172.16.1.0/24) 
# R2 is a static (non-distributed) router. R1 and R2 are connected via switch "join"

usage () {
    cat << EOF
usage: case3.sh COMMAND

Commands:
  host1 --chassis=$chassis Run commands for host1. This host has northd running.
  host2 --db=tcp:IP:6641 Run commands for host2
EOF
}

host1 () {
echo $1

case $1 in
  --chassis=*)
    chassis=`expr X"$1" : 'X[^=]*=\(.*\)'`
        shift
        ;;
esac

if [ -z "$chassis" ]; then
echo "chassis not given"
exit 1
fi

ovn-nbctl create Logical_Router name=R1
ovn-nbctl create Logical_Router name=R2 options:chassis=$chassis

ovn-nbctl ls-add foo
ovn-nbctl ls-add bar
ovn-nbctl ls-add alice
ovn-nbctl ls-add join

# Connect foo to R1
ovn-nbctl -- --id=@lrp create Logical_Router_port name=foo \
network=192.168.1.1/24 mac=\"00:00:01:01:02:03\" -- add Logical_Router R1 \
ports @lrp -- lsp-add foo rp-foo

ovn-nbctl set Logical_switch_port rp-foo type=router options:router-port=foo \
addresses=\"00:00:01:01:02:03\"

# Connect bar to R1
ovn-nbctl -- --id=@lrp create Logical_Router_port name=bar \
network=192.168.2.1/24 mac=\"00:00:01:01:02:04\" -- add Logical_Router R1 \
ports @lrp -- lsp-add bar rp-bar

ovn-nbctl set Logical_switch_port rp-bar type=router options:router-port=bar \
addresses=\"00:00:01:01:02:04\"

# Connect alice to R2
ovn-nbctl -- --id=@lrp create Logical_Router_port name=alice \
network=172.16.1.1/24 mac=\"00:00:02:01:02:03\" -- add Logical_Router R2 \
ports @lrp -- lsp-add alice rp-alice

ovn-nbctl set Logical_switch_port rp-alice type=router options:router-port=alice \
addresses=\"00:00:02:01:02:03\"

# Connect R1 to join
ovn-nbctl -- --id=@lrp create Logical_Router_port name=R1_join \
network=20.0.0.1/24 mac=\"00:00:04:01:02:03\" -- add Logical_Router R1 \
ports @lrp -- lsp-add join r1-join

ovn-nbctl set Logical_switch_port r1-join type=router options:router-port=R1_join \
addresses='"00:00:04:01:02:03"'

# Connect R2 to join
ovn-nbctl -- --id=@lrp create Logical_Router_port name=R2_join \
network=20.0.0.2/24 mac=\"00:00:04:01:02:04\" -- add Logical_Router R2 \
ports @lrp -- lsp-add join r2-join

ovn-nbctl set Logical_switch_port r2-join type=router options:router-port=R2_join \
addresses='"00:00:04:01:02:04"'


ovn-nbctl -- --id=@lrt create Logical_Router_Static_Route \
ip_prefix=172.16.1.0/24 nexthop=20.0.0.2 -- add Logical_Router \
R1 static_routes @lrt

ovn-nbctl -- --id=@lrt create Logical_Router_Static_Route \
ip_prefix=192.168.1.0/24 nexthop=20.0.0.1 -- add Logical_Router \
R2 static_routes @lrt

ovn-nbctl -- --id=@lrt create Logical_Router_Static_Route \
ip_prefix=192.168.2.0/24 nexthop=20.0.0.1 -- add Logical_Router \
R2 static_routes @lrt

sh ovn-port.sh add-port  foo foo1 192.168.1.2/24 192.168.1.1
sh ovn-port.sh add-port  bar bar1 192.168.2.2/24 192.168.2.1

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

sh ovn-port.sh add-port --db=$DB alice alice1 172.16.1.2/24 172.16.1.1
}


case $1 in
    "host1")
        shift
        host1 "$*"
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
