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

call "%ROOT%\scripts\generate-build-info.bat"
if errorlevel 1 exit /b 1

pushd "%APP_DIR%"
dcc32 "-U..\App.Core" WindowsApp.dpr
set COMPILE_RESULT=%ERRORLEVEL%
popd
copy /Y "%ROOT%\src\App.Core\AppCoreBuildInfo.template.pas" "%ROOT%\src\App.Core\AppCoreBuildInfo.pas" >nul
if not "%COMPILE_RESULT%"=="0" exit /b 1

if exist "%RUNTIME%" rmdir /s /q "%RUNTIME%"
mkdir "%RUNTIME%"
mkdir "%DIAGNOSTICS%"

copy /Y "%APP_DIR%\WindowsApp.exe" "%RUNTIME%\WindowsApp.exe" >nul
copy /Y "%APP_DIR%\app.config" "%RUNTIME%\app.config" >nul
copy /Y "%APP_DIR%\languages.csv" "%RUNTIME%\languages.csv" >nul

"%AUTOIT%" "%~dp0smoke_login.au3" "%RUNTIME%\WindowsApp.exe" "%RUNTIME%" "%DIAGNOSTICS%"
set E2E_RESULT=%ERRORLEVEL%
if not "%E2E_RESULT%"=="0" exit /b %E2E_RESULT%

if not exist "%RUNTIME%\logs\application.log" (
  echo Diagnostics log was not generated.
  exit /b 30
)

findstr /C:"INFO App.Start" "%RUNTIME%\logs\application.log" >nul
if errorlevel 1 (
  echo App.Start was not written to diagnostics log.
  exit /b 31
)

findstr /C:"TIMING Auth.Login" "%RUNTIME%\logs\application.log" >nul
if errorlevel 1 (
  echo Auth.Login timing was not written to diagnostics log.
  exit /b 32
)

exit /b 0
