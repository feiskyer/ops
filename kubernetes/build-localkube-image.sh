#!/bin/bash
apt-get update && apt-get install build-essential -y

git clone https://github.com/kubernetes/minikube.git $GOPATH/src/k8s.io/minikube
cd $GOPATH/src/k8s.io/minikube
make

make localkube-image REGISTRY=feisky

