apt-get install dpkg-dev 
cmd=`which $1`
pac=`dpkg -S $cmd`
pacname=`echo $pac | awk -F: '{print $1}'`
apt-get source $pacname
