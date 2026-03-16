#!/bin/bash

TOOLCHAIN=.toolchain
TOOLCHAIN=$(realpath $TOOLCHAIN)

if [ ! -d "output" ]; then
    mkdir output/opt/bin -p
fi

BIN=$(realpath output/opt/bin)
OPT=$(realpath output/opt)

function build() {
    echo "Building $1..."
    (
        cd ports/$1
        OPT_LOCAL=$(realpath $OPT/$1)
        mkdir -p $OPT_LOCAL
        bash build.sh $TOOLCHAIN $BIN $OPT_LOCAL
    )
}


(
    build nasm
    build mujs
    build lua
    build flc
    build jvm
)