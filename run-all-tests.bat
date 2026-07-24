@echo off
setlocal

call :RunStep "Core unit and coverage" "tests\App.Core.Tests" "coverage.bat"
if errorlevel 1 exit /b 1

call :RunStep "App.Win unit and coverage" "tests\App.Win.Tests" "coverage.bat"
if errorlevel 1 exit /b 1

call :RunStep "Visual tests" "tests\App.Win.Visual" "run-visual-tests.bat verify"
if errorlevel 1 exit /b 1

call :RunStep "E2E smoke" "tests\App.Win.E2E" "run-smoke-login.bat"
if errorlevel 1 exit /b 1

if /I "%~1"=="mutation" (
  call :RunStep "Mutation tests" "tests\App.Core.Tests" "mutation.bat"
  if errorlevel 1 exit /b 1
) else (
  echo Skipping mutation tests. Run run-all-tests.bat mutation to include them.
)

echo All requested checks passed.
exit /b 0

:RunStep
echo.
echo === %~1 ===
pushd "%~dp0%~2"
call %~3
set STEP_RESULT=%ERRORLEVEL%
popd
if not "%STEP_RESULT%"=="0" (
  echo Step failed: %~1
  exit /b %STEP_RESULT%
)
exit /b 0
