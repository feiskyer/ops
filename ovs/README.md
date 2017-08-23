# Open vSwitch

## Ubuntu Installation

Build deb:

```sh
apt-get install build-essential fakeroot -y
apt-get install graphviz autoconf automake debhelper dh-autoreconf libssl-dev libtool python-twisted-conch python-zopeinterface python-all -y
dpkg-checkbuilddeps
# If you have run the build before, ensure cleaning first.
# fakeroot debian/rules clean
DEB_BUILD_OPTIONS='parallel=8 nocheck' fakeroot debian/rules binary
```

Install:

```sh
apt-get install -y module-assistant dkms python-twisted-web build-essential
dpkg -i *.deb
```

## CentOS/REHL Installation

Build RPM:

```sh
make rpm-fedora RPMBUILD_OPT="--without check"
# with dpdk
# make rpm-fedora RPMBUILD_OPT="--with dpdk --without check"

make rpm-fedora-kmod
```

## Installation from source

Install pre-requisite:

```sh
apt-get install -y build-essential fakeroot debhelper \
                    autoconf automake bzip2 libssl-dev \
                    openssl graphviz python-all procps \
                    python-dev python-setuptools python-pip \
                    python-twisted-conch libtool git dh-autoreconf \
                    linux-headers-$(uname -r)
pip install -U pip
```

Get code and build

```sh
git clone https://github.com/openvswitch/ovs.git
cd ovs
./boot.sh
./configure --prefix=/usr --localstatedir=/var  --sysconfdir=/etc --enable-ssl --with-linux=/lib/modules/`uname -r`/build
make -j3

make install
make modules_install
pip install ovs
```

Configure kernel modules and start ovs

```sh
cat > /etc/depmod.d/openvswitch.conf << EOF
override openvswitch * extra
override vport-* * extra
EOF

depmod -a
cp debian/openvswitch-switch.init /etc/init.d/openvswitch-switch
/etc/init.d/openvswitch-switch force-reload-kmod
```
