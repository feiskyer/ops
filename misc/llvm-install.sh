#!/bin/bash
# Install LLVM 12 (Ubuntu 18.04)
wget https://apt.llvm.org/llvm.sh
chmod +x llvm.sh && sudo ./llvm.sh 12 all

# Default clang version to 12
ln -s /usr/bin/llvm-strip-12 /usr/bin/llvm-strip
ln -s /usr/bin/clang-12 /usr/bin/clang
ln -s /usr/bin/clang++-12 /usr/bin/clang++
