#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

cd $GOPATH/src/k8s.io/kubernetes
hack/install-etcd.sh
export PATH=$GOPATH/src/k8s.io/kubernetes/third_party/etcd:${PATH}
export KUBERNETES_PROVIDER=local
export CONTAINER_RUNTIME=remote
export CONTAINER_RUNTIME_ENDPOINT=/var/run/frakti.sock
hack/local-up-cluster.sh
