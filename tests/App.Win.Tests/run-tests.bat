@echo off
setlocal

pushd "%~dp0"
dcc32 "-U..\..\src\App.Win;..\..\src\App.Core" AppWinTests.dpr
if errorlevel 1 (
  popd
  exit /b 1
)

AppWinTests.exe
set RESULT=%ERRORLEVEL%
popd
exit /b %RESULT%
