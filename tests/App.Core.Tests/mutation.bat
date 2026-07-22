@echo off
setlocal EnableExtensions EnableDelayedExpansion

set TEST_EXE=AppCoreTests.exe
set MUTATIONS_DIR=mutations
set REPORT=mutation-report.txt
set BASELINE_LOG=mutation-baseline.log
set HAD_ERROR=0

for /f "usebackq delims=" %%R in (`git rev-parse --show-toplevel`) do set REPO_ROOT=%%R

if not "%MUTATION_ALLOW_DIRTY%"=="1" (
  git diff --quiet
  if errorlevel 1 (
    echo Working tree has unstaged changes. Commit or stash them before mutation testing.
    exit /b 1
  )

  git diff --cached --quiet
  if errorlevel 1 (
    echo Working tree has staged changes. Commit or unstage them before mutation testing.
    exit /b 1
  )
)

if not exist "%MUTATIONS_DIR%\*.patch" (
  echo No mutation patches found in %MUTATIONS_DIR%.
  exit /b 1
)

echo Running baseline tests...
call :compile
if errorlevel 1 exit /b 1

"%TEST_EXE%" < nul > "%BASELINE_LOG%"
if errorlevel 1 (
  type "%BASELINE_LOG%"
  echo Baseline tests must pass before mutation testing.
  exit /b 1
)

echo Mutation testing report > "%REPORT%"
echo ======================= >> "%REPORT%"
echo. >> "%REPORT%"

set TOTAL=0
set KILLED=0
set SURVIVED=0

for %%M in ("%MUTATIONS_DIR%\*.patch") do (
  call :run_mutation "%%~fM"
  if errorlevel 1 set HAD_ERROR=1
)

echo. >> "%REPORT%"
echo Summary: !TOTAL! tested, !KILLED! killed, !SURVIVED! survived. >> "%REPORT%"
type "%REPORT%"

if not "!SURVIVED!"=="0" exit /b 1
if not "!HAD_ERROR!"=="0" exit /b 1
exit /b 0

:compile
dcc32 "-U..\..\src\App.Core" -B AppCoreTests.dpr > nul
exit /b %errorlevel%

:run_mutation
set PATCH=%~1
set NAME=%~n1
set LOG=mutation-%NAME%.log
set RESULT=SURVIVED

set /a TOTAL+=1
echo Running %NAME%...

pushd "%REPO_ROOT%" > nul
git apply "%PATCH%"
set APPLY_ERROR=%errorlevel%
popd > nul
if not "%APPLY_ERROR%"=="0" (
  echo %NAME%: APPLY_FAILED >> "%REPORT%"
  set /a SURVIVED+=1
  exit /b 1
)

call :compile
if errorlevel 1 (
  set RESULT=KILLED
  echo Compile failed. > "%LOG%"
) else (
  "%TEST_EXE%" < nul > "%LOG%"
  if errorlevel 1 set RESULT=KILLED
)

pushd "%REPO_ROOT%" > nul
git apply -R "%PATCH%"
set RESTORE_ERROR=%errorlevel%
popd > nul
if not "%RESTORE_ERROR%"=="0" (
  echo %NAME%: RESTORE_FAILED >> "%REPORT%"
  set /a SURVIVED+=1
  exit /b 1
)

if "!RESULT!"=="KILLED" (
  set /a KILLED+=1
) else (
  set /a SURVIVED+=1
)

echo %NAME%: !RESULT! >> "%REPORT%"
exit /b 0
