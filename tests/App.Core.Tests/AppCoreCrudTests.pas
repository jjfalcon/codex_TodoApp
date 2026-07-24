unit AppCoreCrudTests;

interface

procedure RunCrudTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCoreAuth,
  AppCoreClock,
  AppCoreCrud,
  AppCoreTaskCrudProvider,
  AppCoreTaskItem,
  AppCoreTaskRepository,
  AppCoreTaskService,
  AppCoreUser,
  AppCoreUserCrudProvider,
  AppCoreUserRepository,
  AppCoreUserService;

type
  TFixedClock = class(TInterfacedObject, IClock)
  public
    function Now: TDateTime;
  end;

function TFixedClock.Now: TDateTime;
begin
  Result := EncodeDate(2026, 7, 23);
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

procedure AddUser(ARepo: TInMemoryUserRepository; const AId, AUsername,
  ADisplayName, AEmail: string; ARole: TUserRole);
var
  LUser: TUser;
begin
  LUser := TUser.Create(AId, AUsername, ADisplayName, 'hash', 'salt', True,
    ARole, AEmail, EncodeDate(2026, 7, 23));
  ARepo.Add(LUser);
end;

procedure BuildProvider(var ARepo: TInMemoryUserRepository;
  var AService: TUserService; var AProvider: ICrudProvider);
var
  LHasher: IPasswordHasher;
begin
  ARepo := TInMemoryUserRepository.Create;
  LHasher := TBasicPasswordHasher.Create;
  AddUser(ARepo, 'admin', 'admin', 'Administrador', 'admin@example.com', urAdmin);
  AddUser(ARepo, 'user', 'user', 'Usuario normal', 'user@example.com', urNormal);
  AService := TUserService.Create(ARepo, TFixedClock.Create, LHasher);
  AProvider := TUserCrudProvider.Create(AService, 'admin');
end;

procedure BuildTaskProvider(var ARepo: ITaskRepository;
  var AService: ITaskService; var AProvider: ICrudProvider);
begin
  ARepo := TInMemoryTaskRepository.Create;
  AService := TTaskService.Create(ARepo, TFixedClock.Create);
  AProvider := TTaskCrudProvider.Create(AService);
end;

procedure UserCrudSchemaExposesFields;
var
  LRepo: TInMemoryUserRepository;
  LService: TUserService;
  LProvider: ICrudProvider;
  LSchema: TCrudSchema;
begin
  BuildProvider(LRepo, LService, LProvider);
  LSchema := LProvider.Schema;
  try
    AssertTrue(LSchema.FieldByName('username') <> nil, 'Schema should include username.');
    AssertTrue(LSchema.FieldByName('password') <> nil, 'Schema should include password for create/change.');
    AssertEquals(8, LSchema.FieldCount, 'Schema should expose expected field count.');
  finally
    LSchema.Free;
    LService.Free;
  end;
end;

procedure UserCrudSearchesRecords;
var
  LRepo: TInMemoryUserRepository;
  LService: TUserService;
  LProvider: ICrudProvider;
  LRecords: TList;
begin
  BuildProvider(LRepo, LService, LProvider);
  LRecords := LProvider.List('normal', '', True, nil);
  try
    AssertEquals(1, LRecords.Count, 'Search should return matching records.');
    AssertEquals('user', TCrudRecord(LRecords[0]).Value('username'), 'Search should match display name.');
  finally
    FreeCrudRecordList(LRecords);
    LService.Free;
  end;
end;

procedure UserCrudSortsRecords;
var
  LRepo: TInMemoryUserRepository;
  LService: TUserService;
  LProvider: ICrudProvider;
  LRecords: TList;
begin
  BuildProvider(LRepo, LService, LProvider);
  LRecords := LProvider.List('', 'username', False, nil);
  try
    AssertEquals('user', TCrudRecord(LRecords[0]).Value('username'), 'Descending sort should put user first.');
  finally
    FreeCrudRecordList(LRecords);
    LService.Free;
  end;
end;

procedure UserCrudUpdatesThroughService;
var
  LRepo: TInMemoryUserRepository;
  LService: TUserService;
  LProvider: ICrudProvider;
  LRecord: TCrudRecord;
begin
  BuildProvider(LRepo, LService, LProvider);
  LRecord := TCrudRecord.Create;
  try
    LRecord.SetValue('username', 'user2');
    LRecord.SetValue('displayName', 'Usuario dos');
    LRecord.SetValue('email', 'user2@example.com');
    LRecord.SetValue('role', 'user');
    LRecord.SetValue('active', 'true');
    LRecord.SetValue('locked', 'false');
    LProvider.UpdateRecord('user', LRecord);

    AssertEquals('user2', LRepo.FindById('user').Username, 'Update should delegate to user service.');
  finally
    LRecord.Free;
    LService.Free;
  end;
end;

procedure UserCrudCreatesThroughService;
var
  LRepo: TInMemoryUserRepository;
  LService: TUserService;
  LProvider: ICrudProvider;
  LRecord: TCrudRecord;
  LId: string;
begin
  BuildProvider(LRepo, LService, LProvider);
  LRecord := TCrudRecord.Create;
  try
    LRecord.SetValue('username', 'newuser');
    LRecord.SetValue('displayName', 'Nuevo usuario');
    LRecord.SetValue('email', 'newuser@example.com');
    LRecord.SetValue('role', 'user');
    LRecord.SetValue('password', 'secret1');
    LId := LProvider.CreateRecord(LRecord);

    AssertTrue(LId <> '', 'Create should return new id.');
    AssertTrue(LRepo.FindByUsername('newuser') <> nil, 'Create should persist user in repository.');
  finally
    LRecord.Free;
    LService.Free;
  end;
