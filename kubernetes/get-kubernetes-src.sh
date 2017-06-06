#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if [ "$GOPATH" = "" ]; then
    echo "Please setup GOPATH first."
    exit
fi

git clone https://github.com/kubernetes/kubernetes $GOPATH/src/k8s.io/kubernetes

