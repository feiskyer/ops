#!/bin/bash
# Install cri-containerd.

git clone https://github.com/kubernetes-incubator/cri-containerd $GOPATH/src/github.com/kubernetes-incubator/cri-containerd
cd $GOPATH/src/github.com/kubernetes-incubator/cri-containerd
hack/install-deps.sh 
make 
sudo make install

sudo cp contrib/systemd-units/* /lib/systemd/system/
sudo systemctl daemon-reload

sudo systemctl start containerd
sudo systemctl start cri-containerd
sudo systemctl enable containerd
sudo systemctl enable cri-containerd

