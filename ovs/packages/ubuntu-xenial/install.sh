#!/bin/sh
curdir=$(dirname "${BASH_SOURCE}")
apt-get update
apt-get -y install python-six python2.7

dpkg -i $curdir/openvswitch-datapath-module-*.deb
dpkg -i $curdir/openvswitch-common_2.7.0-1_amd64.deb $curdir/openvswitch-switch_2.7.0-1_amd64.deb
dpkg -i $curdir/ovn-central_2.7.0-1_amd64.deb $curdir/ovn-common_2.7.0-1_amd64.deb $curdir/ovn-controller-vtep_2.7.0-1_amd64.deb $curdir/ovn-docker_2.7.0-1_amd64.deb $curdir/ovn-host_2.7.0-1_amd64.deb $curdir/python-openvswitch_2.7.0-1_all.deb

