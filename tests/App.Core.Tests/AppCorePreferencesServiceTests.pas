unit AppCorePreferencesServiceTests;

interface

procedure RunPreferencesServiceTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCorePreferences;

type
  TTestProc = procedure;

procedure AssertEquals(const AExpected, AActual: string; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
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

procedure SavePreferencesStoresEditableValues;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
  LPreferences: TUserPreferences;
begin
    LRepo := TInMemoryLoginPreferencesRepository.Create;
  LService := TPreferencesService.Create(LRepo);
  try
    LService.SavePreferences('en', 'TSK');
    LPreferences := LService.GetPreferences;

    AssertEquals('en', LPreferences.ActiveLanguage, 'Language should be saved.');
    AssertEquals('TSK', LPreferences.LastMainOption, 'Last main option should be saved.');
  finally
    LService.Free;
  end;
end;

procedure SavePreferencesRejectsInvalidLanguage;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LService := TPreferencesService.Create(LRepo);
  try
    try
      LService.SavePreferences('fr', 'Dashboard');
    except
      on E: EPreferencesValidationError do
        Exit;
    end;
  finally
    LService.Free;
  end;
  raise Exception.Create('Expected invalid language error.');
end;

procedure SavePreferencesRejectsInvalidMainOption;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LService := TPreferencesService.Create(LRepo);
  try
    try
      LService.SavePreferences('es', 'About');
    except
      on E: EPreferencesValidationError do
        Exit;
    end;
  finally
    LService.Free;
  end;
  raise Exception.Create('Expected invalid main option error.');
end;

procedure SavePreferencesKeepsLastUsername;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
  LPreferences: TUserPreferences;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LRepo.SetLastUsername('admin');
  LService := TPreferencesService.Create(LRepo);
  try
    LService.SavePreferences('es', 'USR');
    LPreferences := LService.GetPreferences;

    AssertEquals('admin', LPreferences.LastUsername, 'Saving editable preferences should keep last username.');
  finally
    LService.Free;
  end;
end;

procedure SavePreferencesRejectsLegacyMainOptions;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LService := TPreferencesService.Create(LRepo);
  try
    try
      LService.SavePreferences('es', 'Tasks');
    except
      on E: EPreferencesValidationError do
      begin
        try
          LService.SavePreferences('es', 'Users');
        except
          on E2: EPreferencesValidationError do
            Exit;
        end;
      end;
    end;
  finally
    LService.Free;
  end;
  raise Exception.Create('Expected legacy main options to be rejected.');
end;

procedure SavePreferencesAcceptsTskMainOption;
var
  LRepo: ILoginPreferencesRepository;
  LService: TPreferencesService;
  LPreferences: TUserPreferences;
begin
  LRepo := TInMemoryLoginPreferencesRepository.Create;
  LService := TPreferencesService.Create(LRepo);
  try
    LService.SavePreferences('es', 'TSK');
    LPreferences := LService.GetPreferences;
    AssertEquals('TSK', LPreferences.LastMainOption, 'TSK should be a valid main option.');
  finally
    LService.Free;
  end;
end;

procedure RunPreferencesServiceTests(var AFailures: Integer);
begin
  RunTest('PreferencesService_saves_editable_values', SavePreferencesStoresEditableValues, AFailures);
  RunTest('PreferencesService_rejects_invalid_language', SavePreferencesRejectsInvalidLanguage, AFailures);
  RunTest('PreferencesService_rejects_invalid_main_option', SavePreferencesRejectsInvalidMainOption, AFailures);
  RunTest('PreferencesService_rejects_legacy_main_options', SavePreferencesRejectsLegacyMainOptions, AFailures);
  RunTest('PreferencesService_keeps_last_username', SavePreferencesKeepsLastUsername, AFailures);
  RunTest('PreferencesService_accepts_tsk_main_option', SavePreferencesAcceptsTskMainOption, AFailures);
end;

end.
