@echo off
setlocal

set TEST_EXE=AppWinTests.exe
set TEST_MAP=AppWinTests.map
set COVERAGE_OUT=coverage
set COVERAGE_LOG=%COVERAGE_OUT%\coverage.log
set CODE_COVERAGE=%~dp0..\..\.tools\delphi-code-coverage\CodeCoverage.exe
for %%I in ("..\..\src\App.Win") do set WIN_SRC=%%~fI

if not exist "%CODE_COVERAGE%" (
  where CodeCoverage.exe >nul 2>nul
  if errorlevel 1 (
    echo CodeCoverage.exe was not found in .tools or PATH.
    exit /b 1
  )
  set CODE_COVERAGE=CodeCoverage.exe
)

if exist "%COVERAGE_OUT%" rmdir /s /q "%COVERAGE_OUT%"
mkdir "%COVERAGE_OUT%"

dcc32 "-U..\..\src\App.Win;..\..\src\App.Core" -GD AppWinTests.dpr
if errorlevel 1 exit /b 1

"%CODE_COVERAGE%" ^
  -m "%TEST_MAP%" ^
  -e "%TEST_EXE%" ^
  -sp "%WIN_SRC%" ^
  -u LoginForm AppWinLocalization ^
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
