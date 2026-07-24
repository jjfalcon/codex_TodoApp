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
set LATEST_PATH=%RELEASE_ROOT%\latest.json
set SQLITE_DLL=

for /f "delims=" %%i in ('where sqlite3.dll 2^>nul') do if not defined SQLITE_DLL set SQLITE_DLL=%%i

if "%SQLITE_DLL%"=="" (
  echo sqlite3.dll was not found in PATH. Install or expose SQLite runtime before building a release.
  exit /b 1
)

call "%ROOT%\scripts\build-windows.bat"
if errorlevel 1 exit /b 1

if exist "%STAGING%" rmdir /s /q "%STAGING%"
mkdir "%PACKAGE_DIR%"
if errorlevel 1 exit /b 1

copy /Y "%APP_DIR%\WindowsApp.exe" "%PACKAGE_DIR%\WindowsApp.exe" >nul
if errorlevel 1 exit /b 1

copy /Y "%APP_DIR%\languages.csv" "%PACKAGE_DIR%\languages.csv" >nul
if errorlevel 1 exit /b 1

copy /Y "%APP_DIR%\app.default.config" "%PACKAGE_DIR%\app.config" >nul
if errorlevel 1 exit /b 1

copy /Y "%SQLITE_DLL%" "%PACKAGE_DIR%\sqlite3.dll" >nul
if errorlevel 1 exit /b 1

if exist "%ZIP_PATH%" del "%ZIP_PATH%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%PACKAGE_DIR%\*' -DestinationPath '%ZIP_PATH%' -Force"
if errorlevel 1 exit /b 1

powershell -NoProfile -ExecutionPolicy Bypass -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $zip = [System.IO.Compression.ZipFile]::OpenRead('%ZIP_PATH%'); try { $names = @($zip.Entries | ForEach-Object { $_.FullName }); foreach ($required in @('WindowsApp.exe','languages.csv','app.config','sqlite3.dll')) { if ($names -notcontains $required) { Write-Host ('Missing release entry: ' + $required); exit 1 } } } finally { $zip.Dispose() }"
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
  echo   "publishedAt": "%BUILD_DATE%",
  echo   "package": "%PACKAGE_NAME%.zip",
  echo   "sha256": "%SHA256%"
  echo }
) > "%MANIFEST_PATH%"

(
  echo {
  echo   "version": "%VERSION%",
  echo   "commit": "%COMMIT_HASH%",
  echo   "buildDate": "%BUILD_DATE%",
  echo   "publishedAt": "%BUILD_DATE%",
  echo   "package": "%PACKAGE_NAME%.zip",
  echo   "sha256": "%SHA256%"
  echo }
) > "%LATEST_PATH%"

for /f "tokens=1" %%i in ('certutil -hashfile "%ZIP_PATH%" SHA256 ^| findstr /R /V "hash CertUtil"') do set VERIFY_SHA256=%%i
if not "%VERIFY_SHA256%"=="%SHA256%" (
  echo Release hash verification failed.
  exit /b 1
)

copy /Y "%BUILD_INFO_TEMPLATE%" "%BUILD_INFO%" >nul

echo Release package: %ZIP_PATH%
echo SHA256: %SHA256%
echo Manifest: %MANIFEST_PATH%
echo Latest manifest: %LATEST_PATH%
echo Release validation passed.
exit /b 0
