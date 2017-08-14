# Open vSwitch

## Ubuntu

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

## CentOS/REHL

Build RPM:

```sh
make rpm-fedora RPMBUILD_OPT="--without check"
# with dpdk
# make rpm-fedora RPMBUILD_OPT="--with dpdk --without check"

make rpm-fedora-kmod
```

