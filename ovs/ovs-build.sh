#!/bin/sh
# build openvswitch packages (rpm or deb).

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
  yum install -y rpm-build autoconf automake libtool systemd-units openssl openssl-devel
  yum install -y python-devel python-twisted-core python-zope-interface python-six desktop-file-utils
  yum install -y groff graphviz procps-ng checkpolicy selinux-policy-devel libcap-ng-devel
  rpm -ivh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm
  yum install -y python3-devel kernel-devel
  ./boot.sh && ./configure --prefix=/usr --localstatedir=/var --sysconfdir=/etc
  make rpm-fedora RPMBUILD_OPT="--without check"
  make rpm-fedora-kmod
}

build-centos-dpdk() {
  make rpm-fedora RPMBUILD_OPT="--with dpdk --without check"
  make rpm-fedora-kmod
}

lsb_dist=''
if command_exists lsb_release; then
    lsb_dist="$(lsb_release -si)"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/lsb-release ]; then
    lsb_dist="$(. /etc/lsb-release && echo "$DISTRIB_ID")"
fi
if [ -z "$lsb_dist" ] && [ -r /etc/centos-release ]; then
    lsb_dist='centos'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/redhat-release ]; then
    lsb_dist='redhat'
fi
if [ -z "$lsb_dist" ] && [ -r /etc/os-release ]; then
    lsb_dist="$(. /etc/os-release && echo "$ID")"
fi

lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
case "$lsb_dist" in

    ubuntu)
        download-ovs
        build-ubuntu
    ;;

    fedora|centos|redhat)
        download-ovs
        build-centos
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
