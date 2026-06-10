unit AppCoreRepositoryFactoryTests;

interface

procedure RunRepositoryFactoryTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCorePreferences,
  AppCoreRepositoryFactory,
  AppCoreTaskRepository,
  AppCoreUserRepository;

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

procedure FactoryCreatesUserRepository;
var
  LFactory: IRepositoryFactory;
  LRepo: IUserRepository;
begin
  LFactory := TJsonRepositoryFactory.Create('.');
  LRepo := LFactory.CreateUserRepository;
  AssertTrue(LRepo <> nil, 'CreateUserRepository should return non-nil.');
  AssertTrue(LRepo.All <> nil, 'All() should return non-nil list.');
end;

procedure FactoryCreatesTaskRepository;
var
  LFactory: IRepositoryFactory;
  LRepo: ITaskRepository;
begin
  LFactory := TJsonRepositoryFactory.Create('.');
  LRepo := LFactory.CreateTaskRepository;
  AssertTrue(LRepo <> nil, 'CreateTaskRepository should return non-nil.');
end;

procedure FactoryCreatesLoginPreferencesRepository;
var
  LFactory: IRepositoryFactory;
  LRepo: ILoginPreferencesRepository;
begin
  LFactory := TJsonRepositoryFactory.Create('.');
  LRepo := LFactory.CreateLoginPreferencesRepository;
  AssertTrue(LRepo <> nil, 'CreateLoginPreferencesRepository should return non-nil.');
end;

procedure FactoryCreatesDistinctUserRepositories;
var
  LFactory: IRepositoryFactory;
  LRepo1: IUserRepository;
  LRepo2: IUserRepository;
begin
  LFactory := TJsonRepositoryFactory.Create('.');
  LRepo1 := LFactory.CreateUserRepository;
  LRepo2 := LFactory.CreateUserRepository;
  AssertTrue(LRepo1 <> LRepo2, 'Each call should create a new repository instance.');
end;

procedure RunRepositoryFactoryTests(var AFailures: Integer);
begin
  RunTest('Factory_creates_user_repository', FactoryCreatesUserRepository, AFailures);
  RunTest('Factory_creates_task_repository', FactoryCreatesTaskRepository, AFailures);
  RunTest('Factory_creates_login_preferences_repository', FactoryCreatesLoginPreferencesRepository, AFailures);
  RunTest('Factory_creates_distinct_user_repositories', FactoryCreatesDistinctUserRepositories, AFailures);
end;

end.
