usage () {
    cat << EOF
usage: ovn-port COMMAND

These commands need to be run on the host where you plan
to spawn your namespaces.

Commands:
  add-port [--db=tcp:IP:6640] LSWITCH LPORT_NAME IP/MASK GATEWAY
  del-port [--db=tcp:IP:6640] LPORT_NAME
EOF
}

add_port () {

    case $1 in
      --db=*)
            DB=`expr X"$1" : 'X[^=]*=\(.*\)'`
            shift
            ;;
    esac

    LSWITCH=$1
    if [ -z "$LSWITCH" ]; then
        echo "No switch name given" >& 2
        exit 1
    fi

    if [ -n "$DB" ]; then
        exists=`ovn-nbctl --db=$DB get logical_switch $LSWITCH name`
    else
        exists=`ovn-nbctl get logical_switch $LSWITCH name`
    fi

    if [ -z "$exists" ]; then
       echo "$LSWITCH switch does not exist in NB"
       exit 1
    fi

    LPORT_NAME=$2
    if [ -z "$LPORT_NAME" ]; then
        echo "No lport name given" >& 2
        exit 1
    fi

    IP=$3
    if [ -z "$IP" ]; then
        echo "No IP given" >& 2
        exit 1
    fi

    GATEWAY=$4
    if [ -z "$GATEWAY" ]; then
        echo "No GATEWAY given" >& 2
        exit 1
    fi

    x=`shuf -i 1-99  -n 1`
    y=`shuf -i 1-99  -n 1`
    z=`shuf -i 1-99  -n 1`

    MAC="00:02:03:$x:$y:$z"

    if [ -n "$DB" ]; then
        ovn-nbctl --db=$DB lsp-add $LSWITCH $LPORT_NAME
    else
        ovn-nbctl lsp-add $LSWITCH $LPORT_NAME
    fi

    IP_ONLY=`echo $IP | awk -F \/ '{print $1}'`
    if [ -n "$DB" ]; then
        ovn-nbctl --db=$DB lsp-set-addresses $LPORT_NAME "$MAC $IP_ONLY"
    else
        ovn-nbctl lsp-set-addresses $LPORT_NAME "$MAC $IP_ONLY"
    fi

    ip netns add $LPORT_NAME
    ip link add "${LPORT_NAME}_l" type veth peer name "${LPORT_NAME}_c"

    BRIDGE="br-int"
    if ovs-vsctl --may-exist add-port "$BRIDGE" "${LPORT_NAME}_l" \
           -- set interface "${LPORT_NAME}_l" \
           external_ids:iface-id="$LPORT_NAME"; then : ; else
            echo >&2 "$UTIL: Failed to add "${LPORT_NAME}_l" port to bridge $BRIDGE"
            ip link delete "${LPORT_NAME}_l"
            exit 1
    fi

    ip link set "${LPORT_NAME}_l" up
    ip link set "${LPORT_NAME}_c" netns "${LPORT_NAME}"
    ip netns exec "${LPORT_NAME}" ip link set dev "${LPORT_NAME}_c" name eth0
    ip netns exec "${LPORT_NAME}" ip link set eth0 up
    ip netns exec "${LPORT_NAME}" ip link set dev eth0 mtu 1440

    ip netns exec "${LPORT_NAME}" ip addr add $IP dev eth0
    ip netns exec "${LPORT_NAME}"  ip link set dev eth0 address "$MAC"
    ip netns exec "${LPORT_NAME}"  ip route add default via "$GATEWAY"
}

del_port () {
    case $1 in
      --db=*)
            DB=`expr X"$1" : 'X[^=]*=\(.*\)'`
            shift
            ;;
    esac

    LPORT_NAME=$1
    if [ -z "$LPORT_NAME" ]; then
        echo "No lport name given" >& 2
        exit 1
    fi

    if [ -n "$DB" ]; then
        ovn-nbctl --db=$DB lport-del $LPORT_NAME
    else
        ovn-nbctl lport-del $LPORT_NAME
    fi

    ip netns delete $LPORT_NAME
    ovs-vsctl del-port ${LPORT_NAME}_l
    ip link delete ${LPORT_NAME}_l
}

case $1 in
    "add-port")
        shift
        add_port "$@"
        exit 0
        ;;
    "del-port")
        shift
        del_port "$@"
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
