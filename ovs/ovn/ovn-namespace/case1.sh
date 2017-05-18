# 4 logical switches. 2 of them connected to one router. Another 2 to a 
# different one. The routers are connected via peer option.

usage () {
    cat << EOF
usage: case1.sh COMMAND

Commands:
  host1 Run commands for host1. This host has northd running.
  host2 --db=tcp:IP:6641 Run commands for host2
EOF
}

host1 () {
sh ovn-router.sh create-router R1
ovn-nbctl ls-add foo
ovn-nbctl ls-add bar
sh ovn-router.sh connect-switch R1 foo 192.168.1.1/24
sh ovn-router.sh connect-switch R1 bar 192.168.2.1/24

sh ovn-router.sh create-router R2
ovn-nbctl ls-add alice
ovn-nbctl ls-add bob
sh ovn-router.sh connect-switch R2 alice 172.16.1.1/24
sh ovn-router.sh connect-switch R2 bob 172.16.2.1/24

sh ovn-router.sh connect-router R1 20.0.0.1/24 R2 20.0.0.2/24
ovn-nbctl lr-route-add R1 0.0.0.0/0 20.0.0.2
ovn-nbctl lr-route-add R2 0.0.0.0/0 20.0.0.1

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

sh ovn-port.sh add-port --db=$DB bar bar1 192.168.2.2/24 192.168.2.1
sh ovn-port.sh add-port --db=$DB bob bob1 172.16.2.2/24 172.16.2.1
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
