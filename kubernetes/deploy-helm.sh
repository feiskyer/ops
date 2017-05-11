#!/bin/bash

HELM_VERSION="v2.4.1"
KUBERNTES_ROOT=$(dirname "${BASH_SOURCE}")

curl -sSL https://storage.googleapis.com/kubernetes-helm/helm-${HELM_VERSION}-linux-amd64.tar.gz -o helm-linux-amd64.tar.gz
tar zxvf helm-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/
rm -rf helm-linux-amd64.tar.gz linux-amd64

# init helm
kubectl create -f $KUBERNTES_ROOT/helm-admin.yaml
helm init

# update repo
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo update

