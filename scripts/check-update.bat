@echo off
setlocal

if "%~1"=="" (
  echo Usage: scripts\check-update.bat ^<manifest-url-or-path^> ^<current-version^> [download-dir]
  exit /b 2
)

if "%~2"=="" (
  echo Usage: scripts\check-update.bat ^<manifest-url-or-path^> ^<current-version^> [download-dir]
  exit /b 2
)

set DOWNLOAD_DIR=%~3
if "%DOWNLOAD_DIR%"=="" set DOWNLOAD_DIR=updates

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0check-update.ps1" -ManifestUrl "%~1" -CurrentVersion "%~2" -DownloadDir "%DOWNLOAD_DIR%"
exit /b %ERRORLEVEL%
