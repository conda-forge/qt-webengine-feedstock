@echo on

cmake -LAH -G "Ninja" ^
    %CMAKE_ARGS% ^
    -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
    -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
    -DCMAKE_UNITY_BUILD=ON ^
    -DCMAKE_UNITY_BUILD_BATCH_SIZE=32 ^
    -DCMAKE_MESSAGE_LOG_LEVEL=STATUS ^
    -DGPerf_EXECUTABLE=%BUILD_PREFIX%\Library\usr\bin\gperf.exe ^
    -DBISON_EXECUTABLE=%BUILD_PREFIX%\Library\bin\win_bison.exe ^
    -DFLEX_EXECUTABLE=%BUILD_PREFIX%\Library\bin\win_flex.exe ^
    -DFEATURE_webengine_build_gn=OFF ^
    -DFEATURE_webengine_system_libevent=ON ^
    -DFEATURE_webengine_system_icu=ON ^
    -DFEATURE_qtpdf_build=OFF ^
    -DFEATURE_webengine_jumbo_file_merge_limit=16 ^
    -B build .
if errorlevel 1 exit 1

cmake --build build --target install --config Release
if errorlevel 1 exit 1

:: unversioned exes must avoid clobbering the qt5 packages, but versioned dlls still need to be in PATH
xcopy /y /s %LIBRARY_PREFIX%\lib\qt6\bin\*.dll %LIBRARY_PREFIX%\bin
if errorlevel 1 exit 1
