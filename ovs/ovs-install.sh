#!/bin/bash

ovs-install-centos() {
  yum install centos-release-openstack-newton
  yum install openvswitch
  systemctl enable openvswitch
  systemctl start openvswitch
}

ovs-install-centos-latest() {
  wget -o /etc/yum.repos.d/ovs-master.repo https://copr.fedorainfracloud.org/coprs/leifmadsen/ovs-master/repo/epel-7/leifmadsen-ovs-master-epel-7.repo
  yum install openvswitch openvswitch-ovn-*
}

ovs-install-ubuntu() {
	apt-get install -y openvswitch-switch ovn-central ovn-common ovn-controller-vtep ovn-docker ovn-host
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
        ovs-install-ubuntu
    ;;

    fedora|centos|redhat)
        ovs-install-centos-latest
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
