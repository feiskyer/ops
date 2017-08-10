# Open vSwitch

## Build deb

```sh
apt-get install build-essential fakeroot
dpkg-checkbuilddeps
# 已经编译过，需要首先clean
# fakeroot debian/rules clean
DEB_BUILD_OPTIONS='parallel=8 nocheck' fakeroot debian/rules binary
```

## Build RPM

```sh
make rpm-fedora RPMBUILD_OPT="--without check"
# with dpdk
# make rpm-fedora RPMBUILD_OPT="--with dpdk --without check"

make rpm-fedora-kmod
```
