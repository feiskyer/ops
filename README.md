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

## Docker

- Install docker v1.13: `kubernetes/install-docker.sh`
- Install docker latest: `export DOCKER_VERSION="latest" && kubernetes/install-docker.sh`

## Kubernetes

### Create a kubernetes cluster master

- Install kubernetes with docker: `kubernetes/install-kubernetes.sh`

### Add a new node

```sh
# Setup token and CIDR first.
# replace this with yours.
export TOKEN="xxxx"
export MASTER_IP="x.x.x.x"
export CONTAINER_CIDR="10.244.2.0/24"

kubernetes/add-docker-node.sh
```

### Kubernetes manifest examples

See [k8s-examples](k8s-examples/README.md).

## OVS

- Install ovs: `ovs/ovs-install.sh`
- Start ovn: `ovs/ovn-start.sh`

## Misc

- Install golang: `misc/golang-install.sh`
