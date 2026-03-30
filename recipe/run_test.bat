pushd test

if exist .qmake.stash del /a .qmake.stash
if %ErrorLevel% neq 0 exit /b %ErrorLevel%

:: Only test that this builds
qmake6 qtwebengine.pro
if %ErrorLevel% neq 0 exit /b %ErrorLevel%

nmake
if %ErrorLevel% neq 0 exit /b %ErrorLevel%

popd
