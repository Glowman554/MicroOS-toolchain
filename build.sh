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
        bash build.sh $TOOLCHAIN $BIN $OPT
    )
}


(
    build nasm
    build mujs
    build lua
    build flc
)