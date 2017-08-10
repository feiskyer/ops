#!/bin/sh
GOVERSION=1.8.3
curl -sL https://storage.googleapis.com/golang/go$GOVERSION.linux-amd64.tar.gz | tar -C /usr/local -zxf -

echo 'export GOPATH=/go' >> ~/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin/:$GOPATH/bin' >> ~/.bashrc

echo 'Please run following commands to setup go:'
echo
echo '  export GOPATH=/go'
echo '  export PATH=$PATH:/usr/local/go/bin/:$GOPATH/bin'
echo
