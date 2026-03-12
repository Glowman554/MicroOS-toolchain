#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
SRC_DIR="$SCRIPT_DIR/src"

echo "Cleaning toolchain..."

if [ -d "$BUILD_DIR" ]; then
    echo "Removing build directory: $BUILD_DIR"
    rm -rf "$BUILD_DIR"
fi

if [ -d "$SRC_DIR" ]; then
    echo "Removing source directory: $SRC_DIR"
    rm -rf "$SRC_DIR"
fi
