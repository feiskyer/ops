#!/bin/bash
git clone https://github.com/kubernetes/kubernetes $GOPATH/src/k8s.io/kubernetes
cd $GOPATH/src/k8s.io/kubernetes
make WHAT='cmd/kubelet'

screen -dmS dockershim _output/bin/kubelet --v=3 --logtostderr --experimental-dockershim
