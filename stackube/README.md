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
export KUBECONFIG=$HOME/admin.conf
kubectl cluster-info

# OpenStack
source openrc admin admin
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

