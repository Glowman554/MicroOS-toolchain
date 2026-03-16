#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <toolchain> <bin> <opt>"
    exit 1
fi

TOOLCHAIN=$1
BIN=$2
OPT=$3


if [ ! -d "src" ]; then
    git clone https://github.com/phillbush/jvm src
    (
        cd src
        git am < ../0001-change-default-classpath.patch
    )
fi

(
    cd src

    make CC=$TOOLCHAIN/bin/i686-microos-gcc

    cd tests
    for test in *.java; do
        echo "Compiling $test..."
        javac -d . -source 8 -target 8 $test
    done
)


cp src/java $BIN
cp src/javap $BIN
cp src/tests/*.class $OPT