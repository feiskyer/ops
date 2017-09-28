# Devops

[![Build Status](https://travis-ci.org/feiskyer/ops.svg?branch=master)](https://travis-ci.org/feiskyer/ops) 

Tools&scripts for devops.

**Contents**

- Container/docker management
- Kubernetes deployment&management
- Networking experiments
- Vagrant tools

## Install

```sh
git clone https://github.com/feiskyer/ops.git
cd ops
```

## Docker

Install docker v1.13:

```sh
kubernetes/install-docker.sh
```

Install docker latest:

```sh
export DOCKER_VERSION="latest"
kubernetes/install-docker.sh
```

## Kubernetes

### Install kubernetes (with docker)

```sh
kubernetes/install-kubernetes.sh
```

### Install kubernetes (with hyper via frakti)

Install latest stable version:

```sh
kubernetes/install-kubernetes-frakti.sh
```

### Add a node

```sh
# replace this with yours.
export TOKEN="xxxx"
export MASTER_IP="x.x.x.x"
export CONTAINER_CIDR="10.244.2.0/24"
```

Add a new node with docker runtime:

```sh
# Install kubernetes and add it to cluster.
kubernetes/add-docker-node.sh
```

Add a new node with hyper runtime:

```sh
# Install kubernetes and add it to cluster.
kubernetes/add-hyper-node.sh
```

## OVS

Install ovs:

```sh
ovs/ovs-install.sh
```

Start ovn:

```sh
ovs/ovn-start.sh
```

## Misc

Install golang:

```sh
misc/golang-install.sh
```
