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

### Install kubernetes

```sh
./kubernetes/setup_kubernetes.sh
```

### Install kubernetes with frakti

Install latest stable version:

```sh
./kubernetes/setupp_kubernetes_frakti.sh
```

### Add a node

```sh
# replace this with yours.
export TOKEN="xxxx"
export MASTER_IP="x.x.x.x"
export CONTAINER_CIDR="10.244.x.0/24"

# Install kubernetes and add it to cluster.
./kubernetes/add_node.sh
```

## OVS

Install ovs ovn all-in-one:

```sh
curl http://feisky.xyz/ops/ovs/ovn-build-start.sh | bash
```

## Misc

Install golang:

```sh
curl http://feisky.xyz/ops/misc/golang-install.sh | bash
```
