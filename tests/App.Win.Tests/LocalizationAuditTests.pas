unit LocalizationAuditTests;

interface

procedure RunLocalizationAuditTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  TypInfo,
  Controls,
  Forms,
  StdCtrls,
  AboutForm,
  CrudDetailForm,
  CrudForm,
  CrudPreviewForm,
  CrudSearchForm,
  MainForm,
  PreferencesForm,
  LoginForm,
  AppCoreLocalization,
  AppWinLocalization;

type
  TTestProc = procedure;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
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

function ColumnIndex(AHeaders: TStrings; const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to AHeaders.Count - 1 do
    if LowerCase(AHeaders[I]) = LowerCase(AName) then
    begin
      Result := I;
      Exit;
    end;
end;

procedure RequireColumn(AHeaders: TStrings; const AName: string);
begin
  if ColumnIndex(AHeaders, AName) < 0 then
    raise Exception.Create('Localization CSV must contain column "' + AName + '".');
end;

procedure LoadCsvKeysForForm(const AFileName, AFormName: string; AKeys: TStrings);
var
  LLines: TStringList;
  LHeaders: TStringList;
  LValues: TStringList;
  LKeyColumn: Integer;
  I: Integer;
  LKey: string;
  LPrefix: string;
  LSeparator: Char;
begin
  LLines := TStringList.Create;
  LHeaders := TStringList.Create;
  LValues := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    if LLines.Count = 0 then
      raise Exception.Create('Localization CSV is empty.');

    LSeparator := DetectCsvSeparator(LLines[0]);
    ParseCsvLine(LLines[0], LHeaders, LSeparator);
    LKeyColumn := ColumnIndex(LHeaders, 'key');
    LPrefix := AFormName + '.';
    for I := 1 to LLines.Count - 1 do
    begin
      ParseCsvLine(LLines[I], LValues, LSeparator);
      if (LKeyColumn >= 0) and (LKeyColumn < LValues.Count) then
      begin
        LKey := LValues[LKeyColumn];
        if Copy(LKey, 1, Length(LPrefix)) = LPrefix then
          AKeys.Add(LKey);
      end;
    end;
  finally
    LValues.Free;
    LHeaders.Free;
    LLines.Free;
  end;
end;

function HasKey(AKeys: TStrings; const AKey: string): Boolean;
begin
  Result := AKeys.IndexOf(AKey) >= 0;
end;

procedure AuditCaptionKeys(AForm: TForm; AKeys: TStrings);
var
  I: Integer;
  LComponent: TComponent;
  LCaption: string;
  LKey: string;
begin
  LCaption := GetStrProp(AForm, 'Caption');
  if LCaption <> '' then
  begin
    LKey := AForm.Name + '.Caption';
    if not HasKey(AKeys, LKey) then
      raise Exception.Create('Missing localization key ' + LKey + '.');
  end;

  for I := 0 to AForm.ComponentCount - 1 do
  begin
    LComponent := AForm.Components[I];
    if LComponent.Name = '' then
      Continue;

    if IsPublishedProp(LComponent, 'Caption') then
    begin
      LCaption := GetStrProp(LComponent, 'Caption');
      if LCaption <> '' then
      begin
        LKey := AForm.Name + '.' + LComponent.Name + '.Caption';
        if not HasKey(AKeys, LKey) then
          raise Exception.Create('Missing localization key ' + LKey + '.');
      end;
    end;
  end;
end;

procedure AuditLocalizationCsvForForm(const AFileName, ADefaultLanguage,
  AActiveLanguage: string; AForm: TForm);
var
  LLines: TStringList;
  LHeaders: TStringList;
  LKeys: TStringList;
  LLocalization: ILocalizationService;
  LSeparator: Char;
begin
  if not FileExists(AFileName) then
    raise Exception.Create('Localization CSV was not found: ' + AFileName);

  LLines := TStringList.Create;
  LHeaders := TStringList.Create;
  LKeys := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    if LLines.Count = 0 then
      raise Exception.Create('Localization CSV is empty.');

    LSeparator := DetectCsvSeparator(LLines[0]);
    ParseCsvLine(LLines[0], LHeaders, LSeparator);
    RequireColumn(LHeaders, 'key');
    RequireColumn(LHeaders, ADefaultLanguage);
    RequireColumn(LHeaders, AActiveLanguage);

    LLocalization := TCsvLocalizationService.Create(AFileName, AActiveLanguage,
      ADefaultLanguage);
    AppWinLocalization.ApplyLocalization(AForm, LLocalization, True);

    LoadCsvKeysForForm(AFileName, AForm.Name, LKeys);
    AuditCaptionKeys(AForm, LKeys);
  finally
    LKeys.Free;
    LHeaders.Free;
    LLines.Free;
  end;
end;

function LanguagesCsvPath: string;
begin
  Result := ExpandFileName('..\..\src\App.Win\languages.csv');
end;

procedure LocalizationAuditAcceptsLoginFormCsv;
var
  LForm: TFrmLogin;
begin
  LForm := TFrmLogin.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditAcceptsMainFormCsv;
var
  LForm: TFrmMain;
begin
  LForm := TFrmMain.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditAcceptsAboutFormCsv;
var
  LForm: TFrmAbout;
begin
  LForm := TFrmAbout.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditAcceptsPreferencesFormCsv;
var
  LForm: TFrmPreferences;
begin
  LForm := TFrmPreferences.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditAcceptsCrudFormCsv;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditAcceptsCrudDetailFormCsv;
var
  LForm: TFrmCrudDetail;
begin
  LForm := TFrmCrudDetail.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditAcceptsCrudSearchFormCsv;
var
  LForm: TFrmCrudSearch;
begin
  LForm := TFrmCrudSearch.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditAcceptsCrudPreviewFormCsv;
var
  LForm: TFrmCrudPreview;
begin
  LForm := TFrmCrudPreview.Create(nil);
  try
    AuditLocalizationCsvForForm(LanguagesCsvPath, 'es', 'en', LForm);
  finally
    LForm.Free;
  end;
end;

procedure LocalizationAuditRejectsMissingCsv;
var
  LForm: TFrmLogin;
begin
  LForm := TFrmLogin.Create(nil);
  try
    try
      AuditLocalizationCsvForForm('missing-languages.csv', 'es', 'en', LForm);
    except
      on E: Exception do
        Exit;
    end;
  finally
    LForm.Free;
  end;
  raise Exception.Create('Expected missing CSV audit failure.');
end;

procedure LocalizationAuditRejectsMissingColumns;
const
  LFileName = 'test_bad_languages.csv';
var
  LLines: TStringList;
  LForm: TFrmLogin;
begin
  LLines := TStringList.Create;
  try
    LLines.Add('key,es');
    LLines.Add('FrmLogin.Caption,Login');
    LLines.SaveToFile(LFileName);
  finally
    LLines.Free;
  end;

  LForm := TFrmLogin.Create(nil);
  try
    try
      AuditLocalizationCsvForForm(LFileName, 'es', 'en', LForm);
    except
      on E: Exception do
        Exit;
    end;
  finally
    LForm.Free;
    DeleteFile(LFileName);
  end;
  raise Exception.Create('Expected missing column audit failure.');
end;

procedure LocalizationAuditRejectsUnknownComponent;
const
  LFileName = 'test_unknown_component_languages.csv';
var
  LLines: TStringList;
  LForm: TFrmLogin;
begin
  LLines := TStringList.Create;
  try
    LLines.Add('key,es,en');
    LLines.Add('FrmLogin.UnknownLabel.Caption,Texto,Text');
    LLines.SaveToFile(LFileName);
  finally
    LLines.Free;
  end;

  LForm := TFrmLogin.Create(nil);
  try
    try
      AuditLocalizationCsvForForm(LFileName, 'es', 'en', LForm);
    except
      on E: Exception do
        Exit;
    end;
  finally
    LForm.Free;
    DeleteFile(LFileName);
  end;
  raise Exception.Create('Expected unknown component audit failure.');
end;

procedure LocalizationAuditRejectsUnknownProperty;
const
  LFileName = 'test_unknown_property_languages.csv';
var
  LLines: TStringList;
  LForm: TFrmLogin;
begin
  LLines := TStringList.Create;
  try
    LLines.Add('key,es,en');
    LLines.Add('FrmLogin.LblUsername.UnknownProperty,Texto,Text');
    LLines.SaveToFile(LFileName);
  finally
    LLines.Free;
  end;

  LForm := TFrmLogin.Create(nil);
  try
    try
      AuditLocalizationCsvForForm(LFileName, 'es', 'en', LForm);
    except
      on E: Exception do
        Exit;
    end;
  finally
    LForm.Free;
    DeleteFile(LFileName);
  end;
  raise Exception.Create('Expected unknown property audit failure.');
end;

procedure LocalizationAuditRejectsMissingCaptionKey;
const
  LFileName = 'test_missing_caption_languages.csv';
var
  LLines: TStringList;
  LForm: TFrmLogin;
begin
  LLines := TStringList.Create;
  try
    LLines.Add('key,es,en');
    LLines.Add('FrmLogin.Caption,Login,Login');
    LLines.SaveToFile(LFileName);
  finally
    LLines.Free;
  end;

  LForm := TFrmLogin.Create(nil);
  try
    try
      AuditLocalizationCsvForForm(LFileName, 'es', 'en', LForm);
    except
      on E: Exception do
        Exit;
    end;
  finally
    LForm.Free;
    DeleteFile(LFileName);
  end;
  raise Exception.Create('Expected missing caption key audit failure.');
end;

procedure RunLocalizationAuditTests(var AFailures: Integer);
begin
  RunTest('LocalizationAudit_accepts_login_form_csv', LocalizationAuditAcceptsLoginFormCsv, AFailures);
  RunTest('LocalizationAudit_accepts_main_form_csv', LocalizationAuditAcceptsMainFormCsv, AFailures);
  RunTest('LocalizationAudit_accepts_about_form_csv', LocalizationAuditAcceptsAboutFormCsv, AFailures);
  RunTest('LocalizationAudit_accepts_preferences_form_csv', LocalizationAuditAcceptsPreferencesFormCsv, AFailures);
  RunTest('LocalizationAudit_accepts_crud_form_csv', LocalizationAuditAcceptsCrudFormCsv, AFailures);
  RunTest('LocalizationAudit_accepts_crud_detail_form_csv', LocalizationAuditAcceptsCrudDetailFormCsv, AFailures);
  RunTest('LocalizationAudit_accepts_crud_search_form_csv', LocalizationAuditAcceptsCrudSearchFormCsv, AFailures);
  RunTest('LocalizationAudit_accepts_crud_preview_form_csv', LocalizationAuditAcceptsCrudPreviewFormCsv, AFailures);
  RunTest('LocalizationAudit_rejects_missing_csv', LocalizationAuditRejectsMissingCsv, AFailures);
  RunTest('LocalizationAudit_rejects_missing_columns', LocalizationAuditRejectsMissingColumns, AFailures);
  RunTest('LocalizationAudit_rejects_unknown_component', LocalizationAuditRejectsUnknownComponent, AFailures);
  RunTest('LocalizationAudit_rejects_unknown_property', LocalizationAuditRejectsUnknownProperty, AFailures);
  RunTest('LocalizationAudit_rejects_missing_caption_key', LocalizationAuditRejectsMissingCaptionKey, AFailures);
end;

end.
