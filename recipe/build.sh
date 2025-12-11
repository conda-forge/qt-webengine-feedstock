#! /usr/bin/env bash

set -xeuo pipefail

syncqt.pl -version ${PKG_VERSION}

mkdir qtwebengine-build
pushd qtwebengine-build

USED_BUILD_PREFIX=${BUILD_PREFIX:-${PREFIX}}
echo USED_BUILD_PREFIX=${BUILD_PREFIX}

# qtwebengine needs python 2
if [[ $(uname) == "Darwin" && $(arch) == "arm64" ]]; then
    export PATH="$(pyenv root)/shims:${PATH}"
else
    mamba create --yes --prefix "${SRC_DIR}/python2_hack" --channel conda-forge --no-deps python=2
    export PATH=${SRC_DIR}/python2_hack/bin:${PATH}
fi

if [[ $(uname) == "Linux" ]]; then
    ln -s ${GXX} g++ || true
    ln -s ${GCC} gcc || true
    ln -s ${USED_BUILD_PREFIX}/bin/${HOST}-gcc-ar gcc-ar || true

    export LD=${GXX}
    export CC=${GCC}
    export CXX=${GXX}

    chmod +x g++ gcc gcc-ar
    export PATH=$PREFIX/bin:${PWD}:${PATH}

    which pkg-config
    export PKG_CONFIG_EXECUTABLE=$(which pkg-config)
    export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig/:$BUILD_PREFIX/lib/pkgconfig/

    # Set QMake prefix to $PREFIX
    qmake -set prefix $PREFIX

    qmake QMAKE_LIBDIR=${PREFIX}/lib \
        QMAKE_LFLAGS+="-Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib" \
        INCLUDEPATH+="${PREFIX}/include" \
        PKG_CONFIG_EXECUTABLE=$(which pkg-config) \
        ..

    # Cleanup before final version
    # https://github.com/conda-forge/qt-webengine-feedstock/pull/15#issuecomment-1336593298
    pushd "${PREFIX}/lib"
    for f in *.prl; do
        sed -i "s,\$.CONDA_BUILD_SYSROOT),${CONDA_BUILD_SYSROOT},g" ${f};
    done
    popd

    pushd "${PREFIX}/mkspecs"
    for f in *.pri; do
        sed -i "s,\$.CONDA_BUILD_SYSROOT),${CONDA_BUILD_SYSROOT},g" ${f}
    done
    popd

    pushd
    cd "${PREFIX}/mkspecs/modules"
    for f in *.pri; do
        sed -i "s,\$.CONDA_BUILD_SYSROOT),${CONDA_BUILD_SYSROOT},g" ${f}
    done
    popd

    CPATH=$PREFIX/include:$BUILD_PREFIX/src/core/api make -j$CPU_COUNT \
        | sed "s,.SRC_DIR/qtwebengine-build/g++,g++," \
        | sed "s,^g++.*-o,g++ [...] -o," || true
    #           ^    use a comma instead of a / to avoid escape sequences

    # Parallel making will ultimately fail, so we do it to retain somewhat
    # reasonable build times, but fall back to a single-threaded make to finish
    # the job.
    CPATH=$PREFIX/include:$BUILD_PREFIX/src/core/api make -j1 \
        | sed "s,.SRC_DIR/qtwebengine-build/g++,g++," \
        | sed "s,^g++.*-o,g++ [...] -o,"
    #           ^    use a comma instead of a / to avoid escape sequences

    make install
fi

if [[ $(uname) == "Darwin" ]]; then
    # Let Qt set its own flags and vars
    unset OSX_ARCH CFLAGS CXXFLAGS LDFLAGS

    # Qt passes clang flags to LD (e.g. -stdlib=c++)
    export LD=${CXX}

    # Use xcode-avoidance scripts provided by qt-main so that the build can
    # run with just the command-line tools, and not full XCode, installed.
    export PATH=$PREFIX/bin/xc-avoidance:$PATH

    # However, the Chromium build process uses absolute paths to the macOS
    # build configuration tools (e.g., `/usr/bin/xcodebuild`), so the xcode-avoidance
    # scripts don't work for that piece of the build. Instead we need
    # to patch the build configuration to make sure that it builds against the
    # desired SDK, so that the binary rpaths are correct.
    pushd ../src/3rdparty/chromium/build/config/mac
    awk 'NR==77{$0="    rebase_path(\"'$CONDA_BUILD_SYSROOT'\", root_build_dir),"}1' BUILD.gn >BUILD.gn.tmp
    mv -f BUILD.gn.tmp BUILD.gn
    popd

    export APPLICATION_EXTENSION_API_ONLY=NO

    EXTRA_FLAGS=""
    if [[ $(arch) == "arm64" ]]; then
      EXTRA_FLAGS="QMAKE_APPLE_DEVICE_ARCHS=arm64"
    fi

    if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" == "1" ]]; then
      # The python2_hack does not know about _sysconfigdata_arm64_apple_darwin20_0_0, so unset the data name
      unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
    fi

    # Set QMake prefix to $PREFIX
    qmake -set prefix $PREFIX

    # sed -i '' -e 's/-Werror//' $PREFIX/mkspecs/features/qt_module_headers.prf

    qmake QMAKE_LIBDIR=${PREFIX}/lib \
        INCLUDEPATH+="${PREFIX}/include" \
        CONFIG+="warn_off" \
        QMAKE_CFLAGS_WARN_ON="-w" \
        QMAKE_CXXFLAGS_WARN_ON="-w" \
        QMAKE_CFLAGS+="-Wno-everything" \
        QMAKE_CXXFLAGS+="-Wno-everything" \
        $EXTRA_FLAGS \
        QMAKE_LFLAGS+="-Wno-everything -Wl,-rpath,$PREFIX/lib -L$PREFIX/lib" \
        PKG_CONFIG_EXECUTABLE=$(which pkg-config) \
        ..

    # find . -type f -exec sed -i '' -e 's/-Wl,-fatal_warnings//g' {} +
    # sed -i '' -e 's/-Werror//' $PREFIX/mkspecs/features/qt_module_headers.prf

    make -j$CPU_COUNT
    make install
fi

# Post build setup
# ----------------
# Remove static libraries that are not part of the Qt SDK.
pushd "${PREFIX}"/lib > /dev/null
    find . -name "*.a" -and -not -name "libQt*" -exec rm -f {} \;
popd > /dev/null
