unit AboutFormTests;

interface

procedure RunAboutFormTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AboutForm,
  AppCoreLocalization;

type
  TTestProc = procedure;

  TFakeLocalizationService = class(TInterfacedObject, ILocalizationService)
  private
    FLanguage: string;
    FTexts: TStringList;
  public
    constructor Create(const ALanguage: string);
    destructor Destroy; override;
    function Language: string;
    function HasText(const AKey: string): Boolean;
    function Text(const AKey: string): string;
    procedure AddKeysForForm(const AFormName: string; AKeys: TStrings);
    procedure ChangeLanguage(const ALanguage: string);
    procedure AddText(const AKey, AValue: string);
  end;

  TFakeAboutUpdateChecker = class(TInterfacedObject, IAboutUpdateChecker)
  public
    ResultText: string;
    function CheckForUpdate: TAboutUpdateCheckResult;
  end;

constructor TFakeLocalizationService.Create(const ALanguage: string);
begin
  inherited Create;
  FLanguage := ALanguage;
  FTexts := TStringList.Create;
end;

destructor TFakeLocalizationService.Destroy;
begin
  FTexts.Free;
  inherited Destroy;
end;

function TFakeLocalizationService.Language: string;
begin
  Result := FLanguage;
end;

function TFakeLocalizationService.HasText(const AKey: string): Boolean;
begin
  Result := FTexts.IndexOfName(AKey) >= 0;
end;

function TFakeLocalizationService.Text(const AKey: string): string;
begin
  Result := FTexts.Values[AKey];
end;

procedure TFakeLocalizationService.AddKeysForForm(const AFormName: string;
  AKeys: TStrings);
var
  I: Integer;
  LPrefix: string;
  LKey: string;
begin
  LPrefix := AFormName + '.';
  for I := 0 to FTexts.Count - 1 do
  begin
    LKey := FTexts.Names[I];
    if Copy(LKey, 1, Length(LPrefix)) = LPrefix then
      AKeys.Add(LKey);
  end;
end;

procedure TFakeLocalizationService.AddText(const AKey, AValue: string);
begin
  FTexts.Values[AKey] := AValue;
end;

procedure TFakeLocalizationService.ChangeLanguage(const ALanguage: string);
begin
  FLanguage := ALanguage;
end;

function TFakeAboutUpdateChecker.CheckForUpdate: TAboutUpdateCheckResult;
begin
  Result.MessageText := ResultText;
end;

procedure AssertEquals(const AExpected, AActual: string; const AMessage: string);
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure AssertStartsWith(const APrefix, AActual: string; const AMessage: string);
begin
  if Copy(AActual, 1, Length(APrefix)) <> APrefix then
    raise Exception.Create(AMessage + ' Expected prefix "' + APrefix + '", got "' + AActual + '".');
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

function LanguagesCsvPath: string;
begin
  Result := ExpandFileName('..\..\src\App.Win\languages.csv');
end;

function CreateEnglishLocalization: TFakeLocalizationService;
begin
  Result := TFakeLocalizationService.Create('en');
  Result.AddText('FrmAbout.Caption', 'About translated');
  Result.AddText('FrmAbout.LblAppName.Caption', 'Application translated');
  Result.AddText('FrmAbout.LblDescription.Caption', 'Description translated');
  Result.AddText('FrmAbout.LblCopyright.Caption', 'Copyright translated');
  Result.AddText('FrmAbout.LblTechHeader.Caption', 'Technical translated');
  Result.AddText('FrmAbout.BtnAccept.Caption', 'OK translated');
  Result.AddText('FrmAbout.BtnCheckUpdate.Caption', 'Check update translated');
  Result.AddText('FrmAbout.LblUpdateStatus.Caption', '');
  Result.AddText('About.VersionPrefix', 'Version translated: ');
  Result.AddText('About.ExecutableVersionPrefix', 'Executable translated: ');
  Result.AddText('About.CommitPrefix', 'Commit translated: ');
  Result.AddText('About.OperatingSystemPrefix', 'OS translated: ');
  Result.AddText('About.ArchitecturePrefix', 'Arch translated: ');
  Result.AddText('About.BuildDatePrefix', 'Build translated: ');
  Result.AddText('About.DatabasePrefix', 'Database translated: ');
