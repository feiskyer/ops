# Stackube

## Install via devstack

```sh
# create stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo su - stack

git clone https://git.openstack.org/openstack-dev/devstack -b stable/ocata
cd devstack
curl -sSL https://raw.githubusercontent.com/openstack/stackube/master/devstack/local.conf.sample -o local.conf

# install
./stack.sh
```

## Setup kubernetes and OpenStack client:

```sh
# Kubernetes
export KUBECONFIG=/etc/kubernetes/admin.conf
kubectl cluster-info

# OpenStack
source /opt/stack/devstack/openrc admin admin
openstack service list
```

## Add a node

```sh
# create stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo su - stack

git clone https://git.openstack.org/openstack-dev/devstack -b stable/ocata
cd devstack

curl -sSL https://raw.githubusercontent.com/openstack/stackube/master/devstack/local.conf.node.sample -o local.conf
```

Set configure in local.conf:

- set `HOST_IP` to local host's IP
- set `SERVICE_HOST` to master's IP
- set `KUBEADM_TOKEN` to kubeadm token

Run `./stack.sh` to install.

## CNI Internal

CNI network config

```json
{
    "cniVersion": "0.3.1",
    "name": "net",
    "type": "kubestack",
    "kubestack-config": "/etc/kubestack.conf"
}
```

/etc/kubestack.conf

```conf
[Global]
auth-url=https://192.168.0.3/identity_admin/v2.0
username=admin
password=password
tenant-name=admin
region=RegionOne
ext-net-id=550370a3-4fc2-4494-919d-cae33f5b3de8
[Plugin]
plugin-name=ovs
integration-bridge=br-int
```

evaluate

```sh

$ cd /root/gopath/src/git.openstack.org/openstack/stackube
$ sudo ip netns add ns

# Add
$ echo '{"cniVersion": "0.3.1","name": "net","type": "kubestack","kubestack-config": "/etc/kubestack.conf"}' | sudo CNI_COMMAND=ADD CNI_NETNS=/var/run/netns/ns CNI_PATH=./_output CNI_IFNAME=eth0 CNI_CONTAINERID=id CNI_VERSION=0.3.1 CNI_ARGS='IgnoreUnknown=1;K8S_POD_NAMESPACE=alice;K8S_POD_NAME=pod;K8S_POD_INFRA_CONTAINER_ID=id' ./_output/kubestack

# Del
$ echo '{"cniVersion": "0.3.1","name": "net","type": "kubestack","kubestack-config": "/etc/kubestack.conf"}' | sudo CNI_COMMAND=DEL CNI_NETNS=/var/run/netns/ns CNI_PATH=./_output CNI_IFNAME=eth0 CNI_CONTAINERID=id CNI_VERSION=0.3.1 CNI_ARGS='IgnoreUnknown=1;K8S_POD_NAMESPACE=alice;K8S_POD_NAME=pod;K8S_POD_INFRA_CONTAINER_ID=id' ./_output/kubestack

# Sample output of bridge plugin.
$ sudo CNI_PATH=/opt/cni/bin cnitool add mynet /var/run/netns/ns
{
    "cniVersion": "0.3.1",
    "interfaces": [
        {
            "name": "cni0",
            "mac": "0a:58:0a:f4:01:01"
        },
        {
            "name": "vethe7bd96ce",
            "mac": "c2:36:17:41:aa:45"
        },
        {
            "name": "eth0",
            "mac": "0a:58:0a:f4:01:0a",
            "sandbox": "/var/run/netns/ns"
        }
    ],
    "ips": [
        {
            "version": "4",
            "interface": 2,
            "address": "10.244.1.10/24",
            "gateway": "10.244.1.1"
        }
    ],
    "routes": [
        {
            "dst": "0.0.0.0/0"
        }
    ],
    "dns": {}
}
```

## User Guide

```sh
$ cat <<EOF | kubectl create -f -
apiVersion: "stackube.kubernetes.io/v1"
kind: Tenant
metadata:
  name: test
spec:
  username: "test"
  password: "password"
EOF

$ cat > test.conf <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    insecure-skip-tls-verify: true
    server: https://192.168.128.66:6443
  name: stackube
contexts:
- context:
    cluster: stackube
    namespace: test
    user: test
  name: test
current-context: test
users:
- name: test
  user:
    password: password
    username: test
EOF

# wait for network Active
kubectl get namespace test
kubectl -n test get network -o yaml

# switch to user test's config
export KUBECONFIG=$(pwd)/test.conf

kubectl -n test run nginx --image=nginx
# wait for pod running
kubectl -n test get pod -o wide -w
# create service
kubectl -n test expose deploy nginx --port=80 --name=nginx
kubectl -n test expose deploy nginx --type=LoadBalancer --port=80 --name=http
# wait for service initialization
kubectl -n test get service -w
# visit service inside pod
kubectl -n test run -i -t --image=busybox sh
```
