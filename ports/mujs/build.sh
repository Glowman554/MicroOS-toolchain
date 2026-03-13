#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <toolchain> <bin> <opt>"
    exit 1
fi

TOOLCHAIN=$1
BIN=$2
OPT=$3


if [ ! -d "src" ]; then
    git clone https://github.com/ArtifexSoftware/mujs src
fi

(
    cd src

    make HAVE_READLINE=no CC=$TOOLCHAIN/bin/i686-microos-gcc
)


cp src/build/debug/mujs $BIN
cp src/build/debug/mujs-pp $BIN
cp hello-mujs.js $OPT
