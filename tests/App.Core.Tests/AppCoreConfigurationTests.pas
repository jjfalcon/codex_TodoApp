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
    AssertEquals('es', LConfig.Language, 'Default language should be es.');
    AssertEquals('languages.csv', LConfig.LanguageFile, 'Default language file should be languages.csv.');
    AssertEquals('false', LowerCase(BoolToStr(LConfig.UpdatesEnabled, True)), 'Updates should be disabled by default.');
    AssertEquals('', LConfig.UpdateManifestUrl, 'Default update manifest URL should be empty.');
    AssertEquals('updates', LConfig.UpdateDownloadDir, 'Default update download dir should be updates.');
    AssertEquals('todoapp.db', LConfig.DatabaseFile, 'Default database file should be todoapp.db.');
  finally
    LConfig.Free;
  end;
  DeleteFile(LTestConfigFile);
end;

procedure ReadsDatabaseFile;
var
  LConfig: TAppConfiguration;
  LFile: TStringList;
begin
  DeleteFile(LTestConfigFile);
  LFile := TStringList.Create;
  try
    LFile.Add('[Persistence]');
    LFile.Add('Backend=sqlite');
    LFile.Add('DatabaseFile=local\todo.db');
    LFile.SaveToFile(LTestConfigFile);
  finally
    LFile.Free;
  end;

  LConfig := TAppConfiguration.Create(LTestConfigFile);
  try
    AssertEquals('sqlite', LConfig.Backend, 'Should read sqlite backend.');
    AssertEquals('local\todo.db', LConfig.DatabaseFile, 'Should read database file.');
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

procedure ReadsLocalizationSettings;
var
  LConfig: TAppConfiguration;
  LFile: TStringList;
begin
  DeleteFile(LTestConfigFile);
  LFile := TStringList.Create;
  try
    LFile.Add('[Localization]');
    LFile.Add('Language=en');
    LFile.Add('File=i18n.csv');
    LFile.SaveToFile(LTestConfigFile);
  finally
    LFile.Free;
  end;

  LConfig := TAppConfiguration.Create(LTestConfigFile);
  try
    AssertEquals('en', LConfig.Language, 'Should read selected language.');
    AssertEquals('i18n.csv', LConfig.LanguageFile, 'Should read localization file.');
  finally
    LConfig.Free;
  end;
  DeleteFile(LTestConfigFile);
end;

procedure ReadsUpdateSettings;
var
  LConfig: TAppConfiguration;
  LFile: TStringList;
begin
  DeleteFile(LTestConfigFile);
  LFile := TStringList.Create;
  try
    LFile.Add('[Updates]');
    LFile.Add('Enabled=true');
    LFile.Add('ManifestUrl=https://example.test/latest.json');
    LFile.Add('DownloadDir=downloaded-updates');
    LFile.SaveToFile(LTestConfigFile);
  finally
    LFile.Free;
  end;

  LConfig := TAppConfiguration.Create(LTestConfigFile);
  try
    AssertEquals('true', LowerCase(BoolToStr(LConfig.UpdatesEnabled, True)), 'Should read update enabled flag.');
    AssertEquals('https://example.test/latest.json', LConfig.UpdateManifestUrl, 'Should read update manifest URL.');
    AssertEquals('downloaded-updates', LConfig.UpdateDownloadDir, 'Should read update download dir.');
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
  RunTest('Reads_database_file', ReadsDatabaseFile, AFailures);
  RunTest('Reads_connectionString', ReadsConnectionString, AFailures);
  RunTest('Reads_localization_settings', ReadsLocalizationSettings, AFailures);
  RunTest('Reads_update_settings', ReadsUpdateSettings, AFailures);
end;

end.
