FROM ubuntu:latest

MAINTAINER Pengfei Ni

ENV GOVERSION "1.8.3"
ENV GOPATH "/go"
ENV PATH "/go/bin:/usr/local/go/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN apt-get update && \
    apt-get install -y build-essential qemu autoconf automake pkg-config libdevmapper-dev curl && \
    apt-get install -y libsqlite3-dev aufs-tools wget libaio1 libpixman-1-0 && \
    apt-get install -y dpkg-dev dh-make debhelper libvirt-dev cpio git && \
    curl -sL https://storage.googleapis.com/golang/go${GOVERSION}.linux-amd64.tar.gz | tar -C /usr/local -zxf - && \
    apt-get clean

VOLUME ["/data"]
COPY run.sh /

CMD ["/run.sh"]
