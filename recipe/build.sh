#!/bin/sh

if test "$CONDA_BUILD_CROSS_COMPILATION" = "1"
then
  CMAKE_ARGS="${CMAKE_ARGS} -DQT_HOST_PATH=${BUILD_PREFIX}"
fi

cmake -LAH -G "Ninja" ${CMAKE_ARGS} \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_FIND_FRAMEWORK=LAST \
  -DCMAKE_INSTALL_RPATH:STRING=${PREFIX}/lib \
  -DCMAKE_MESSAGE_LOG_LEVEL=STATUS \
  -DPython3_EXECUTABLE=${BUILD_PREFIX}/bin/python \
  -DFEATURE_webengine_system_ffmpeg=ON \
  -DFEATURE_webengine_system_libevent=ON \
  -DFEATURE_webengine_system_icu=ON \
  -DFEATURE_webengine_system_zlib=OFF \
  -DFEATURE_webengine_system_icu=ON \
  -DFEATURE_webengine_system_re2=ON \
  -DFEATURE_qtpdf_build=OFF \
  -DFEATURE_qtwebengine_widgets_build=OFF \
  -DFEATURE_webengine_system_pulseaudio=OFF \
  -DFEATURE_webengine_jumbo_file_merge_limit=16 \
  -B build .
cmake --build build --target install
