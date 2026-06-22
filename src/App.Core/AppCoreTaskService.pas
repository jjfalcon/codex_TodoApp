unit AppCoreTaskService;

interface

uses
  SysUtils,
  AppCoreClock,
  AppCoreTaskItem,
  AppCoreTaskRepository;

type
  ETaskValidationError = class(Exception);
  ETaskNotFoundError = class(Exception);

  ITaskService = interface
    ['{99B372AE-BC7E-47AF-91AE-9A0DA9B451C2}']
    function CreateTask(const ATitle: string): TTaskItem;
    function CompleteTask(const AId: string): TTaskItem;
    procedure DeleteTask(const AId: string);
    function ListTasks: TTaskItemArray;
    function ListPendingTasks: TTaskItemArray;
    function SearchTasks(const AQuery: string): TTaskItemArray;
  end;

  TTaskService = class(TInterfacedObject, ITaskService)
  private
    FRepository: ITaskRepository;
    FClock: IClock;

    procedure EnsureTitleIsValid(const ATitle: string);
    function NewId: string;
    function RequireTask(const AId: string): TTaskItem;
  public
    constructor Create(const ARepository: ITaskRepository; const AClock: IClock);

    function CreateTask(const ATitle: string): TTaskItem;
    function CompleteTask(const AId: string): TTaskItem;
    procedure DeleteTask(const AId: string);
    function ListTasks: TTaskItemArray;
    function ListPendingTasks: TTaskItemArray;
    function SearchTasks(const AQuery: string): TTaskItemArray;
  end;

implementation

constructor TTaskService.Create(const ARepository: ITaskRepository; const AClock: IClock);
begin
  inherited Create;
  FRepository := ARepository;
  FClock := AClock;
end;

function TTaskService.CreateTask(const ATitle: string): TTaskItem;
begin
  EnsureTitleIsValid(ATitle);

  Result := TTaskItem.Create(NewId, Trim(ATitle), FClock.Now);
  FRepository.Add(Result);
end;

function TTaskService.CompleteTask(const AId: string): TTaskItem;
begin
  Result := RequireTask(AId);
  Result.Status := tsCompleted;
  Result.CompletedAt := FClock.Now;
  FRepository.Save(Result);
end;

procedure TTaskService.DeleteTask(const AId: string);
begin
  RequireTask(AId);
  FRepository.Delete(AId);
end;

procedure TTaskService.EnsureTitleIsValid(const ATitle: string);
begin
  if Trim(ATitle) = '' then
    raise ETaskValidationError.Create('Task title is required.');
end;

function TTaskService.ListTasks: TTaskItemArray;
begin
  Result := FRepository.ListAll;
end;

function TTaskService.ListPendingTasks: TTaskItemArray;
var
  LAll: TTaskItemArray;
  I: Integer;
  LCount: Integer;
begin
  LAll := ListTasks;
  SetLength(Result, Length(LAll));
  LCount := 0;

  for I := 0 to Length(LAll) - 1 do
    if LAll[I].Status = tsPending then
    begin
      Result[LCount] := LAll[I];
      Inc(LCount);
    end;

  SetLength(Result, LCount);
end;

function TTaskService.NewId: string;
var
  LGuid: TGUID;
begin
  CreateGUID(LGuid);
  Result := GUIDToString(LGuid);
end;

function TTaskService.RequireTask(const AId: string): TTaskItem;
begin
  Result := FRepository.FindById(AId);
  if Result = nil then
    raise ETaskNotFoundError.Create('Task was not found.');
end;

function TTaskService.SearchTasks(const AQuery: string): TTaskItemArray;
var
  LAll: TTaskItemArray;
  LQuery: string;
  I: Integer;
  LCount: Integer;
begin
  LQuery := UpperCase(Trim(AQuery));
  if LQuery = '' then
  begin
    Result := ListTasks;
    Exit;
  end;

  LAll := ListTasks;
  SetLength(Result, Length(LAll));
  LCount := 0;

  for I := 0 to Length(LAll) - 1 do
    if Pos(LQuery, UpperCase(LAll[I].Title)) > 0 then
    begin
      Result[LCount] := LAll[I];
      Inc(LCount);
    end;

  SetLength(Result, LCount);
end;

end.
