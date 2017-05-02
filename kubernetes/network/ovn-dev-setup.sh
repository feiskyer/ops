#!/bin/bash
curdir=$(dirname "${BASH_SOURCE}")

apt-get update
apt-get install -y vim build-essential git iproute2 net-tools

# install ovs with ovn
$curdir/../../ovs/packages/ubuntu-xenial/install.sh

# install golang
$curdir/../../misc/golang-install.sh
go get -u github.com/kardianos/govendor

