#!/bin/bash

if [ $# != 1 ]; then
	echo "Usage: $0 path"
	exit 1
fi

path=$1
ip=`ifconfig eth0 | grep inet | sed -n '1p' | awk '{print $2}' | cut -d : -f 2` 

svnadmin create $1
echo "[general]
auth-access = write
password-db = passwd
anon-access = none

[sasl]" >$path/conf/svnserve.conf

echo "[users]
feisky=feisky" >$path/conf/passwd 

svnserve -d -r $path --listen-host $ip

echo "SVN address: svn://$ip"

exit 0
