# Logical network:
# Three LRs - R1, R2 and R3 that are connected to each other via LS "join"
# in 20.0.0.0/24 network. R1 has switchess foo (192.168.1.0/24)
# connected to it. R2 has alice (172.16.1.0/24) and R3 has bob (10.32.1.0/24)
# connected to it.

usage () {
    cat << EOF
usage: case1.sh COMMAND

Commands:
  host1 Run commands for host1. This host has northd running.
  host2 --db=tcp:IP:6641 Run commands for host2
EOF
}

host1 () {
ovn-nbctl create Logical_Router name=R1
ovn-nbctl create Logical_Router name=R2
ovn-nbctl create Logical_Router name=R3

ovn-nbctl ls-add foo
ovn-nbctl ls-add alice
ovn-nbctl ls-add bob
ovn-nbctl ls-add join

# Connect foo to R1
ovn-nbctl -- --id=@lrp create Logical_Router_port name=foo \
network=192.168.1.1/24 mac=\"00:00:01:01:02:03\" -- add Logical_Router R1 \
ports @lrp -- lsp-add foo rp-foo

ovn-nbctl set Logical_switch_port rp-foo type=router options:router-port=foo \
addresses=\"00:00:01:01:02:03\"

# Connect alice to R2
ovn-nbctl -- --id=@lrp create Logical_Router_port name=alice \
network=172.16.1.1/24 mac=\"00:00:02:01:02:03\" -- add Logical_Router R2 \
ports @lrp -- lsp-add alice rp-alice

ovn-nbctl set Logical_switch_port rp-alice type=router options:router-port=alice \
addresses=\"00:00:02:01:02:03\"

# Connect bob to R3
ovn-nbctl -- --id=@lrp create Logical_Router_port name=bob \
network=10.32.1.1/24 mac=\"00:00:03:01:02:03\" -- add Logical_Router R3 \
ports @lrp -- lsp-add bob rp-bob

ovn-nbctl set Logical_switch_port rp-bob type=router options:router-port=bob \
addresses=\"00:00:03:01:02:03\"

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


# Connect R3 to join
ovn-nbctl -- --id=@lrp create Logical_Router_port name=R3_join \
network=20.0.0.3/24 mac=\"00:00:04:01:02:05\" -- add Logical_Router R3 \
ports @lrp -- lsp-add join r3-join

ovn-nbctl set Logical_switch_port r3-join type=router options:router-port=R3_join \
addresses='"00:00:04:01:02:05"'

ovn-nbctl set Logical_Router R1 static_routes:172.16.1.0/24=20.0.0.2
ovn-nbctl set logical_router R1 static_routes:10.32.1.0/24=20.0.0.3

ovn-nbctl set logical_router R2 static_routes:192.168.1.0/24=20.0.0.1
ovn-nbctl set logical_router R2 static_routes:10.32.1.0/24=20.0.0.3

ovn-nbctl set logical_router R3 static_routes:192.168.1.0/24=20.0.0.1
ovn-nbctl set logical_router R3 static_routes:172.16.1.0/24=20.0.0.2

sh ovn-port.sh add-port foo foo1 192.168.1.2/24 192.168.1.1
sh ovn-port.sh add-port alice alice1 172.16.1.2/24 172.16.1.1
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

sh ovn-port.sh add-port --db=$DB bob bob1 10.32.1.2/24 10.32.1.1
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
