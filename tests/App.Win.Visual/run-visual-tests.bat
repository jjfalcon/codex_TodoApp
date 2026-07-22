@echo off
setlocal

set MODE=%1
if "%MODE%"=="" set MODE=verify

pushd "%~dp0"
dcc32 "-U..\..\src\App.Win;..\..\src\App.Core" AppWinVisualTests.dpr
if errorlevel 1 (
  popd
  exit /b 1
)

AppWinVisualTests.exe %MODE%
set RESULT=%ERRORLEVEL%
popd
exit /b %RESULT%
