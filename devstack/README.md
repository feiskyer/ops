# Devstack

## Download devstack

```sh
# create stack user
sudo useradd -s /bin/bash -d /opt/stack -m stack
echo "stack ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/stack
sudo su - stack

git clone https://git.openstack.org/openstack-dev/devstack -b stable/ocata
cd devstack
```

## Install components

- For kubernetes, create local.conf from kubernetes.conf.sample
- For OpenStack, create local.conf from openstack.conf.sample
- Combined, create local.conf from local.conf.sample

Then run `./stack.sh` to install.

## Play with OpenStack/Kubernetes

```sh
# Kubernetes
export KUBECONFIG=$HOME/admin.conf
kubectl cluster-info

# OpenStack
source openrc admin admin
openstack service list
```
