#!/bin/sh

if test "$CONDA_BUILD_CROSS_COMPILATION" = "1"
then
  CMAKE_ARGS="${CMAKE_ARGS} -DQT_HOST_PATH=${BUILD_PREFIX}"

  # native gn
  CC=$CC_FOR_BUILD CXX=$CXX_FOR_BUILD CFLAGS= CXXFLAGS= CPPFLAGS= LDFLAGS=${LDFLAGS//$PREFIX/$BUILD_PREFIX} \
    cmake -G "Ninja" -DCMAKE_PREFIX_PATH=$BUILD_PREFIX -DCMAKE_INSTALL_PREFIX=$PWD/build_native_gn/install -B build_native_gn src/gn
  cmake --build build_native_gn --target install
  CMAKE_ARGS="${CMAKE_ARGS} -DGn_EXECUTABLE=$PWD/build_native_gn/install/bin/gn"
fi

cmake -LAH -G "Ninja" ${CMAKE_ARGS} \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_FIND_FRAMEWORK=LAST \
  -DCMAKE_INSTALL_RPATH:STRING=${PREFIX}/lib \
  -DCMAKE_MESSAGE_LOG_LEVEL=STATUS \
  -DPython3_EXECUTABLE=${BUILD_PREFIX}/bin/python \
  -DFEATURE_webengine_system_ffmpeg=ON \
  -DFEATURE_webengine_system_icu=ON \
  -DFEATURE_webengine_system_zlib=OFF \
  -DFEATURE_webengine_system_icu=ON \
  -DFEATURE_webengine_system_re2=ON \
  -DFEATURE_webengine_system_pulseaudio=OFF \
  -DFEATURE_webengine_vaapi=OFF \
  -DFEATURE_qtpdf_build=OFF \
  -DFEATURE_qtwebengine_widgets_build=OFF \
  -B build .
cmake --build build --target install

test -f ${PREFIX}/lib/libQt6WebEngine${SHLIB_EXT}
