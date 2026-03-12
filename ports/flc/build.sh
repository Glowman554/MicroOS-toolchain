#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <toolchain> <bin> <opt>"
    exit 1
fi

TOOLCHAIN=$1
BIN=$2
OPT=$3


if [ ! -d "src" ]; then
    git clone https://github.com/Glowman554/FireStorm src
fi

(
    cd src/flc

    make CC=$TOOLCHAIN/bin/i686-microos-gcc
)


cp src/flc/flc $BIN
cp hello-fl.fl $OPT