unit AppCoreAboutServiceTests;

interface

procedure RunAboutServiceTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCoreAbout,
  AppCoreBuildInfo;

procedure AssertEquals(const AExpected, AActual: string; const AMessage: string);
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure RunTest(const AName: string; AProc: TProcedure; var AFailures: Integer);
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

function CreateFullInfo: TAboutInfo;
begin
  Result.ApplicationName := 'Test App';
  Result.Version := '2.0.0';
  Result.Description := 'Test description.';
  Result.Copyright := 'Test Copyright 2026';
  Result.ExecutableVersion := '2.0.0.1';
  Result.CommitHash := 'abc1234';
  Result.OperatingSystem := 'Windows 10';
  Result.Architecture := 'x64';
  Result.BuildDate := '2026-06-09';
  Result.DatabasePath := 'C:\data\test.db';
end;

procedure AboutInfoReturnsApplicationName;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LService := TAboutService.Create(CreateFullInfo);
  LInfo := LService.GetAboutInfo;
  AssertEquals('Test App', LInfo.ApplicationName, 'Should return application name.');
end;

procedure AboutInfoReturnsApplicationVersion;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LService := TAboutService.Create(CreateFullInfo);
  LInfo := LService.GetAboutInfo;
  AssertEquals('2.0.0', LInfo.Version, 'Should return application version.');
end;

procedure AboutInfoReturnsDescription;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LService := TAboutService.Create(CreateFullInfo);
  LInfo := LService.GetAboutInfo;
  AssertEquals('Test description.', LInfo.Description, 'Should return description.');
end;

procedure AboutInfoReturnsCopyright;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LService := TAboutService.Create(CreateFullInfo);
  LInfo := LService.GetAboutInfo;
  AssertEquals('Test Copyright 2026', LInfo.Copyright, 'Should return copyright.');
end;

procedure AboutInfoReturnsNotAvailableForMissingOptionalData;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LInfo := CreateFullInfo;
  LInfo.ExecutableVersion := '';
  LInfo.CommitHash := '';
  LInfo.Architecture := '';
  LInfo.BuildDate := '';
  LInfo.DatabasePath := '';
  LService := TAboutService.Create(LInfo);
  LInfo := LService.GetAboutInfo;
  AssertEquals('No disponible', LInfo.ExecutableVersion, 'Missing executable version should show No disponible.');
  AssertEquals('No disponible', LInfo.CommitHash, 'Missing commit hash should show No disponible.');
  AssertEquals('No disponible', LInfo.Architecture, 'Missing architecture should show No disponible.');
  AssertEquals('No disponible', LInfo.BuildDate, 'Missing build date should show No disponible.');
  AssertEquals('No disponible', LInfo.DatabasePath, 'Missing database path should show No disponible.');
end;

procedure AboutInfoReturnsGeneratedBuildVersion;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LService := TAboutService.Create;
  LInfo := LService.GetAboutInfo;
  AssertEquals(AppBuildVersion, LInfo.Version,
    'Default version should include Git commit count as fourth value.');
  AssertEquals(AppBuildVersion, LInfo.ExecutableVersion,
    'Executable version should match generated application version.');
end;

procedure AboutInfoReturnsGeneratedCommitHash;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LService := TAboutService.Create;
  LInfo := LService.GetAboutInfo;
  AssertEquals(AppBuildCommitHash, LInfo.CommitHash,
    'Default about info should expose short Git commit hash.');
end;

procedure AboutInfoDoesNotExposeSensitiveConnectionData;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LInfo := CreateFullInfo;
  LInfo.DatabasePath := 'host=prod;password=secret123;db=mydb';
  LService := TAboutService.Create(LInfo);
  LInfo := LService.GetAboutInfo;
  AssertEquals('No disponible', LInfo.DatabasePath,
    'Sensitive connection data should be sanitized.');
end;

procedure AboutInfoCanBeLoadedWithoutActiveBusinessChanges;
var
  LInfo: TAboutInfo;
  LService: IAboutService;
begin
  LInfo := CreateFullInfo;
  LService := TAboutService.Create(LInfo);
  LInfo := LService.GetAboutInfo;
  AssertEquals('Test App', LInfo.ApplicationName,
    'About info should be loaded without side effects.');
end;

procedure RunAboutServiceTests(var AFailures: Integer);
begin
  RunTest('AboutInfo_returns_application_name', AboutInfoReturnsApplicationName, AFailures);
  RunTest('AboutInfo_returns_application_version', AboutInfoReturnsApplicationVersion, AFailures);
  RunTest('AboutInfo_returns_description', AboutInfoReturnsDescription, AFailures);
  RunTest('AboutInfo_returns_copyright', AboutInfoReturnsCopyright, AFailures);
  RunTest('AboutInfo_returns_not_available_for_missing_optional_data', AboutInfoReturnsNotAvailableForMissingOptionalData, AFailures);
  RunTest('AboutInfo_returns_generated_build_version', AboutInfoReturnsGeneratedBuildVersion, AFailures);
  RunTest('AboutInfo_returns_generated_commit_hash', AboutInfoReturnsGeneratedCommitHash, AFailures);
  RunTest('AboutInfo_does_not_expose_sensitive_connection_data', AboutInfoDoesNotExposeSensitiveConnectionData, AFailures);
  RunTest('AboutInfo_can_be_loaded_without_active_business_changes', AboutInfoCanBeLoadedWithoutActiveBusinessChanges, AFailures);
end;

end.
