# Devstack

## For Kubernetes

Install components:

```sh
git clone https://git.openstack.org/openstack-dev/devstack -b stable/ocata
cd devstack
tools/create-stack-user.sh

# create local.conf
# copy kubernetes.conf.sample from this repo

# start install
su - stack
./stack.sh
```

Playing with kubernetes:

```sh
export KUBECONFIG=/etc/kubernetes/admin.conf

# Playing with kubernetes now.
kubectl cluster-info
```


## For OpenStack

Install components:

```sh
git clone https://git.openstack.org/openstack-dev/devstack -b stable/ocata
cd devstack
tools/create-stack-user.sh

# create local.conf
# copy openstack.conf.sample from this repo

# start install
# or yum install -y libvirt ceph
sudo apt-get install -y libvirt-bin ceph-common
su - stack
./stack.sh
```

Playing with openstack:

```sh
# source config
source openrc admin admin

# playing with openstack commands now.
openstack service list
```
