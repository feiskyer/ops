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

## FAQ

**Ceph install failed because of package conflicts on CentOS 7**

Install ceph manually and retry devstack:

```sh
sudo rpm -Uvh https://download.ceph.com/rpm-jewel/el7/noarch/ceph-release-1-1.el7.noarch.rpm
sudo yum install -y ceph
```

**sudo ip -6 addr replace 2001:db8::2/64 dev br-ex Permission denied**

Enable ipv6

```sh
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=0
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=0
```

## Reference

- <https://github.com/openstack/stackube/tree/master/devstack>