end;

function CreateSpanishLocalization: TFakeLocalizationService;
begin
  Result := TFakeLocalizationService.Create('es');
  Result.AddText('FrmAbout.Caption', 'Acerca de');
  Result.AddText('FrmAbout.LblTechHeader.Caption', 'Informacion tecnica');
  Result.AddText('FrmAbout.BtnAccept.Caption', 'Aceptar');
  Result.AddText('FrmAbout.BtnCheckUpdate.Caption', 'Buscar actualizacion');
  Result.AddText('FrmAbout.LblUpdateStatus.Caption', '');
  Result.AddText('About.VersionPrefix', 'Version: ');
  Result.AddText('About.ExecutableVersionPrefix', 'Version del ejecutable: ');
  Result.AddText('About.CommitPrefix', 'Commit GitHub: ');
  Result.AddText('About.OperatingSystemPrefix', 'Sistema operativo: ');
  Result.AddText('About.ArchitecturePrefix', 'Arquitectura: ');
  Result.AddText('About.BuildDatePrefix', 'Fecha de compilacion: ');
  Result.AddText('About.DatabasePrefix', 'Base de datos: ');
end;

procedure AboutFormLoadsEnglishDynamicTexts;
var
  LForm: TFrmAbout;
  LLocalization: ILocalizationService;
begin
  LLocalization := CreateEnglishLocalization;
  LForm := TFrmAbout.Create(nil);
  try
    LForm.ApplyLocalization(LLocalization);

    AssertEquals('About translated', LForm.Caption, 'About caption should use active language.');
    AssertEquals('Technical translated', LForm.LblTechHeader.Caption,
      'Technical header should use active language.');
    AssertEquals('OK translated', LForm.BtnAccept.Caption, 'Accept button should use active language.');
    AssertEquals('Check update translated', LForm.BtnCheckUpdate.Caption,
      'Check update button should use active language.');
    AssertEquals('Application translated', LForm.LblAppName.Caption,
      'Application label should use language file value.');
    AssertEquals('Description translated', LForm.LblDescription.Caption,
      'Description label should use language file value.');
    AssertEquals('Copyright translated', LForm.LblCopyright.Caption,
      'Copyright label should use language file value.');
    AssertStartsWith('Version translated: ', LForm.LblVersion.Caption,
      'Version label should use active language.');
    AssertStartsWith('Executable translated: ', LForm.LblExecVersion.Caption,
      'Executable version label should use active language.');
    AssertStartsWith('Commit translated: ', LForm.LblCommit.Caption,
      'Commit label should use active language.');
    AssertStartsWith('OS translated: ', LForm.LblOS.Caption,
      'Operating system label should use active language.');
    AssertStartsWith('Arch translated: ', LForm.LblArch.Caption,
      'Architecture label should use active language.');
    AssertStartsWith('Build translated: ', LForm.LblBuildDate.Caption,
      'Build date label should use active language.');
    AssertStartsWith('Database translated: ', LForm.LblDbPath.Caption,
      'Database label should use active language.');
  finally
    LForm.Free;
  end;
end;

procedure AboutFormReloadsSpanishAfterEnglish;
var
  LForm: TFrmAbout;
