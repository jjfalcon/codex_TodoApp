@echo off
setlocal

set ROOT=%~dp0..
set APP_DIR=%ROOT%\src\App.Win
set BUILD_INFO=%ROOT%\src\App.Core\AppCoreBuildInfo.pas
set BUILD_INFO_TEMPLATE=%ROOT%\src\App.Core\AppCoreBuildInfo.template.pas

call "%ROOT%\scripts\generate-build-info.bat"
if errorlevel 1 exit /b 1

pushd "%APP_DIR%"
dcc32 "-U..\App.Core" -B WindowsApp.dpr
set BUILD_RESULT=%ERRORLEVEL%
popd

copy /Y "%BUILD_INFO_TEMPLATE%" "%BUILD_INFO%" >nul
exit /b %BUILD_RESULT%
