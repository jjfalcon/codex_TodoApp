@echo off
setlocal

set TEST_EXE=AppCoreTests.exe
set TEST_MAP=AppCoreTests.map
set COVERAGE_OUT=coverage
set COVERAGE_LOG=%COVERAGE_OUT%\coverage.log
set MIN_COVERAGE=90
set CODE_COVERAGE=%~dp0..\..\.tools\delphi-code-coverage\CodeCoverage.exe
for %%I in ("..\..\src\App.Core") do set CORE_SRC=%%~fI

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

dcc32 "-U..\..\src\App.Core" -GD AppCoreTests.dpr
if errorlevel 1 exit /b 1

"%CODE_COVERAGE%" ^
  -m "%TEST_MAP%" ^
  -e "%TEST_EXE%" ^
  -sp "%CORE_SRC%" ^
  -u AppCoreAbout AppCoreAuth AppCoreConfiguration AppCoreDiagnostics AppCoreLocalization AppCorePreferences AppCorePreferencesFileRepository AppCoreRepositoryFactory AppCoreTaskFileRepository AppCoreTaskItem AppCoreTaskRepository AppCoreTaskService AppCoreUpdate AppCoreUser AppCoreUserFileRepository AppCoreUserRepository AppCoreUserService ^
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

powershell -NoProfile -ExecutionPolicy Bypass -Command "$xml = [xml](Get-Content '%COVERAGE_OUT%\CodeCoverage_summary.xml'); $covered = [int]$xml.report.stats.coveredpercent.value; if ($covered -lt %MIN_COVERAGE%) { Write-Host ('Coverage threshold failed: ' + $covered + '%% < %MIN_COVERAGE%%%'); exit 1 } else { Write-Host ('Coverage threshold passed: ' + $covered + '%% >= %MIN_COVERAGE%%%') }"
if errorlevel 1 exit /b 1

exit /b 0
