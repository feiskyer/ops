#!/bin/sh
# build, install and start ovn

download-ovs() {
  curl -o openvswitch-2.7.0.tar.gz http://openvswitch.org/releases/openvswitch-2.7.0.tar.gz
  tar zxvf openvswitch-2.7.0.tar.gz
  cd openvswitch-2.7.0
}

build-ubuntu() {
  apt-get update
  apt-get -y install build-essential fakeroot
  apt-get -y install graphviz autoconf automake bzip2 debhelper dh-autoreconf libssl-dev libtool openssl
  apt-get -y install procps python-all python-twisted-conch python-zopeinterface python-six

  dpkg-checkbuilddeps
  DEB_BUILD_OPTIONS='parallel=8 nocheck' fakeroot debian/rules binary

  # build modules
  cd ..
  apt-get -y install module-assistant
  dpkg -i openvswitch-datapath-source_2.7.0-1_all.deb
  m-a prepare
  m-a build openvswitch-datapath
  cp /usr/src/openvswitch-datapath-module-*.deb ./
}

build-centos() {
  make rpm-fedora RPMBUILD_OPT="--without check"
  make rpm-fedora-kmod
}

build-centos-dpdk() {
  make rpm-fedora RPMBUILD_OPT="--with dpdk --without check"
  make rpm-fedora-kmod
}

install-ubuntu() {
  apt-get -y install python-six python2.7
  dpkg -i openvswitch-datapath-module-*.deb
  dpkg -i openvswitch-common_2.7.0-1_amd64.deb openvswitch-switch_2.7.0-1_amd64.deb
  dpkg -i ovn-central_2.7.0-1_amd64.deb ovn-common_2.7.0-1_amd64.deb ovn-controller-vtep_2.7.0-1_amd64.deb ovn-docker_2.7.0-1_amd64.deb ovn-host_2.7.0-1_amd64.deb python-openvswitch_2.7.0-1_all.deb
}

start-ovs() {
  /usr/share/openvswitch/scripts/ovs-ctl start --system-id=random
}

start-ovn() {
  /usr/share/openvswitch/scripts/ovs-ctl start --system-id=random
  /usr/share/openvswitch/scripts/ovn-ctl start_northd
  /usr/share/openvswitch/scripts/ovn-ctl start_controller
  /usr/share/openvswitch/scripts/ovn-ctl start_controller_vtep
  export CENTRAL_IP=`hostname -I`
  export LOCAL_IP=${CENTRAL_IP}
  export ENCAP_TYPE=vxlan
  ovs-vsctl set Open_vSwitch . external_ids:ovn-remote="tcp:$CENTRAL_IP:6642" external_ids:ovn-nb="tcp:$CENTRAL_IP:6641" external_ids:ovn-encap-ip=$LOCAL_IP external_ids:ovn-encap-type="$ENCAP_TYPE"
  ovn-nbctl set-connection ptcp:6641
  ovn-sbctl set-connection ptcp:6642
}


download-ovs
build-ubuntu
install-ubuntu
start-ovn

