unit PreferencesFormTests;

interface

procedure RunPreferencesFormTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  Forms,
  PreferencesForm,
  AppCorePreferences;

type
  TTestProc = procedure;

  TLanguageEventSink = class
  private
    FCallCount: Integer;
    FLanguage: string;
  public
    procedure LanguageSaved(Sender: TObject; const ALanguage: string);
    property CallCount: Integer read FCallCount;
    property Language: string read FLanguage;
  end;

procedure TLanguageEventSink.LanguageSaved(Sender: TObject; const ALanguage: string);
begin
  Inc(FCallCount);
  FLanguage := ALanguage;
end;

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

procedure PreferencesFormLoadsCurrentValues;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
  LForm: TFrmPreferences;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LRepo.SetLastUsername('admin');
  LRepo.SetActiveLanguage('en');
  LRepo.SetLastMainOption('TSK');
  LService := TPreferencesService.Create(LRepo);
  LForm := TFrmPreferences.Create(nil);
  try
    LForm.Configure(LService);

    AssertEquals('admin', LForm.EdtLastUsername.Text, 'Form should show last username.');
    AssertEquals('en', LForm.CmbLanguage.Text, 'Form should show active language.');
    AssertEquals('TSK', LForm.CmbLastMainOption.Text, 'Form should show last main option.');
    AssertTrue(LForm.EdtLastUsername.ReadOnly, 'Last username should be read-only.');
  finally
    LForm.Free;
  end;
end;

procedure PreferencesFormSavesValues;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
  LForm: TFrmPreferences;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LService := TPreferencesService.Create(LRepo);
  LForm := TFrmPreferences.Create(nil);
  try
    LForm.Configure(LService);
    LForm.CmbLanguage.Text := 'en';
    LForm.CmbLastMainOption.Text := 'USR';
    LForm.BtnSaveClick(nil);

    AssertEquals('en', LRepo.ActiveLanguage, 'Form should save language.');
    AssertEquals('USR', LRepo.LastMainOption, 'Form should save last main option.');
  finally
    LForm.Free;
  end;
end;

procedure PreferencesFormNotifiesSavedLanguage;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
  LForm: TFrmPreferences;
  LSink: TLanguageEventSink;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LService := TPreferencesService.Create(LRepo);
  LForm := TFrmPreferences.Create(nil);
  LSink := TLanguageEventSink.Create;
  try
    LForm.Configure(LService);
    LForm.OnLanguageSaved := LSink.LanguageSaved;
    LForm.CmbLanguage.Text := 'en';
    LForm.CmbLastMainOption.Text := 'Dashboard';
    LForm.BtnSaveClick(nil);

    AssertEquals(1, LSink.CallCount, 'Form should notify language save once.');
    AssertEquals('en', LSink.Language, 'Form should notify saved language.');
  finally
    LSink.Free;
    LForm.Free;
  end;
end;

procedure PreferencesFormLoadsTskMainOption;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
  LForm: TFrmPreferences;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LRepo.SetLastMainOption('TSK');
  LService := TPreferencesService.Create(LRepo);
  LForm := TFrmPreferences.Create(nil);
  try
    LForm.Configure(LService);
    AssertEquals('TSK', LForm.CmbLastMainOption.Text, 'Form should allow TSK as startup screen.');
  finally
    LForm.Free;
  end;
end;

procedure RunPreferencesFormTests(var AFailures: Integer);
begin
  RunTest('PreferencesForm_loads_current_values', PreferencesFormLoadsCurrentValues, AFailures);
  RunTest('PreferencesForm_saves_values', PreferencesFormSavesValues, AFailures);
  RunTest('PreferencesForm_notifies_saved_language', PreferencesFormNotifiesSavedLanguage, AFailures);
  RunTest('PreferencesForm_loads_tsk_main_option', PreferencesFormLoadsTskMainOption, AFailures);
end;

end.
