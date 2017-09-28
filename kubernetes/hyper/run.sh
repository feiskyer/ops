#!/bin/bash
# download and build hyper deb packages.
set -e
set -u

# download latest code
git clone https://github.com/hyperhq/hyperd $GOPATH/src/github.com/hyperhq/hyperd
git clone https://github.com/hyperhq/hyperstart $GOPATH/src/github.com/hyperhq/hyperstart

# build
cd $GOPATH/src/github.com/hyperhq/hyperd/package/ubuntu
./make-deb.sh

# copy deb out
cp ./hypercontainer/*.deb ./hyperstart/*.deb /data

echo "Build hyper deb success."
