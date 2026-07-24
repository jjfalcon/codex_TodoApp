@echo off
setlocal

set ROOT=%~dp0..
set RELEASES=%ROOT%\releases
set TAG=%~1

if "%TAG%"=="" (
  echo Usage: scripts\publish-github-release.bat vX.Y.Z
  exit /b 1
)

where gh >nul 2>nul
if errorlevel 1 (
  echo GitHub CLI gh was not found. Install gh and authenticate with gh auth login.
  exit /b 2
)

for /f "delims=" %%i in ('powershell -NoProfile -Command "Get-ChildItem '%RELEASES%\TodoApp-*.zip' | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName"') do set ZIP_PATH=%%i

if "%ZIP_PATH%"=="" (
  echo Release ZIP was not found. Run scripts\release-windows.bat first.
  exit /b 1
)

for %%I in ("%ZIP_PATH%") do (
  set ZIP_NAME=%%~nxI
  set BASE_NAME=%%~nI
)

set HASH_PATH=%RELEASES%\%BASE_NAME%.sha256
set MANIFEST_PATH=%RELEASES%\%BASE_NAME%.json
set LATEST_PATH=%RELEASES%\latest.json

if not exist "%HASH_PATH%" (
  echo SHA256 file was not found: "%HASH_PATH%"
  exit /b 1
)

if not exist "%MANIFEST_PATH%" (
  echo Manifest file was not found: "%MANIFEST_PATH%"
  exit /b 1
)

if not exist "%LATEST_PATH%" (
  echo latest.json was not found: "%LATEST_PATH%"
  exit /b 1
)

gh release create "%TAG%" "%ZIP_PATH%" "%HASH_PATH%" "%MANIFEST_PATH%" "%LATEST_PATH%" --title "%TAG%" --notes "TodoApp Windows release %TAG%"
exit /b %ERRORLEVEL%
