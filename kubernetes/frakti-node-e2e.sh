#!/bin/bash
cd $GOPATH/src/k8s.io/kubernetes
make test-e2e-node PARALLELISM=2 TEST_ARGS='--kubelet-flags="--container-runtime=remote --container-runtime-endpoint=/var/run/frakti.sock --feature-gates=AllAlpha=true,Accelerators=false"' FOCUS="\[Conformance\]"

