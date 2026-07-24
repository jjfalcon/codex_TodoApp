@echo off
setlocal EnableDelayedExpansion

set ROOT=%~dp0..
set APP_DIR=%ROOT%\src\App.Win
set RELEASE_ROOT=%ROOT%\releases
set STAGING=%RELEASE_ROOT%\staging
set BUILD_INFO=%ROOT%\src\App.Core\AppCoreBuildInfo.pas
set BUILD_INFO_TEMPLATE=%ROOT%\src\App.Core\AppCoreBuildInfo.template.pas

for /f %%i in ('git -C "%ROOT%" rev-list --count HEAD') do set COMMIT_COUNT=%%i
for /f %%i in ('git -C "%ROOT%" rev-parse --short HEAD') do set COMMIT_HASH=%%i
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set BUILD_DATE=%%i

if "%COMMIT_COUNT%"=="" (
  echo Could not determine Git commit count.
  exit /b 1
)

if "%COMMIT_HASH%"=="" (
  echo Could not determine Git commit hash.
  exit /b 1
)

set VERSION=1.0.0.%COMMIT_COUNT%
set PACKAGE_NAME=TodoApp-%VERSION%-%COMMIT_HASH%
set PACKAGE_DIR=%STAGING%\%PACKAGE_NAME%
set ZIP_PATH=%RELEASE_ROOT%\%PACKAGE_NAME%.zip
set HASH_PATH=%RELEASE_ROOT%\%PACKAGE_NAME%.sha256
set MANIFEST_PATH=%RELEASE_ROOT%\%PACKAGE_NAME%.json

call "%ROOT%\scripts\build-windows.bat"
if errorlevel 1 exit /b 1

if exist "%STAGING%" rmdir /s /q "%STAGING%"
mkdir "%PACKAGE_DIR%"
if errorlevel 1 exit /b 1

copy /Y "%APP_DIR%\WindowsApp.exe" "%PACKAGE_DIR%\WindowsApp.exe" >nul
if errorlevel 1 exit /b 1

copy /Y "%APP_DIR%\languages.csv" "%PACKAGE_DIR%\languages.csv" >nul
if errorlevel 1 exit /b 1

(
  echo [Persistence]
  echo Backend=json
  echo DataPath=.
  echo.
  echo [Localization]
  echo Language=es
  echo File=languages.csv
  echo ConnectionString=
  echo.
  echo [Login]
  echo LastUsername=
  echo.
  echo [Main]
  echo LastOption=Dashboard
) > "%PACKAGE_DIR%\app.config"

if exist "%ZIP_PATH%" del "%ZIP_PATH%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%PACKAGE_DIR%\*' -DestinationPath '%ZIP_PATH%' -Force"
if errorlevel 1 exit /b 1

for /f "tokens=1" %%i in ('certutil -hashfile "%ZIP_PATH%" SHA256 ^| findstr /R /V "hash CertUtil"') do set SHA256=%%i
if "%SHA256%"=="" (
  echo Could not calculate SHA256.
  exit /b 1
)

echo %SHA256%  %PACKAGE_NAME%.zip> "%HASH_PATH%"

(
  echo {
  echo   "version": "%VERSION%",
  echo   "commit": "%COMMIT_HASH%",
  echo   "buildDate": "%BUILD_DATE%",
  echo   "package": "%PACKAGE_NAME%.zip",
  echo   "sha256": "%SHA256%"
  echo }
) > "%MANIFEST_PATH%"

copy /Y "%BUILD_INFO_TEMPLATE%" "%BUILD_INFO%" >nul

echo Release package: %ZIP_PATH%
echo SHA256: %SHA256%
echo Manifest: %MANIFEST_PATH%
exit /b 0
