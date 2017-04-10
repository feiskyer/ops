#!/bin/bash
if [ $# != 1 ]
then
	echo "Usage: $0 process"
	exit 1
fi

process=$1
p=`ps -e | grep $process | awk '{print $1}'`
if [ -z $p ]
then
	echo "Process $process doesn't exist"
	exit 1
fi

echo "Sub threads:"
ps mp $p -o THREAD,tid
echo "Sub process:"
pstree -p $p
