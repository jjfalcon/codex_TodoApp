@echo off
setlocal

set ROOT=%~dp0..\..
set APP_DIR=%ROOT%\src\App.Win
set RUNTIME=%~dp0runtime
set DIAGNOSTICS=%RUNTIME%\diagnostics
set AUTOIT=%ROOT%\.tools\autoit\install\AutoIt3.exe

if not exist "%AUTOIT%" (
  echo AutoIt portable was not found at "%AUTOIT%".
  exit /b 2
)

pushd "%APP_DIR%"
dcc32 "-U..\App.Core" WindowsApp.dpr
if errorlevel 1 (
  popd
  exit /b 1
)
popd

if exist "%RUNTIME%" rmdir /s /q "%RUNTIME%"
mkdir "%RUNTIME%"
mkdir "%DIAGNOSTICS%"

copy /Y "%APP_DIR%\WindowsApp.exe" "%RUNTIME%\WindowsApp.exe" >nul
copy /Y "%APP_DIR%\app.config" "%RUNTIME%\app.config" >nul
copy /Y "%APP_DIR%\languages.csv" "%RUNTIME%\languages.csv" >nul

"%AUTOIT%" "%~dp0smoke_login.au3" "%RUNTIME%\WindowsApp.exe" "%RUNTIME%" "%DIAGNOSTICS%"
exit /b %ERRORLEVEL%