begin
  LForm := TFrmAbout.Create(nil);
  try
    LForm.ApplyLocalization(CreateEnglishLocalization);
    LForm.ApplyLocalization(CreateSpanishLocalization);

    AssertEquals('Acerca de', LForm.Caption, 'About caption should return to Spanish.');
    AssertEquals('Informacion tecnica', LForm.LblTechHeader.Caption,
      'Technical header should return to Spanish.');
    AssertEquals('Aceptar', LForm.BtnAccept.Caption,
      'Accept button should return to Spanish.');
    AssertEquals('Buscar actualizacion', LForm.BtnCheckUpdate.Caption,
      'Check update button should return to Spanish.');
    AssertStartsWith('Version del ejecutable: ', LForm.LblExecVersion.Caption,
      'Executable version label should return to Spanish.');
    AssertStartsWith('Commit GitHub: ', LForm.LblCommit.Caption,
      'Commit label should return to Spanish.');
    AssertStartsWith('Sistema operativo: ', LForm.LblOS.Caption,
      'Operating system label should return to Spanish.');
    AssertStartsWith('Arquitectura: ', LForm.LblArch.Caption,
      'Architecture label should return to Spanish.');
    AssertStartsWith('Fecha de compilacion: ', LForm.LblBuildDate.Caption,
      'Build date label should return to Spanish.');
    AssertStartsWith('Base de datos: ', LForm.LblDbPath.Caption,
      'Database label should return to Spanish.');
  finally
    LForm.Free;
  end;
end;

procedure AboutFormLoadsRealCsvEnglishTexts;
var
  LForm: TFrmAbout;
begin
  LForm := TFrmAbout.Create(nil);
  try
    LForm.ApplyLocalization(TCsvLocalizationService.Create(LanguagesCsvPath, 'en', 'es'));

    AssertEquals('About', LForm.Caption, 'About caption should come from real language file.');
    AssertEquals('Windows application', LForm.LblAppName.Caption,
      'Application label should come from real language file.');
    AssertEquals('Windows application developed in Delphi following TDD principles.',
      LForm.LblDescription.Caption,
      'Description label should come from real language file.');
    AssertEquals('Technical information', LForm.LblTechHeader.Caption,
      'Technical header should come from real language file.');
    AssertEquals('Check for update', LForm.BtnCheckUpdate.Caption,
      'Check update button should come from real language file.');
    AssertStartsWith('Executable version: ', LForm.LblExecVersion.Caption,
      'Executable version prefix should come from real language file.');
    AssertStartsWith('GitHub commit: ', LForm.LblCommit.Caption,
      'Commit prefix should come from real language file.');
    AssertStartsWith('Operating system: ', LForm.LblOS.Caption,
      'Operating system prefix should come from real language file.');
    AssertStartsWith('Database: ', LForm.LblDbPath.Caption,
      'Database prefix should come from real language file.');
  finally
    LForm.Free;
  end;
end;

procedure AboutFormShowsMessageWhenUpdateCheckerIsMissing;
var
  LForm: TFrmAbout;
begin
  LForm := TFrmAbout.Create(nil);
  try
    LForm.BtnCheckUpdateClick(nil);

    AssertEquals('Updater is not configured.', LForm.LblUpdateStatus.Caption,
      'Missing update checker should show a clear message.');
  finally
    LForm.Free;
  end;
end;

procedure AboutFormShowsUpdateCheckerResult;
var
  LForm: TFrmAbout;
  LChecker: TFakeAboutUpdateChecker;
begin
  LChecker := TFakeAboutUpdateChecker.Create;
  LChecker.ResultText := 'Update available and verified.';

  LForm := TFrmAbout.Create(nil);
  try
    LForm.ConfigureUpdateChecker(LChecker);
    LForm.BtnCheckUpdateClick(nil);

    AssertEquals('Update available and verified.', LForm.LblUpdateStatus.Caption,
      'Update checker result should be shown on the form.');
  finally
    LForm.Free;
  end;
end;

procedure RunAboutFormTests(var AFailures: Integer);
begin
  RunTest('AboutForm_loads_english_dynamic_texts', AboutFormLoadsEnglishDynamicTexts, AFailures);
  RunTest('AboutForm_reloads_spanish_after_english', AboutFormReloadsSpanishAfterEnglish, AFailures);
  RunTest('AboutForm_loads_real_csv_english_texts', AboutFormLoadsRealCsvEnglishTexts, AFailures);
  RunTest('AboutForm_shows_message_when_update_checker_is_missing', AboutFormShowsMessageWhenUpdateCheckerIsMissing, AFailures);
  RunTest('AboutForm_shows_update_checker_result', AboutFormShowsUpdateCheckerResult, AFailures);
end;

end.
