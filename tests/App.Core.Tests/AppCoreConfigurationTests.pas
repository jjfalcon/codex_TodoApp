unit AppCoreConfigurationTests;

interface

procedure RunConfigurationTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCoreConfiguration;

procedure AssertEquals(const AExpected, AActual: string; const AMessage: string); overload;
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

const
  LTestConfigFile = 'test_app_config.ini';

procedure DefaultsWhenFileDoesNotExist;
var
  LConfig: TAppConfiguration;
begin
  DeleteFile(LTestConfigFile);
  LConfig := TAppConfiguration.Create(LTestConfigFile);
  try
    AssertEquals('json', LConfig.Backend, 'Default backend should be json.');
    AssertEquals('.', LConfig.DataPath, 'Default dataPath should be ".".');
    AssertEquals('', LConfig.ConnectionString, 'Default connectionString should be "".');
  finally
    LConfig.Free;
  end;
  DeleteFile(LTestConfigFile);
end;

procedure ReadsJsonBackend;
var
  LConfig: TAppConfiguration;
  LFile: TStringList;
begin
  DeleteFile(LTestConfigFile);
  LFile := TStringList.Create;
  try
    LFile.Add('[Persistence]');
    LFile.Add('Backend=json');
    LFile.SaveToFile(LTestConfigFile);
  finally
    LFile.Free;
  end;

  LConfig := TAppConfiguration.Create(LTestConfigFile);
  try
    AssertEquals('json', LConfig.Backend, 'Should read json backend.');
  finally
    LConfig.Free;
  end;
  DeleteFile(LTestConfigFile);
end;

procedure ReadsDataPath;
var
  LConfig: TAppConfiguration;
  LFile: TStringList;
begin
  DeleteFile(LTestConfigFile);
  LFile := TStringList.Create;
  try
    LFile.Add('[Persistence]');
    LFile.Add('DataPath=C:\data\');
    LFile.SaveToFile(LTestConfigFile);
  finally
    LFile.Free;
  end;

  LConfig := TAppConfiguration.Create(LTestConfigFile);
  try
    AssertEquals('C:\data\', LConfig.DataPath, 'Should read dataPath.');
  finally
    LConfig.Free;
  end;
  DeleteFile(LTestConfigFile);
end;

procedure ReadsConnectionString;
var
  LConfig: TAppConfiguration;
  LFile: TStringList;
begin
  DeleteFile(LTestConfigFile);
  LFile := TStringList.Create;
  try
    LFile.Add('[Persistence]');
    LFile.Add('ConnectionString=server=localhost;db=todo');
    LFile.SaveToFile(LTestConfigFile);
  finally
    LFile.Free;
  end;

  LConfig := TAppConfiguration.Create(LTestConfigFile);
  try
    AssertEquals('server=localhost;db=todo', LConfig.ConnectionString, 'Should read connectionString.');
  finally
    LConfig.Free;
  end;
  DeleteFile(LTestConfigFile);
end;

procedure RunConfigurationTests(var AFailures: Integer);
begin
  RunTest('Defaults_when_file_does_not_exist', DefaultsWhenFileDoesNotExist, AFailures);
  RunTest('Reads_json_backend', ReadsJsonBackend, AFailures);
  RunTest('Reads_dataPath', ReadsDataPath, AFailures);
  RunTest('Reads_connectionString', ReadsConnectionString, AFailures);
end;

end.
