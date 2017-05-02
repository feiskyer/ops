#!/bin/bash
version=1.4.21
source=(ftp://ftp.netfilter.org/pub/iptables/iptables-$version.tar.bz2) 

mkdir /tmp/iptables-$version
cd /tmp/iptables-$version
PKG="$(pwd)/pkg"

if [ -d $PKG ]; then
    mkdir -p $PKG
fi

if [ ! -d iptables-$version ]; then
    curl -q -L -O $source
    tar xvf iptables-$version.*tar*
fi

cd iptables-$version

./configure \
    --prefix=/usr \
    --mandir=/usr/man \
    --disable-shared \
    --enable-static

export CFLAGS='-static'
export LDFLAGS='-static -dl'

make
make DESTDIR=$PKG install

ldd $PKG/usr/sbin/xtables-multi
cd ..

