unit AppCoreDiagnosticsTests;

interface

procedure RunDiagnosticsTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCoreDiagnostics;

type
  TTestProc = procedure;

procedure AssertContains(const AExpected, AActual, AMessage: string);
begin
  if Pos(AExpected, AActual) = 0 then
    raise Exception.Create(AMessage + ' Expected to contain "' + AExpected + '", got "' + AActual + '".');
end;

procedure AssertNotContains(const AUnexpected, AActual, AMessage: string);
begin
  if Pos(AUnexpected, AActual) > 0 then
    raise Exception.Create(AMessage + ' Did not expect "' + AUnexpected + '" in "' + AActual + '".');
end;

procedure RunTest(const AName: string; AProc: TTestProc; var AFailures: Integer);
begin
  try
    AProc;
    Writeln('[OK] ', AName);
  except
    on E: Exception do
    begin
      Inc(AFailures);
      Writeln('[FAIL] ', AName, ': ', E.Message);
    end;
  end;
end;

function TestLogFileName(const AName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(GetCurrentDir) + 'diagnostics-test\' +
    AName + '\application.log';
end;

function ReadFileText(const AFileName: string): string;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

procedure LoggerCreatesDirectoryAndWritesInfo;
var
  LLogger: IDiagnosticsLogger;
  LFileName: string;
  LText: string;
begin
  LFileName := TestLogFileName('info');
  LLogger := TFileDiagnosticsLogger.Create(LFileName);
  LLogger.Info('App.Start', 'Application started');
  LText := ReadFileText(LFileName);
  AssertContains('INFO App.Start Application started', LText,
    'Info log should include level, event and message.');
end;

procedure LoggerWritesTimingDuration;
var
  LLogger: IDiagnosticsLogger;
  LFileName: string;
  LText: string;
begin
  LFileName := TestLogFileName('timing');
  LLogger := TFileDiagnosticsLogger.Create(LFileName);
  LLogger.Timing('Task.Create', 'result=ok', 37);
  LText := ReadFileText(LFileName);
  AssertContains('TIMING Task.Create durationMs=37 result=ok', LText,
    'Timing log should include durationMs.');
end;

procedure LoggerSanitizesSensitiveValues;
var
  LLogger: IDiagnosticsLogger;
  LFileName: string;
  LText: string;
begin
  LFileName := TestLogFileName('sanitize');
  LLogger := TFileDiagnosticsLogger.Create(LFileName);
  LLogger.Error('Config.Load', 'password=secret token=abc connectionString=db');
  LText := ReadFileText(LFileName);
  AssertContains('password=[redacted]', LText, 'Password should be redacted.');
  AssertContains('token=[redacted]', LText, 'Token should be redacted.');
  AssertContains('connectionstring=[redacted]', LowerCase(LText),
    'Connection string should be redacted.');
  AssertNotContains('secret', LText, 'Secret value should not be written.');
  AssertNotContains('abc', LText, 'Token value should not be written.');
end;

procedure RunDiagnosticsTests(var AFailures: Integer);
begin
  RunTest('DiagnosticsLogger_writes_info', LoggerCreatesDirectoryAndWritesInfo, AFailures);
  RunTest('DiagnosticsLogger_writes_timing_duration', LoggerWritesTimingDuration, AFailures);
  RunTest('DiagnosticsLogger_sanitizes_sensitive_values', LoggerSanitizesSensitiveValues, AFailures);
end;

end.
