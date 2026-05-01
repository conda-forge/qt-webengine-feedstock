#!/bin/bash

set -e

# Run smoke test on all Linux architectures
pushd test

# Ensure make can find a compiler.
ln -s ${GXX} g++
export PATH=${PWD}:${PATH}

# Keep QMake from trying to detect the SDK in the wrong place in CI.
export QT_MAC_SDK_NO_VERSION_CHECK=1

qmake6 -Wall -Wparser qtwebengine.pro
make

popd