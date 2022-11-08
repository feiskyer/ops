#!/bin/bash

apt-get update
apt-get install -y lsb-release

# Install libraries
code=$(lsb_release -s -c)
case "$code" in

    bionic)
        apt install -y bison build-essential cmake clang llvm flex \
            git libedit-dev llvm-dev libclang-dev  zlib1g-dev \
            libelf-dev libfl-dev pkg-config \
            linux-tools-$(uname -r) binutils-dev
    ;;

    *)
        apt install -y bison build-essential cmake flex git \
            libedit-dev zlib1g-dev libelf-dev libfl-dev \
            python3-distutils linux-tools-$(uname -r) \
            libncurses-dev bison libssl-dev dwarves \
            libcap-dev binutils-dev
    ;;

esac

# Build and Install libbpf
git clone https://github.com/libbpf/libbpf
cd libbpf/src && make && make install

# Install bpftool
# tip: use https://github.com/libbpf/bpftool/issues/17#issuecomment-1092393579 if it build fails
git clone https://github.com/libbpf/bpftool --recurse-submodules
cd bpftool/src && make && make install
