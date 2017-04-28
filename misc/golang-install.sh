#!/bin/sh
GOVERSION=1.8.1
curl -sL https://storage.googleapis.com/golang/go$GOVERSION.linux-amd64.tar.gz | tar -C /usr/local -zxf -
echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/local/go/bin/:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/go/bin"' >> /etc/environment
echo 'GOPATH="/go"' >> /etc/environment

echo 'Please run following commands to setup go:'
echo
echo '  export GOPATH=/go'
echo '  export PATH=$PATH:/usr/local/go/bin/:$GOPATH/bin'
echo
