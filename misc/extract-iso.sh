#!/bin/bash

if [ $# != 2 ]
then
	echo "Usage: $0 src.iso dstdir"
	exit 1
fi

src=$1
dst=$2

mount -o loop $src /mnt
/bin/cp -rf /mnt/* $dst
umount /mnt
