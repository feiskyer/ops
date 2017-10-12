#!/bin/bash
# Install openvswitch via source code or rpms/debs.

OVS_VERSION=${OVS_VERSION:-"stable"}

ovs-install-centos() {
  yum install centos-release-openstack-pike
  yum install -y openvswitch openvswitch-ovn-*
  systemctl enable openvswitch
  systemctl start openvswitch
}

ovs-install-centos-latest() {
  wget -O /etc/yum.repos.d/ovs-master.repo https://copr.fedorainfracloud.org/coprs/leifmadsen/ovs-master/repo/epel-7/leifmadsen-ovs-master-epel-7.repo
  yum install openvswitch openvswitch-ovn-*
}

ovs-install-ubuntu() {
  # Don't install ubuntu hosted packages because they are old.
	# apt-get install -y openvswitch-switch ovn-central ovn-common ovn-host
  apt-get install apt-transport-https
  echo "deb https://packages.wand.net.nz $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/wand.list
  curl https://packages.wand.net.nz/keyring.gpg -o /etc/apt/trusted.gpg.d/wand.gpg
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
  apt-get update
  apt-get -y build-dep dkms
  apt-get install python-six openssl python-pip -y
  pip install --upgrade pip
  apt-get install openvswitch-datapath-dkms -y
  apt-get install openvswitch-switch openvswitch-common -y
  pip install ovs

  # on the master, also install
  apt-get install ovn-central ovn-common -y

  # on the node, also install
  apt-get install ovn-host ovn-common -y
}

ovs-install-ubuntu-latest() {
    apt-get install -y build-essential fakeroot debhelper \
                    autoconf automake bzip2 libssl-dev \
                    openssl graphviz python-all procps \
                    python-dev python-setuptools python-pip \
                    python-twisted-conch libtool git dh-autoreconf \
                    linux-headers-$(uname -r)
    pip install -U pip
    
    #Get code and build
    git clone https://github.com/openvswitch/ovs.git
    cd ovs
    ./boot.sh
    ./configure --prefix=/usr --localstatedir=/var  --sysconfdir=/etc --enable-ssl --with-linux=/lib/modules/`uname -r`/build
    make -j3

    make install
    make modules_install
    pip install ovs

    #Configure kernel modules and start ovs
    cat > /etc/depmod.d/openvswitch.conf << EOF
override openvswitch * extra
override vport-* * extra
EOF

    depmod -a
    cp debian/openvswitch-switch.init /etc/init.d/openvswitch-switch
    /etc/init.d/openvswitch-switch force-reload-kmod
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
        if [ "$OVS_VERSION" = "latest" ]; then
            ovs-install-centos-latest
        else
            ovs-install-centos
        fi
    ;;

    fedora|centos|redhat)
        if [ "$OVS_VERSION" = "latest" ]; then
            ovs-install-ubuntu-latest
        else
            ovs-install-ubuntu
        fi
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
