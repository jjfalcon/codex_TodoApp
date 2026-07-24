unit AppCoreSqliteRepositoryTests;

interface

procedure RunSqliteRepositoryTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCoreIniText,
  AppCoreRepositoryFactory,
  AppCoreTaskItem,
  AppCoreTaskRepository,
  AppCoreUser,
  AppCoreUserRepository;

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

function TestDbFileName(const AName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) + AName;
  DeleteFile(Result);
end;

procedure SqliteTaskRepositoryPersistsTasks;
var
  LDb: string;
  LFactory: IRepositoryFactory;
  LRepo: ITaskRepository;
  LTask: TTaskItem;
  LItems: TTaskItemArray;
begin
  LDb := TestDbFileName('todoapp-task-repository-test.db');
  LFactory := TSqliteRepositoryFactory.Create(ExtractFilePath(LDb), ExtractFileName(LDb));
  LRepo := LFactory.CreateTaskRepository;
  LTask := TTaskItem.Create('task-1', 'SQLite task', EncodeDate(2026, 7, 24));
  LTask.Status := tsCompleted;
  LTask.CompletedAt := EncodeDate(2026, 7, 25);
  LRepo.Add(LTask);
  LRepo := nil;

  LRepo := LFactory.CreateTaskRepository;
  LItems := LRepo.ListAll;
  AssertEquals(1, Length(LItems), 'SQLite task repository should persist one task.');
  AssertEquals('SQLite task', LItems[0].Title, 'SQLite task title should be restored.');
  AssertTrue(LItems[0].IsCompleted, 'SQLite task status should be restored.');
  DeleteFile(LDb);
end;

procedure SqliteUserRepositoryPersistsUsersAndPreferences;
var
  LDb: string;
  LFactory: IRepositoryFactory;
  LRepo: IUserRepository;
  LUser: TUser;
begin
  LDb := TestDbFileName('todoapp-user-repository-test.db');
  LFactory := TSqliteRepositoryFactory.Create(ExtractFilePath(LDb), ExtractFileName(LDb));
  LRepo := LFactory.CreateUserRepository;
  LUser := TUser.Create('user-1', 'admin', 'Admin', 'hash', 'salt', True,
    urAdmin, 'admin@example.test', EncodeDate(2026, 7, 24));
  LUser.FailedAttempts := 2;
  LUser.Locked := True;
  LUser.LastLoginAt := EncodeDate(2026, 7, 25);
  LUser.PreferencesText := IniTextWriteValue('', 'User', 'ActiveLanguage', 'en');
  LRepo.Save(LUser);
  LRepo := nil;

  LRepo := LFactory.CreateUserRepository;
  LUser := LRepo.FindByUsername('ADMIN');
  AssertTrue(LUser <> nil, 'SQLite user repository should find persisted user case-insensitively.');
  AssertEquals('admin@example.test', LUser.Email, 'SQLite user email should be restored.');
  AssertEquals('en', IniTextReadValue(LUser.PreferencesText, 'User',
    'ActiveLanguage'), 'SQLite user preferences text should be restored.');
  AssertTrue(LUser.Locked, 'SQLite user locked flag should be restored.');
  DeleteFile(LDb);
end;

procedure SqliteFactoryKeepsAppPreferencesInAppConfig;
var
  LDb: string;
  LDataPath: string;
  LFactory: IRepositoryFactory;
begin
  LDb := TestDbFileName('todoapp-factory-test.db');
  LDataPath := ExtractFilePath(LDb);
  LFactory := TSqliteRepositoryFactory.Create(LDataPath, ExtractFileName(LDb));

  AssertTrue(LFactory.CreateTaskRepository <> nil, 'SQLite factory should create task repository.');
  AssertTrue(LFactory.CreateUserRepository <> nil, 'SQLite factory should create user repository.');
  AssertTrue(LFactory.CreateLoginPreferencesRepository <> nil,
    'SQLite factory should keep app preferences repository available.');
  DeleteFile(LDb);
end;

procedure RunSqliteRepositoryTests(var AFailures: Integer);
begin
  RunTest('SqliteTaskRepository_persists_tasks', SqliteTaskRepositoryPersistsTasks, AFailures);
  RunTest('SqliteUserRepository_persists_users_and_preferences', SqliteUserRepositoryPersistsUsersAndPreferences, AFailures);
  RunTest('SqliteFactory_keeps_app_preferences_in_app_config', SqliteFactoryKeepsAppPreferencesInAppConfig, AFailures);
end;

end.
