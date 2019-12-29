#!/bin/sh
GOVERSION=$(curl -sL https://golang.org/VERSION?m=text)
curl -sL https://storage.googleapis.com/golang/$GOVERSION.linux-amd64.tar.gz | sudo tar -C /usr/local -zxf -

echo 'export GOPATH=/go' >> ~/.bashrc
echo 'export PATH=$PATH:/usr/local/go/bin/:$GOPATH/bin' >> ~/.bashrc

echo 'Please run following commands to setup go:'
echo
echo '  export GOPATH=/go'
echo '  export PATH=$PATH:/usr/local/go/bin/:$GOPATH/bin'
echo
