# Devops

[![Build Status](https://travis-ci.org/feiskyer/ops.svg?branch=master)](https://travis-ci.org/feiskyer/ops) 

Tools&scripts for daily devops.

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

Add a new node with docker:

```
# Install kubernetes and add it to cluster.
kubernetes/add-docker-node.sh
```

Add a new node with hyper:

```
# Install kubernetes and add it to cluster.
kubernetes/add-hyper-node.sh
```

## OVS

Install ovs ovn all-in-one:

```sh
curl http://feisky.xyz/ops/ovs/ovn-build-start.sh | bash
```

## Misc

Install golang:

```sh
misc/golang-install.sh
```
