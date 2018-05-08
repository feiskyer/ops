# Devops

[![Build Status](https://travis-ci.org/feiskyer/ops.svg?branch=master)](https://travis-ci.org/feiskyer/ops)

Tools&scripts for devops.

**Contents**

- Container/docker management
- Kubernetes deployment&management
- Networking experiments
- Vagrant tools

## Get the scripts

```sh
git clone https://github.com/feiskyer/ops.git
cd ops
```

## Kubernetes

### Create a kubernetes cluster master

- Install kubernetes with docker:

```sh
# Setup kubernetes master.
./kubernetes/install-kubernetes.sh
```

### Add a new node

```sh
# Setup token and CIDR first.
# replace this with yours.
export TOKEN="xxxx"
export MASTER_IP="x.x.x.x"
export CONTAINER_CIDR="10.244.2.0/24"

# Setup and join the new node.
./kubernetes/add-node.sh
```

### Customize

- Use mirrors in China: `export USE_MIRROR=true`. Only required for Chinese users.
- Container runtime: `export CONTAINER_RUNTIME="docker"`. Supported options:
  - docker
  - containerd
  - cri-o
  - gvisor
- CNI network plugins: `export NETWORK_PLUGIN="flannel"`. Supported options:
  - flannel
  - calico
  - weave
  - azure
  - bridge
- Cluster CIDR: `export CLUSTER_CIDR="10.244.0.0/16"`
- Container CIDR: `export CONTAINER_CIDR="10.244.1.0/24"`. Only required for bridge network plugin.

### Kubernetes manifest examples

See [k8s-examples](k8s-examples/README.md).

## Docker

- Install docker v1.13: `./kubernetes/install-docker.sh`
- Install docker latest: `export DOCKER_VERSION="latest" && ./kubernetes/install-docker.sh`

## OVS

- Install ovs: `./ovs/ovs-install.sh`
- Start ovn: `./ovs/ovn-start.sh`

## Misc

- Install golang: `./misc/golang-install.sh`