end;

procedure UserCrudFiltersByColumn;
var
  LRepo: TInMemoryUserRepository;
  LService: TUserService;
  LProvider: ICrudProvider;
  LRecords: TList;
  LFilters: TStringList;
begin
  BuildProvider(LRepo, LService, LProvider);
  LFilters := TStringList.Create;
  try
    LFilters.Values['email'] := 'user@example.com';
    LRecords := LProvider.List('', '', True, LFilters);
    try
      AssertEquals(1, LRecords.Count, 'Column filter should reduce records.');
      AssertEquals('user', TCrudRecord(LRecords[0]).Value('username'), 'Column filter should match email.');
    finally
      FreeCrudRecordList(LRecords);
    end;
  finally
    LFilters.Free;
    LService.Free;
  end;
end;

procedure TaskCrudSchemaExposesFields;
var
  LRepo: ITaskRepository;
  LService: ITaskService;
  LProvider: ICrudProvider;
  LSchema: TCrudSchema;
begin
  BuildTaskProvider(LRepo, LService, LProvider);
  LSchema := LProvider.Schema;
  try
    AssertTrue(LSchema.FieldByName('title') <> nil, 'Task schema should include title.');
    AssertTrue(LSchema.FieldByName('completed') <> nil, 'Task schema should include completed.');
    AssertTrue(LSchema.FieldByName('createdAt') <> nil, 'Task schema should include createdAt.');
    AssertEquals(4, LSchema.FieldCount, 'Task schema should expose expected field count.');
    AssertEquals(Ord(cftBoolean), Ord(LSchema.FieldByName('completed').FieldType), 'Completed should be boolean.');
    AssertTrue(not LSchema.FieldByName('createdAt').Editable, 'CreatedAt should be read-only.');
  finally
    LSchema.Free;
  end;
end;

procedure TaskCrudCreatesUpdatesDeletesThroughService;
var
  LRepo: ITaskRepository;
  LService: ITaskService;
  LProvider: ICrudProvider;
  LRecord: TCrudRecord;
  LId: string;
  LTasks: TTaskItemArray;
begin
  BuildTaskProvider(LRepo, LService, LProvider);
  LRecord := TCrudRecord.Create;
  try
    LRecord.SetValue('title', 'Task from CRUD');
    LId := LProvider.CreateRecord(LRecord);
    LTasks := LService.ListTasks;
    AssertEquals(1, Length(LTasks), 'Create should persist task.');
    AssertEquals('Task from CRUD', LTasks[0].Title, 'Create should use title.');

    LRecord.SetValue('title', 'Updated from CRUD');
    LRecord.SetValue('completed', 'true');
    LProvider.UpdateRecord(LId, LRecord);
    LTasks := LService.ListTasks;
    AssertEquals('Updated from CRUD', LTasks[0].Title, 'Update should persist title.');
    AssertTrue(LTasks[0].IsCompleted, 'Update should persist completed state.');

    LProvider.DeleteRecord(LId);
    AssertEquals(0, Length(LService.ListTasks), 'Delete should remove task.');
  finally
    LRecord.Free;
  end;
end;

procedure TaskCrudListsFiltersAndSorts;
var
  LRepo: ITaskRepository;
  LService: ITaskService;
  LProvider: ICrudProvider;
  LFilters: TStringList;
  LRecords: TList;
  LTask: TTaskItem;
begin
  BuildTaskProvider(LRepo, LService, LProvider);
  LTask := LService.CreateTask('Beta task');
  LService.CreateTask('Alpha task');
  LService.UpdateTask(LTask.Id, LTask.Title, True);

  LFilters := TStringList.Create;
  try
    LFilters.Values['completed'] := 'true';
    LRecords := LProvider.List('', 'title', True, LFilters);
    try
      AssertEquals(1, LRecords.Count, 'Filter should return completed task only.');
      AssertEquals('Beta task', TCrudRecord(LRecords[0]).Value('title'), 'Filter should match completed task.');
    finally
      FreeCrudRecordList(LRecords);
    end;

    LFilters.Clear;
    LRecords := LProvider.List('', 'title', True, LFilters);
    try
      AssertEquals('Alpha task', TCrudRecord(LRecords[0]).Value('title'), 'Sort should order by title.');
    finally
      FreeCrudRecordList(LRecords);
    end;
  finally
    LFilters.Free;
  end;
end;

procedure RunCrudTests(var AFailures: Integer);
begin
  RunTest('Crud_user_schema_exposes_fields', UserCrudSchemaExposesFields, AFailures);
  RunTest('Crud_user_searches_records', UserCrudSearchesRecords, AFailures);
  RunTest('Crud_user_sorts_records', UserCrudSortsRecords, AFailures);
  RunTest('Crud_user_creates_through_service', UserCrudCreatesThroughService, AFailures);
  RunTest('Crud_user_updates_through_service', UserCrudUpdatesThroughService, AFailures);
  RunTest('Crud_user_filters_by_column', UserCrudFiltersByColumn, AFailures);
  RunTest('Crud_task_schema_exposes_fields', TaskCrudSchemaExposesFields, AFailures);
  RunTest('Crud_task_creates_updates_deletes_through_service', TaskCrudCreatesUpdatesDeletesThroughService, AFailures);
  RunTest('Crud_task_lists_filters_and_sorts', TaskCrudListsFiltersAndSorts, AFailures);
end;

end.
