#!/bin/sh
#
# Setup and install hyperd.
#
set -e

hyperd_install_ubuntu() {
    # install from https://docs.hypercontainer.io/get_started/install/linux.html
    curl -k -sSL https://hypercontainer.io/install | bash
    echo -e "Hypervisor=libvirt\n\
Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config
    # TODO: remove this after a stable hyperd is released.
    curl https://hypercontainer-install.s3.amazonaws.com/hypercontainer_0.8.0-1_amd64.deb -o hypercontainer.deb
    curl https://hypercontainer-install.s3.amazonaws.com/hyperstart_0.8.0-1_amd64.deb -o hyperstart.deb
    dpkg -i hyperstart.deb hypercontainer.deb
    rm -f hyperstart.deb hypercontainer.deb

    # TODO: remove this after a stable hyperd is released.
    hyperd_install_src

    systemctl enable hyperd
    systemctl restart hyperd
}

hyperd_install_centos() {
    # install from https://docs.hypercontainer.io/get_started/install/linux.html
    curl -k -sSL https://hypercontainer.io/install | bash
    echo -e "Hypervisor=libvirt\n\
Kernel=/var/lib/hyper/kernel\n\
Initrd=/var/lib/hyper/hyper-initrd.img\n\
Hypervisor=qemu\n\
StorageDriver=overlay\n\
gRPCHost=127.0.0.1:22318" > /etc/hyper/config

    # TODO: remove this after a stable hyperd is released.
    hyperd_install_src

    systemctl enable hyperd
    systemctl restart hyperd
}

hyperd_install_src() {
    mkdir -p $GOPATH/src/k8s.io $GOPATH/src/github.com/hyperhq
    git clone https://github.com/hyperhq/hyperstart $GOPATH/src/github.com/hyperhq/hyperstart
    git clone https://github.com/hyperhq/hyperd $GOPATH/src/github.com/hyperhq/hyperd
    cd $GOPATH/src/github.com/hyperhq/hyperstart
    ./autogen.sh && ./configure && make
    /bin/cp build/hyper-initrd.img /var/lib/hyper
    /bin/cp build/kernel /var/lib/hyper
    cd $GOPATH/src/github.com/hyperhq/hyperd
    ./autogen.sh && ./configure && make
    /bin/cp -f hyperd /usr/bin/hyperd
    /bin/cp -f hyperctl /usr/bin/hyperctl
    # sed -i -e '/unix_sock_rw_perms/d' -e '/unix_sock_admin_perms/d' -e '/clear_emulator_capabilities/d' \
    # -e '/unix_sock_group/d' -e '/auth_unix_ro/d' -e '/auth_unix_rw/d' /etc/libvirt/libvirtd.conf
    # echo unix_sock_rw_perms=\"0777\" >> /etc/libvirt/libvirtd.conf
    # echo unix_sock_admin_perms=\"0777\" >> /etc/libvirt/libvirtd.conf
    # echo unix_sock_group=\"root\" >> /etc/libvirt/libvirtd.conf
    # echo unix_sock_ro_perms=\"0777\" >> /etc/libvirt/libvirtd.conf
    # echo auth_unix_ro=\"none\" >> /etc/libvirt/libvirtd.conf
    # echo auth_unix_rw=\"none\" >> /etc/libvirt/libvirtd.conf
    # sed -i -e '/^clear_emulator_capabilities =/d' -e '/^user =/d' -e '/^group =/d' /etc/libvirt/qemu.conf
    # echo clear_emulator_capabilities=0 >> /etc/libvirt/qemu.conf
    # echo user=\"root\" >> /etc/libvirt/qemu.conf
    # echo group=\"root\" >> /etc/libvirt/qemu.conf
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

which go>/dev/null
if [[ $? != 0 ]]; then
    echo "Please install go from golang.org"
    exit 1
fi

lsb_dist="$(echo "$lsb_dist" | tr '[:upper:]' '[:lower:]')"
case "$lsb_dist" in

    ubuntu)
        hyperd_install_ubuntu
    ;;

    fedora|centos|redhat)
        hyperd_install_centos
    ;;

    *)
        echo "$lsb_dist is not supported (not in centos|ubuntu)"
    ;;

esac
