unit AppCorePreferencesServiceTests;

interface

procedure RunPreferencesServiceTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCorePreferences,
  AppCoreIniText,
  AppCoreCrud,
  AppCoreUser,
  AppCoreUserPreferencesRepository,
  AppCoreUserRepository;

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
  LAppRepo: ILoginPreferencesRepository;
  LUsers: TInMemoryUserRepository;
  LUser: TUser;
  LService: TPreferencesService;
  LPreferences: TPreferencesView;
begin
  LAppRepo := TInMemoryLoginPreferencesRepository.Create;
  LUsers := TInMemoryUserRepository.Create;
  LUser := TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True, urAdmin);
  LUsers.Add(LUser);
  LService := TPreferencesService.Create(LAppRepo, LUsers, 'user-1');
  try
    LService.SavePreferences('en', 'TSK');
    LPreferences := LService.GetPreferences;

    AssertEquals('en', LPreferences.ActiveLanguage, 'Language should be saved.');
    AssertEquals('TSK', LPreferences.LastMainOption, 'Last main option should be saved.');
    AssertEquals('en', IniTextReadValue(LUser.PreferencesText, 'User',
      'ActiveLanguage'), 'Language should be stored on user.');
    AssertEquals('TSK', IniTextReadValue(LUser.PreferencesText, 'User',
      'LastMainOption'), 'Main option should be stored on user.');
  finally
    LService.Free;
  end;
end;

procedure SavePreferencesRejectsInvalidLanguage;
var
  LAppRepo: ILoginPreferencesRepository;
  LUsers: TInMemoryUserRepository;
  LService: TPreferencesService;
begin
  LAppRepo := TInMemoryLoginPreferencesRepository.Create;
  LUsers := TInMemoryUserRepository.Create;
  LUsers.Add(TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True, urAdmin));
  LService := TPreferencesService.Create(LAppRepo, LUsers, 'user-1');
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
  LAppRepo: ILoginPreferencesRepository;
  LUsers: TInMemoryUserRepository;
  LService: TPreferencesService;
begin
  LAppRepo := TInMemoryLoginPreferencesRepository.Create;
  LUsers := TInMemoryUserRepository.Create;
  LUsers.Add(TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True, urAdmin));
  LService := TPreferencesService.Create(LAppRepo, LUsers, 'user-1');
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
  LAppRepo: ILoginPreferencesRepository;
  LUsers: TInMemoryUserRepository;
  LService: TPreferencesService;
  LPreferences: TPreferencesView;
begin
  LAppRepo := TInMemoryLoginPreferencesRepository.Create;
  LAppRepo.SetLastUsername('admin');
  LUsers := TInMemoryUserRepository.Create;
  LUsers.Add(TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True, urAdmin));
  LService := TPreferencesService.Create(LAppRepo, LUsers, 'user-1');
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
  LAppRepo: ILoginPreferencesRepository;
  LUsers: TInMemoryUserRepository;
  LService: TPreferencesService;
begin
  LAppRepo := TInMemoryLoginPreferencesRepository.Create;
  LUsers := TInMemoryUserRepository.Create;
  LUsers.Add(TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True, urAdmin));
  LService := TPreferencesService.Create(LAppRepo, LUsers, 'user-1');
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
  LAppRepo: ILoginPreferencesRepository;
  LUsers: TInMemoryUserRepository;
  LService: TPreferencesService;
  LPreferences: TPreferencesView;
begin
  LAppRepo := TInMemoryLoginPreferencesRepository.Create;
  LUsers := TInMemoryUserRepository.Create;
  LUsers.Add(TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True, urAdmin));
  LService := TPreferencesService.Create(LAppRepo, LUsers, 'user-1');
  try
    LService.SavePreferences('es', 'TSK');
    LPreferences := LService.GetPreferences;
    AssertEquals('TSK', LPreferences.LastMainOption, 'TSK should be a valid main option.');
  finally
    LService.Free;
  end;
end;

procedure UserGridLayoutStoresValuesInCurrentUserPreferencesText;
var
  LUsers: TInMemoryUserRepository;
  LUsersInterface: IUserRepository;
  LUser1, LUser2: TUser;
  LLayout: ICrudGridLayoutRepository;
begin
  LUsers := TInMemoryUserRepository.Create;
  LUsersInterface := LUsers;
  LUser1 := TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True, urAdmin);
  LUser2 := TUser.Create('user-2', 'other', 'Other', 'hash', 'salt', True, urNormal);
  LUsers.Add(LUser1);
  LUsers.Add(LUser2);

  LLayout := TUserGridLayoutRepository.Create(LUsersInterface, 'user-1');
  LLayout.WriteGridValue('TSK', 'Filter.title', 'urgent');
  LLayout.WriteGridValue('TSK', 'Sort.Field', 'title');

  AssertEquals('urgent', IniTextReadValue(LUser1.PreferencesText, 'Grid.TSK',
    'Filter.title'), 'Grid filter should be stored on current user.');
  AssertEquals('title', IniTextReadValue(LUser1.PreferencesText, 'Grid.TSK',
    'Sort.Field'), 'Grid sort should be stored on current user.');
  AssertEquals('', IniTextReadValue(LUser2.PreferencesText, 'Grid.TSK',
    'Filter.title'), 'Other users should keep independent grid preferences.');
end;

procedure RunPreferencesServiceTests(var AFailures: Integer);
begin
  RunTest('PreferencesService_saves_editable_values', SavePreferencesStoresEditableValues, AFailures);
  RunTest('PreferencesService_rejects_invalid_language', SavePreferencesRejectsInvalidLanguage, AFailures);
  RunTest('PreferencesService_rejects_invalid_main_option', SavePreferencesRejectsInvalidMainOption, AFailures);
  RunTest('PreferencesService_rejects_legacy_main_options', SavePreferencesRejectsLegacyMainOptions, AFailures);
  RunTest('PreferencesService_keeps_last_username', SavePreferencesKeepsLastUsername, AFailures);
  RunTest('PreferencesService_accepts_tsk_main_option', SavePreferencesAcceptsTskMainOption, AFailures);
  RunTest('UserGridLayout_stores_values_in_current_user_preferences_text',
    UserGridLayoutStoresValuesInCurrentUserPreferencesText, AFailures);
end;

end.
