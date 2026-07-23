unit AppCoreLocalizationTests;

interface

procedure RunLocalizationTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCoreLocalization;

const
  LTestLocalizationFile = 'test_languages.csv';

procedure AssertEquals(const AExpected, AActual: string; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure AssertEquals(AExpected, AActual: Integer; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected ' + IntToStr(AExpected) + ', got ' + IntToStr(AActual) + '.');
end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
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

procedure WriteLocalizationFile;
var
  LFile: TStringList;
begin
  LFile := TStringList.Create;
  try
    LFile.Add('key,es,en');
    LFile.Add('FrmLogin.Caption,Login,Login');
    LFile.Add('FrmLogin.LblUsername.Caption,Usuario,Username');
    LFile.Add('FrmLogin.LblPassword.Caption,Contrase�a,Password');
    LFile.Add('FrmLogin.BtnLogin.Caption,Entrar,Sign in');
    LFile.Add('FrmLogin.BtnCancel.Caption,Cancelar,Cancel');
    LFile.Add('OtherForm.Caption,Otro,Other');
    LFile.Add('FrmLogin.LblMessage.Caption,"Hola, mundo","Hello, world"');
    LFile.Add('About.VersionPrefix,Version: ,Version: ');
    LFile.SaveToFile(LTestLocalizationFile);
  finally
    LFile.Free;
  end;
end;

procedure LoadsTextForSelectedLanguage;
var
  LLocalization: ILocalizationService;
begin
  WriteLocalizationFile;
  LLocalization := TCsvLocalizationService.Create(LTestLocalizationFile, 'en', 'es');
  AssertEquals('Username', LLocalization.Text('FrmLogin.LblUsername.Caption'),
    'Should load selected language text.');
  DeleteFile(LTestLocalizationFile);
end;

procedure FallsBackToDefaultLanguageWhenSelectedTextIsEmpty;
var
  LFile: TStringList;
  LLocalization: ILocalizationService;
begin
  LFile := TStringList.Create;
  try
    LFile.Add('key,es,en');
    LFile.Add('FrmLogin.BtnLogin.Caption,Entrar,');
    LFile.SaveToFile(LTestLocalizationFile);
  finally
    LFile.Free;
  end;

  LLocalization := TCsvLocalizationService.Create(LTestLocalizationFile, 'en', 'es');
  AssertEquals('Entrar', LLocalization.Text('FrmLogin.BtnLogin.Caption'),
    'Empty selected text should fall back to default language.');
  DeleteFile(LTestLocalizationFile);
end;

procedure ParsesQuotedCsvValues;
var
  LLocalization: ILocalizationService;
begin
  WriteLocalizationFile;
  LLocalization := TCsvLocalizationService.Create(LTestLocalizationFile, 'en', 'es');
  AssertEquals('Hello, world', LLocalization.Text('FrmLogin.LblMessage.Caption'),
    'Should parse quoted values with commas.');
  DeleteFile(LTestLocalizationFile);
end;

procedure LoadsGlobalTextKey;
var
  LLocalization: ILocalizationService;
begin
  WriteLocalizationFile;
  LLocalization := TCsvLocalizationService.Create(LTestLocalizationFile, 'en', 'es');
  AssertTrue(LLocalization.HasText('About.VersionPrefix'),
    'Should load global localization keys.');
  AssertEquals('Version: ', LLocalization.Text('About.VersionPrefix'),
    'Should return global localization key text.');
  DeleteFile(LTestLocalizationFile);
end;
procedure ReturnsOnlyKeysForRequestedForm;
var
  LLocalization: ILocalizationService;
  LKeys: TStringList;
begin
  WriteLocalizationFile;
  LLocalization := TCsvLocalizationService.Create(LTestLocalizationFile, 'es', 'es');
  LKeys := TStringList.Create;
  try
    LLocalization.AddKeysForForm('FrmLogin', LKeys);
    AssertEquals(6, LKeys.Count, 'Should return only keys for requested form.');
    AssertTrue(LKeys.IndexOf('OtherForm.Caption') < 0, 'Should exclude other forms.');
  finally
    LKeys.Free;
  end;
  DeleteFile(LTestLocalizationFile);
end;

procedure ChangesLanguageAndReloadsTexts;
var
  LLocalization: ILocalizationService;
begin
  WriteLocalizationFile;
  LLocalization := TCsvLocalizationService.Create(LTestLocalizationFile, 'es', 'es');
  AssertEquals('Usuario', LLocalization.Text('FrmLogin.LblUsername.Caption'),
    'Should start with Spanish text.');

  LLocalization.ChangeLanguage('en');

  AssertEquals('en', LLocalization.Language, 'Language should be updated.');
  AssertEquals('Username', LLocalization.Text('FrmLogin.LblUsername.Caption'),
    'Texts should be reloaded for new language.');
  DeleteFile(LTestLocalizationFile);
end;

procedure RunLocalizationTests(var AFailures: Integer);
begin
  RunTest('Localization_loads_text_for_selected_language', LoadsTextForSelectedLanguage, AFailures);
  RunTest('Localization_falls_back_to_default_language_when_selected_text_is_empty', FallsBackToDefaultLanguageWhenSelectedTextIsEmpty, AFailures);
  RunTest('Localization_parses_quoted_csv_values', ParsesQuotedCsvValues, AFailures);
  RunTest('Localization_loads_global_text_key', LoadsGlobalTextKey, AFailures);
  RunTest('Localization_returns_only_keys_for_requested_form', ReturnsOnlyKeysForRequestedForm, AFailures);
  RunTest('Localization_changes_language_and_reloads_texts', ChangesLanguageAndReloadsTexts, AFailures);
end;

end.
