@echo off
setlocal

set ROOT=%~dp0..\..
set RELEASES=%ROOT%\releases
set RUNTIME=%~dp0runtime-release
set DIAGNOSTICS=%RUNTIME%\diagnostics
set AUTOIT=%ROOT%\.tools\autoit\install\AutoIt3.exe
set ZIP_PATH=%~1

if not exist "%AUTOIT%" (
  echo AutoIt portable was not found at "%AUTOIT%".
  exit /b 2
)

if "%ZIP_PATH%"=="" (
  for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-ChildItem '%RELEASES%\TodoApp-*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName"') do set ZIP_PATH=%%i
)

if "%ZIP_PATH%"=="" (
  echo Release ZIP was not found. Run scripts\release-windows.bat first or pass a ZIP path.
  exit /b 1
)

if not exist "%ZIP_PATH%" (
  echo Release ZIP does not exist: "%ZIP_PATH%"
  exit /b 1
)

if exist "%RUNTIME%" rmdir /s /q "%RUNTIME%"
mkdir "%RUNTIME%"
mkdir "%DIAGNOSTICS%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_PATH%' -DestinationPath '%RUNTIME%' -Force"
if errorlevel 1 exit /b 1

if not exist "%RUNTIME%\WindowsApp.exe" (
  echo WindowsApp.exe was not found in release ZIP.
  exit /b 1
)

if not exist "%RUNTIME%\app.config" (
  echo app.config was not found in release ZIP.
  exit /b 1
)

if not exist "%RUNTIME%\languages.csv" (
  echo languages.csv was not found in release ZIP.
  exit /b 1
)

if not exist "%RUNTIME%\sqlite3.dll" (
  echo sqlite3.dll was not found in release ZIP.
  exit /b 1
)

"%AUTOIT%" "%~dp0smoke_login.au3" "%RUNTIME%\WindowsApp.exe" "%RUNTIME%" "%DIAGNOSTICS%"
set E2E_RESULT=%ERRORLEVEL%
if not "%E2E_RESULT%"=="0" exit /b %E2E_RESULT%

echo Release smoke passed: %ZIP_PATH%
exit /b 0
