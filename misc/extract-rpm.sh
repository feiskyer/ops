#!/bin/bash

if [ $# != 1 ]
then
	echo "Usage: $0 filename.rpm"
	exit 1
fi

src=$1
rpm2cpio $src | cpio -div
