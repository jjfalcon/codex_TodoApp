unit AppWinUpdateCheckerTests;

interface

procedure RunAppWinUpdateCheckerTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  Windows,
  AppWinUpdateChecker;

type
  TTestProc = procedure;

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

procedure AssertContains(const AExpectedText, AActual, AMessage: string);
begin
  if Pos(AExpectedText, AActual) = 0 then
    raise Exception.Create(AMessage + ' Expected to find "' + AExpectedText +
      '" in "' + AActual + '".');
end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
end;

function TestDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
    'update-checker-test';
end;

procedure SaveTextFile(const AFileName, AText: string);
var
  LText: TStringList;
begin
  LText := TStringList.Create;
  try
    LText.Text := AText;
    LText.SaveToFile(AFileName);
  finally
    LText.Free;
  end;
end;

procedure EnsureCleanDirectory(const ADirectory: string);
begin
  if DirectoryExists(ADirectory) then
  begin
    SysUtils.DeleteFile(IncludeTrailingPathDelimiter(ADirectory) + 'app.config');
    SysUtils.DeleteFile(IncludeTrailingPathDelimiter(ADirectory) + 'app.default.config');
    SysUtils.DeleteFile(IncludeTrailingPathDelimiter(ADirectory) + 'latest.json');
    SysUtils.DeleteFile(IncludeTrailingPathDelimiter(ADirectory) + 'TodoApp-test.zip');
    SysUtils.DeleteFile(IncludeTrailingPathDelimiter(ADirectory) + 'downloads\TodoApp-test.zip');
    RemoveDir(IncludeTrailingPathDelimiter(ADirectory) + 'downloads');
    RemoveDir(ADirectory);
  end;
  ForceDirectories(ADirectory);
end;

procedure AboutUpdateCheckerUsesDefaultConfigWhenLocalConfigHasNoUpdates;
var
  LDirectory: string;
  LPackageFileName: string;
  LHash: string;
  LChecker: TAboutUpdateChecker;
begin
  LDirectory := TestDirectory;
  EnsureCleanDirectory(LDirectory);
  try
    SaveTextFile(IncludeTrailingPathDelimiter(LDirectory) + 'app.config',
      '[Localization]' + #13#10 +
      'Language=es' + #13#10);

    LPackageFileName := IncludeTrailingPathDelimiter(LDirectory) + 'TodoApp-test.zip';
    SaveTextFile(LPackageFileName, 'zip-content');
    LHash := TWindowsSha256Calculator.Create.Sha256File(LPackageFileName);

    SaveTextFile(IncludeTrailingPathDelimiter(LDirectory) + 'latest.json',
      '{' + #13#10 +
      '  "version": "9.9.9.9",' + #13#10 +
      '  "package": "TodoApp-test.zip",' + #13#10 +
      '  "sha256": "' + LHash + '"' + #13#10 +
      '}');

    SaveTextFile(IncludeTrailingPathDelimiter(LDirectory) + 'app.default.config',
      '[Updates]' + #13#10 +
      'Enabled=true' + #13#10 +
      'ManifestUrl=' + IncludeTrailingPathDelimiter(LDirectory) + 'latest.json' + #13#10 +
      'DownloadDir=' + IncludeTrailingPathDelimiter(LDirectory) + 'downloads' + #13#10);

    LChecker := TAboutUpdateChecker.CreateForTests(
      IncludeTrailingPathDelimiter(LDirectory) + 'app.config', False);
    try
      AssertContains('descargada y verificada', LChecker.CheckForUpdate.MessageText,
        'Checker should read app.default.config when app.config has no Updates section.');
    finally
      LChecker.Free;
    end;
  finally
    EnsureCleanDirectory(LDirectory);
    RemoveDir(LDirectory);
  end;
end;

procedure WindowsUpdateApplierBuildsExternalApplyScript;
var
  LApplier: TWindowsUpdateApplier;
  LScript: string;
begin
  LApplier := TWindowsUpdateApplier.Create('C:\TodoApp\', 'C:\TodoApp\WindowsApp.exe', 1234);
  try
    LScript := LApplier.BuildApplyScript('C:\Downloads\TodoApp.zip');

    AssertContains('tasklist /FI "PID eq %PID%"', LScript,
      'Apply script should wait until the current app exits.');
    AssertContains('Expand-Archive', LScript,
      'Apply script should extract the verified ZIP.');
    AssertContains('xcopy "%STAGING%\*" "%TARGET%" /E /I /Y', LScript,
      'Apply script should copy extracted files to the app directory.');
    AssertContains('start "" "%EXE%"', LScript,
      'Apply script should relaunch the application.');
    AssertTrue(Pos('set "PACKAGE=C:\Downloads\TodoApp.zip"', LScript) > 0,
      'Apply script should target the verified package file.');
  finally
    LApplier.Free;
  end;
end;

procedure RunAppWinUpdateCheckerTests(var AFailures: Integer);
begin
  RunTest('AboutUpdateChecker_uses_default_config_when_local_config_has_no_updates',
    AboutUpdateCheckerUsesDefaultConfigWhenLocalConfigHasNoUpdates, AFailures);
  RunTest('WindowsUpdateApplier_builds_external_apply_script',
    WindowsUpdateApplierBuildsExternalApplyScript, AFailures);
end;

end.
