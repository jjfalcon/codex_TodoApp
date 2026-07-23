@echo off
setlocal

set ROOT=%~dp0..
set TARGET=%ROOT%\src\App.Core\AppCoreBuildInfo.pas
set VERSION_MAJOR=1
set VERSION_MINOR=0
set VERSION_PATCH=0

for /f %%i in ('git -C "%ROOT%" rev-list --count HEAD') do set COMMIT_COUNT=%%i
for /f %%i in ('git -C "%ROOT%" rev-parse --short HEAD') do set COMMIT_HASH=%%i

if "%COMMIT_COUNT%"=="" (
  echo Could not determine Git commit count.
  exit /b 1
)

if "%COMMIT_HASH%"=="" (
  echo Could not determine Git commit hash.
  exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set BUILD_DATE=%%i
if "%BUILD_DATE%"=="" set BUILD_DATE=No disponible
set VERSION=%VERSION_MAJOR%.%VERSION_MINOR%.%VERSION_PATCH%.%COMMIT_COUNT%

(
  echo unit AppCoreBuildInfo;
  echo.
  echo interface
  echo.
  echo const
  echo   AppBuildMajor = '%VERSION_MAJOR%';
  echo   AppBuildMinor = '%VERSION_MINOR%';
  echo   AppBuildPatch = '%VERSION_PATCH%';
  echo   AppBuildCommitCount = '%COMMIT_COUNT%';
  echo   AppBuildVersion = '%VERSION%';
  echo   AppBuildCommitHash = '%COMMIT_HASH%';
  echo   AppBuildDate = '%BUILD_DATE%';
  echo.
  echo implementation
  echo.
  echo end.
) > "%TARGET%"

echo Generated %TARGET% with version %VERSION% and commit %COMMIT_HASH%.
exit /b 0
