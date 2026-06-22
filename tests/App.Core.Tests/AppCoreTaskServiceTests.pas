unit AppCoreTaskServiceTests;

interface

procedure RunTaskServiceTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCoreClock,
  AppCoreTaskFileRepository,
  AppCoreTaskItem,
  AppCoreTaskRepository,
  AppCoreTaskService;

type
  TFixedClock = class(TInterfacedObject, IClock)
  private
    FNow: TDateTime;
  public
    constructor Create(const ANow: TDateTime);
    function Now: TDateTime;
  end;

constructor TFixedClock.Create(const ANow: TDateTime);
begin
  inherited Create;
  FNow := ANow;
end;

function TFixedClock.Now: TDateTime;
begin
  Result := FNow;
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

procedure AssertRaisesValidationError(const ATitle: string);
var
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
begin
  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TInMemoryTaskRepository.Create;
  LService := TTaskService.Create(LRepository, LClock);

  try
    LService.CreateTask(ATitle);
  except
    on E: ETaskValidationError do
      Exit;
  end;

  raise Exception.Create('Expected ETaskValidationError.');
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

procedure CreateTaskStoresTrimmedPendingTask;
var
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
  LTask: TTaskItem;
  LTasks: TTaskItemArray;
begin
  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TInMemoryTaskRepository.Create;
  LService := TTaskService.Create(LRepository, LClock);

  LTask := LService.CreateTask('  Prepare release  ');
  LTasks := LService.ListTasks;

  AssertEquals('Prepare release', LTask.Title, 'Title should be trimmed.');
  AssertEquals(Ord(tsPending), Ord(LTask.Status), 'New task should be pending.');
  AssertEquals(1, Length(LTasks), 'Task should be stored.');
end;

procedure CreateTaskRejectsEmptyTitle;
begin
  AssertRaisesValidationError('   ');
end;

procedure CompleteTaskMarksTaskAsCompleted;
var
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
  LTask: TTaskItem;
begin
  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TInMemoryTaskRepository.Create;
  LService := TTaskService.Create(LRepository, LClock);

  LTask := LService.CreateTask('Write test');
  LTask := LService.CompleteTask(LTask.Id);

  AssertTrue(LTask.IsCompleted, 'Task should be completed.');
  AssertTrue(LTask.CompletedAt = LClock.Now, 'Completed date should come from clock.');
end;

procedure DeleteTaskRemovesTask;
var
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
  LTask: TTaskItem;
begin
  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TInMemoryTaskRepository.Create;
  LService := TTaskService.Create(LRepository, LClock);

  LTask := LService.CreateTask('Remove me');
  LService.DeleteTask(LTask.Id);

  AssertEquals(0, Length(LService.ListTasks), 'Task should be removed.');
end;

procedure SearchTasksReturnsMatchingTitles;
var
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
  LResults: TTaskItemArray;
begin
  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TInMemoryTaskRepository.Create;
  LService := TTaskService.Create(LRepository, LClock);

  LService.CreateTask('Call customer');
  LService.CreateTask('Prepare invoice');
  LService.CreateTask('Customer follow up');

  LResults := LService.SearchTasks('customer');

  AssertEquals(2, Length(LResults), 'Search should match two tasks.');
end;

procedure ListPendingTasksReturnsOnlyPendingTasks;
var
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
  LTask: TTaskItem;
  LResults: TTaskItemArray;
begin
  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TInMemoryTaskRepository.Create;
  LService := TTaskService.Create(LRepository, LClock);

  LTask := LService.CreateTask('Done task');
  LService.CreateTask('Pending task');
  LService.CompleteTask(LTask.Id);

  LResults := LService.ListPendingTasks;

  AssertEquals(1, Length(LResults), 'Only pending tasks should be returned.');
  AssertEquals('Pending task', LResults[0].Title, 'Completed tasks should be excluded.');
  AssertEquals(Ord(tsPending), Ord(LResults[0].Status), 'Returned task should be pending.');
end;

function TempTaskFileName(const AName: string): string;
begin
  Result := ExtractFilePath(ParamStr(0)) + AName;
end;

procedure FileRepositoryPersistsCreatedTasks;
var
  LFileName: string;
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
  LTasks: TTaskItemArray;
begin
  LFileName := TempTaskFileName('task_repository_created_test.json');
  if FileExists(LFileName) then
    DeleteFile(LFileName);

  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TFileTaskRepository.Create(LFileName);
  LService := TTaskService.Create(LRepository, LClock);
  LService.CreateTask('Persist me');

  LService := nil;
  LRepository := nil;

  LRepository := TFileTaskRepository.Create(LFileName);
  LTasks := LRepository.ListAll;

  AssertEquals(1, Length(LTasks), 'File repository should reload stored task.');
  AssertEquals('Persist me', LTasks[0].Title, 'Reloaded task should keep title.');
  AssertEquals(Ord(tsPending), Ord(LTasks[0].Status), 'Reloaded task should keep pending status.');

  LRepository := nil;
  if FileExists(LFileName) then
    DeleteFile(LFileName);
end;

procedure FileRepositoryPersistsCompletedTasks;
var
  LFileName: string;
  LClock: IClock;
  LRepository: ITaskRepository;
  LService: ITaskService;
  LTask: TTaskItem;
  LTasks: TTaskItemArray;
begin
  LFileName := TempTaskFileName('task_repository_completed_test.json');
  if FileExists(LFileName) then
    DeleteFile(LFileName);

  LClock := TFixedClock.Create(EncodeDate(2026, 4, 30));
  LRepository := TFileTaskRepository.Create(LFileName);
  LService := TTaskService.Create(LRepository, LClock);
  LTask := LService.CreateTask('Complete me');
  LService.CompleteTask(LTask.Id);

  LService := nil;
  LRepository := nil;

  LRepository := TFileTaskRepository.Create(LFileName);
  LTasks := LRepository.ListAll;

  AssertEquals(1, Length(LTasks), 'File repository should reload completed task.');
  AssertTrue(LTasks[0].IsCompleted, 'Reloaded task should keep completed status.');
  AssertTrue(LTasks[0].CompletedAt = LClock.Now, 'Reloaded task should keep completed date.');

  LRepository := nil;
  if FileExists(LFileName) then
    DeleteFile(LFileName);
end;

procedure RunTaskServiceTests(var AFailures: Integer);
begin
  RunTest('CreateTaskStoresTrimmedPendingTask', CreateTaskStoresTrimmedPendingTask, AFailures);
  RunTest('CreateTaskRejectsEmptyTitle', CreateTaskRejectsEmptyTitle, AFailures);
  RunTest('CompleteTaskMarksTaskAsCompleted', CompleteTaskMarksTaskAsCompleted, AFailures);
  RunTest('DeleteTaskRemovesTask', DeleteTaskRemovesTask, AFailures);
  RunTest('SearchTasksReturnsMatchingTitles', SearchTasksReturnsMatchingTitles, AFailures);
  RunTest('ListPendingTasksReturnsOnlyPendingTasks', ListPendingTasksReturnsOnlyPendingTasks, AFailures);
  RunTest('FileRepositoryPersistsCreatedTasks', FileRepositoryPersistsCreatedTasks, AFailures);
  RunTest('FileRepositoryPersistsCompletedTasks', FileRepositoryPersistsCompletedTasks, AFailures);
end;

end.
