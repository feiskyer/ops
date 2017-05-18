usage () {
    cat << EOF
usage: ovn-router COMMAND

Commands:
  create-router NAME

  connect-switch ROUTER SWITCH SUBNET
  disconnect-switch ROUTER SWITCH

  connect-router ROUTER1 ROUTER1_SUBNET ROUTER2 ROUTER2_SUBNET
  disconnect-router ROUTER1 ROUTER2
EOF
}

create_router () {
    NAME=$1
    if [ -z "$NAME" ]; then
        echo "No router name given" >& 2
        exit 1
    fi

    ovn-nbctl create Logical_Router name=$NAME
}

connect_switch () {
    ROUTER_NAME="$1"
    SWITCH_NAME="$2"
    SUBNET="$3"

    if [ -z "$ROUTER_NAME" ] || [ -z "$SWITCH_NAME" ]; then
    echo >&2 "router name or switch name not given"
    exit 1
    fi

    if [ -z "$SUBNET" ]; then
    echo >&2 "subnet not given"
    exit 1
    fi

    x=`shuf -i 1-99  -n 1`
    y=`shuf -i 1-99  -n 1`
    z=`shuf -i 1-99  -n 1`

    LRP_MAC="00:00:00:$x:$y:$z"

    lrp_uuid=`ovn-nbctl -- --id=@lrp create Logical_Router_port name=$SWITCH_NAME \
    network=$SUBNET mac=\"$LRP_MAC\" -- add Logical_Router $ROUTER_NAME ports @lrp \
    -- lsp-add $SWITCH_NAME rp-"$SWITCH_NAME"`

    ovn-nbctl set Logical_switch_port rp-"$SWITCH_NAME" \
    type=router options:router-port=$SWITCH_NAME addresses=\"$LRP_MAC\"
}

disconnect_switch () {
    ROUTER_NAME="$1"
    SWITCH_NAME="$2"

    if [ -z "$ROUTER_NAME" ] || [ -z "$SWITCH_NAME" ]; then
    echo >&2 "router name or switch name not given"
    exit 1
    fi

    lrp1_uuid=`ovn-nbctl --data=bare --no-heading --columns=_uuid find logical_router_port name=$SWITCH_NAME`

    if [ -z "$lrp1_uuid" ]; then
    echo "no switch with name $SWITCH_NAME connected to $ROUTER_NAME" 
    exit 1
    fi

    ovn-nbctl remove Logical_Router $ROUTER_NAME ports $lrp1_uuid -- destroy logical_router_port $lrp1_uuid
    ovn-nbctl lport-del "rp-$SWITCH_NAME"
}

connect_router () {
    ROUTER1="$1"
    ROUTER1_SUBNET="$2"
    ROUTER2="$3"
    ROUTER2_SUBNET="$4"

    if [ -z "$ROUTER1" ] || [ -z "$ROUTER1_SUBNET" ]; then
    echo >&2 "router1 name or subnet not given"
    exit 1
    fi

    if [ -z "$ROUTER2" ] || [ -z "$ROUTER2_SUBNET" ]; then
    echo >&2 "router2 name or subnet not given"
    exit 1
    fi

    x=`shuf -i 1-99  -n 1`
    y=`shuf -i 1-99  -n 1`
    z=`shuf -i 1-99  -n 1`

    ROUTER1_MAC="00:00:00:$x:$y:$z"

    lrp1_uuid=`ovn-nbctl -- --id=@lrp create Logical_Router_port \
    name=${ROUTER1}_$ROUTER2 \
    network=$ROUTER1_SUBNET mac=\"$ROUTER1_MAC\" -- \
    add Logical_Router $ROUTER1 ports @lrp`

    x=`shuf -i 1-99  -n 1`
    y=`shuf -i 1-99  -n 1`
    z=`shuf -i 1-99  -n 1`

    ROUTER2_MAC="00:00:00:$x:$y:$z"

    lrp2_uuid=`ovn-nbctl -- --id=@lrp create Logical_Router_port \
    name=${ROUTER2}_$ROUTER1 \
    network=$ROUTER2_SUBNET mac=\"$ROUTER2_MAC\" -- \
    add Logical_Router $ROUTER2 ports @lrp`

    ovn-nbctl set logical_router_port $lrp1_uuid peer=${ROUTER2}_$ROUTER1
    ovn-nbctl set logical_router_port $lrp2_uuid peer=${ROUTER1}_$ROUTER2
}

disconnect_router () {
    ROUTER1="$1"
    ROUTER2="$2"

    if [ -z "$ROUTER1" ] || [ -z "$ROUTER2" ]; then
    echo >&2 "router1 and router2 name not given"
    exit 1
    fi

    lrp1_uuid=`ovn-nbctl --data=bare --no-heading --columns=_uuid find logical_router_port name=${ROUTER1}_$ROUTER2`
    lrp2_uuid=`ovn-nbctl --data=bare --no-heading --columns=_uuid find logical_router_port name=${ROUTER2}_$ROUTER1`

    if [ -z "$lrp1_uuid" ] || [ -z $lrp2_uuid ]; then
    echo >&2 "failed to fetch uuids of router ports from names"
    exit 1
    fi

    ovn-nbctl remove logical_router "$ROUTER1" ports $lrp1_uuid -- destroy logical_router_port $lrp1_uuid 
    ovn-nbctl remove logical_router "$ROUTER2" ports $lrp2_uuid -- destroy logical_router_port $lrp2_uuid

}


case $1 in
    "create-router")
        shift
        create_router "$@"
        exit 0
        ;;
    "connect-switch")
        shift
        connect_switch "$@"
        exit 0
        ;;
    "disconnect-switch")
        shift
        disconnect_switch "$@"
        exit 0
        ;;
    "connect-router")
        shift
        connect_router "$@"
        exit 0
        ;;
    "disconnect-router")
        shift
        disconnect_router "$@"
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
