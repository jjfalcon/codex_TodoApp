@echo off
setlocal

set TEST_EXE=AppCoreTests.exe
set TEST_MAP=AppCoreTests.map
set COVERAGE_OUT=coverage
set COVERAGE_LOG=%COVERAGE_OUT%\coverage.log
for %%I in ("..\..\src\App.Core") do set CORE_SRC=%%~fI

where CodeCoverage.exe >nul 2>nul
if errorlevel 1 (
  echo CodeCoverage.exe was not found in PATH.
  echo Download DelphiCodeCoverage and add CodeCoverage.exe to PATH.
  exit /b 1
)

if exist "%COVERAGE_OUT%" rmdir /s /q "%COVERAGE_OUT%"
mkdir "%COVERAGE_OUT%"

dcc32 "-U..\..\src\App.Core" -GD AppCoreTests.dpr
if errorlevel 1 exit /b 1

CodeCoverage ^
  -m "%TEST_MAP%" ^
  -e "%TEST_EXE%" ^
  -sp "%CORE_SRC%" ^
  -u AppCoreAbout AppCoreAuth AppCoreConfiguration AppCorePreferences AppCorePreferencesFileRepository AppCoreRepositoryFactory AppCoreTaskFileRepository AppCoreTaskItem AppCoreTaskRepository AppCoreTaskService AppCoreUser AppCoreUserFileRepository AppCoreUserRepository AppCoreUserService ^
  -od "%COVERAGE_OUT%" ^
  -html ^
  -xml ^
  -tec > "%COVERAGE_LOG%"

type "%COVERAGE_LOG%"

if not exist "%COVERAGE_OUT%\CodeCoverage_summary.html" (
  echo Coverage report was not generated.
  exit /b 1
)

findstr /C:"test(s) failed." "%COVERAGE_LOG%" >nul
if not errorlevel 1 exit /b 1

exit /b 0
