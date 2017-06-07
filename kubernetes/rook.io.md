# Rook.io

Deploy rook cluster:

```sh
# create rook operator
$ kubectl create -f https://github.com/rook/rook/raw/master/demo/kubernetes/rook-operator.yaml
$ kubectl get pods
NAME                             READY     STATUS    RESTARTS   AGE
rook-operator-1641293690-19xjb   1/1       Running   0          1m

# create rook cluster
$ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/demo/kubernetes/rook-cluster.yaml
$ kubectl -n rook get pod
NAME                        READY     STATUS    RESTARTS   AGE
mon0-vrbz8                  1/1       Running   0          1m
mon1-4f7mm                  1/1       Running   0          1m
mon2-f997l                  1/1       Running   0          1m
osd-ml38s                   1/1       Running   0          53s
rook-api-3856091537-sz01s   1/1       Running   0          53s
```

Playing with rook client

```sh
# create rook client
$ kubectl create -f https://raw.githubusercontent.com/rook/rook/master/demo/kubernetes/rook-client.yaml
# Check when the pod is in the Running state
$ kubectl -n rook get pod rook-client
NAME          READY     STATUS    RESTARTS   AGE
rook-client   1/1       Running   0          1m
# Connect to the client pod 
$ kubectl -n rook exec rook-client -it sh
/ # rook node ls
PUBLIC     PRIVATE   STATE     CLUSTER   SIZE      LOCATION   UPDATED
ubuntu-0             OK                  0 B                  0s ago
/ # rook block create --name test --size 10485760
succeeded created image test
/ # rook block map --name test --format --mount /tmp/rook-volume
2017-06-07 03:30:52.525199 I | mkfs.ext4 /dev/rbd0: Discarding device blocks: done
2017-06-07 03:30:52.525744 I | mkfs.ext4 /dev/rbd0: Creating filesystem with 10240 1k blocks and 2560 inodes
2017-06-07 03:30:52.525776 I | mkfs.ext4 /dev/rbd0: Filesystem UUID: 82088113-f97c-4430-b803-feb0dd8b57bd
2017-06-07 03:30:52.525822 I | mkfs.ext4 /dev/rbd0: Superblock backups stored on blocks:
2017-06-07 03:30:52.525841 I | mkfs.ext4 /dev/rbd0: 	8193
2017-06-07 03:30:52.525854 I | mkfs.ext4 /dev/rbd0:
2017-06-07 03:30:52.525925 I | mkfs.ext4 /dev/rbd0: Allocating group tables: done
2017-06-07 03:30:52.526459 I | mkfs.ext4 /dev/rbd0: Writing inode tables: done
2017-06-07 03:30:52.532104 I | mkfs.ext4 /dev/rbd0: Creating journal (1024 blocks): done
2017-06-07 03:30:52.550334 I | mkfs.ext4 /dev/rbd0: Writing superblocks and filesystem accounting information: done
2017-06-07 03:30:52.550366 I | mkfs.ext4 /dev/rbd0:
2017-06-07 03:30:52.550577 I | mkfs.ext4 /dev/rbd0: mke2fs 1.43.3 (04-Sep-2016)
succeeded mapping image test on device /dev/rbd0, formatted, and mounted at /tmp/rook-volume
/ # df | grep /tmp/rook-volume
/dev/rbd0                 8887       172      7999   2% /tmp/rook-volume
/ #
/ #
/ # rook block unmap --mount /tmp/rook-volume
succeeded removing rbd device /dev/rbd0 from '/tmp/rook-volume'
/ #
```

## Special notes for frakti

Because frakti creates pod in hyperVM, which requires setting cpu/memory limits. Or else, it will create hyperVM with 1vcpu and 64MB memory. But 64MB is not sufficient for rook.io components, so we need to set the default memory larger, e.g: 

```sh
# deploy kubernetes with frakti
$ curl -sSL https://github.com/kubernetes/frakti/raw/master/cluster/allinone.sh | bash

# change default memory to 256MB, add --memory=256 at the end
$ grep ExecStart /lib/systemd/system/frakti.service
ExecStart=/usr/bin/frakti --v=3 --log-dir=/var/log/frakti --logtostderr=false --cgroup-driver=cgroupfs --listen=/var/run/frakti.sock --streaming-server-addr=%H --hyper-endpoint=127.0.0.1:22318 --memory=256
$ systemctl daemon-reload
$ systemctl restart frakti
```
