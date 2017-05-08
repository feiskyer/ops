#!/bin/bash

function wait() {
  echo -e "\n"
  read -rsn 1;
}

crictl help
wait
crictl info
wait
crictl status
wait
crictl sandbox ls
wait
cat sandbox-config.json
wait
sid=$(crictl sandbox run sandbox-config.json)
echo $sid
wait
crictl sandbox ls
wait
crictl sandbox ls -v
wait
crictl image ls
wait
crictl image pull busybox
wait
crictl image ls
wait
crictl image ls -v
wait
crictl container ls
wait
cat container-config.json
wait
cid=$(crictl container create $sid container-config.json sandbox-config.json)
echo $cid
wait
crictl container start $cid
wait
crictl container ls
wait
crictl container ls -v
wait
crictl exec -i -t $cid sh
wait
crictl container stop $cid
crictl container rm $cid
crictl sandbox stop $sid
crictl sandbox rm $sid
crictl image rm busybox
