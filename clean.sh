#!/bin/bash

function clean() {
    echo "Cleaning $1..."
    (
        cd ports/$1
        bash clean.sh
    )
}


(
    clean nasm
    clean mujs
    clean lua
    clean flc
)

rm -rf output