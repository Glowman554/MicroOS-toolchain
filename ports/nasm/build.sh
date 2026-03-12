#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <toolchain> <bin> <opt>"
    exit 1
fi

TOOLCHAIN=$1
BIN=$2
OPT=$3


if [ ! -d "src" ]; then
    git clone https://github.com/netwide-assembler/nasm src
fi

(
    cd src

    ./autogen.sh
    
    CC=$TOOLCHAIN/bin/i686-microos-gcc ./configure --host=i686-elf --build=i686-pc-linux-gnu

    make -j$(nproc)
)


cp src/nasm $BIN
cp src/ndisasm $BIN

cp hello-nasm.asm $OPT