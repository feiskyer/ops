# Rook.io

Install ceph client on all hosts first:

```sh
apt-get install -y ceph-fs-common ceph-common
```

Create rook operator and wait its up:

```sh
$ kubectl create -f https://github.com/rook/rook/blob/master/demo/kubernetes/rook-operator.yaml
$ kubectl get pod
NAME                             READY     STATUS    RESTARTS   AGE
rook-operator-3695076312-6th4n   1/1       Running   0          5m
```

Create rook cluster and wait cluster up:

```sh
$ kubectl create -f https://github.com/rook/rook/blob/master/demo/kubernetes/rook-cluster.yaml
$ kubectl -n rook get pod
NAME                        READY     STATUS    RESTARTS   AGE
mon0                        1/1       Running   0          2m
mon1                        1/1       Running   0          2m
mon2                        1/1       Running   0          2m
osd-8lpvc                   1/1       Running   0          1m
rook-api-3856091537-pwnr3   1/1       Running   0          1m
```

Create client and play with rook:

```sh
$ kubectl create -f https://github.com/rook/rook/blob/master/demo/kubernetes/rook-client.yaml
$ kubectl -n rook get pod rook-client -w
NAME          READY     STATUS    RESTARTS   AGE
rook-client   1/1       Running   0          1m
$ kubectl -n rook exec -it rook-client sh
/ # 
/ # rook status
OVERALL STATUS: WARNING

SUMMARY:
SEVERITY   MESSAGE
WARNING    too many PGs per OSD (2048 > max 300)
WARNING    Monitor clock skew detected 

USAGE:
TOTAL       USED       DATA      AVAILABLE
19.32 GiB   5.69 GiB   0 B       13.64 GiB

MONITORS:
NAME      ADDRESS             IN QUORUM   STATUS
mon0      10.244.1.4:6790/0   true        OK
mon1      10.244.1.5:6790/0   true        OK
mon2      10.244.1.6:6790/0   true        OK

OSDs:
TOTAL     UP        IN        FULL      NEAR FULL
1         1         1         false     false

PLACEMENT GROUPS (2048 total):
STATE          COUNT
active+clean   2048
```

Play with block storage:

```sh
# create a block storage
rook block create --name test --size 10485760
# map, format and mount it
rook block map --name test --format --mount /tmp/rook-volume
# write and read files
echo "Hello Rook!" > /tmp/rook-volume/hello
cat /tmp/rook-volume/hello
# unmap and delete
rook block unmap --mount /tmp/rook-volume
rook block delete --name test
```

Play with shared filesystem

```sh
# create filesystem
rook filesystem create --name testFS
# mount the shared filesystem
rook filesystem mount --name testFS --path /tmp/rookFS
# write and read files
echo "Hello Rook!" > /tmp/rookFS/hello
cat /tmp/rookFS/hello
# umount and delete
rook filesystem unmount --path /tmp/rookFS
rook filesystem delete --name testFS
```

Play with Object Storage

```sh
# Create an object storage
rook object create
#Create an object storage user
rook object user create rook-user "my object store user"

# setup s3 config
eval $(rook object connection rook-user --format env-var)
# Create a bucket in the object store
apk update && apk add python py2-pip
s3cmd mb --no-ssl --host=${AWS_ENDPOINT} --host-bucket=  s3://rookbucket
# List buckets in the object store
rook object bucket list
# Upload a file to the newly created bucket
echo "Hello Rook!" > /tmp/rookObj
s3cmd put /tmp/rookObj --no-ssl --host=${AWS_ENDPOINT} --host-bucket=  s3://rookbucket
# Download and verify the file from the bucket
s3cmd get s3://rookbucket/rookObj /tmp/rookObj-download --no-ssl --host=${AWS_ENDPOINT} --host-bucket=
cat /tmp/rookObj-download
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
