# Devops

Tools&scripts for daily devops.

**Contents**

- Container/docker management
- Kubernetes deployment&management
- Networking experiments
- Vagrant tools

## Kubernetes

### Install kubernetes all-in-one

```sh
curl http://feisky.xyz/ops/kubernetes/setup_kubernetes.sh | bash
```

### Install kubernetes all-in-one with frakti

Install latest stable version:

```sh
curl -sSL https://github.com/kubernetes/frakti/raw/master/cluster/allinone.sh | bash
```

Install from source code:
 
```sh
curl http://feisky.xyz/ops/kubernetes/setup_kubernetes_frakti.sh | bash
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
