#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <toolchain> <bin> <opt>"
    exit 1
fi

TOOLCHAIN=$1
BIN=$2
OPT=$3


if [ ! -d "src" ]; then
    git clone https://github.com/lua/lua src
fi

(
    cd src

    make CC=$TOOLCHAIN/bin/i686-microos-gcc CFLAGS="-Wall -O2 \$(MYCFLAGS) -fno-stack-protector -fno-common" MYCFLAGS="-std=c99" MYLIBS="" -j$(nproc)
)


cp src/lua $BIN
cp hello-lua.lua $OPT