unit AppCoreTaskCrudProvider;

interface

uses
  Classes,
  SysUtils,
  AppCoreCrud,
  AppCoreTaskItem,
  AppCoreTaskService;

type
  TTaskCrudProvider = class(TInterfacedObject, ICrudProvider)
  private
    FService: ITaskService;
    function BooleanText(AValue: Boolean): string;
    function RecordFromTask(ATask: TTaskItem): TCrudRecord;
    function RecordMatchesFilters(ARecord: TCrudRecord; AFilters: TStrings): Boolean;
    function RecordMatchesSearch(ARecord: TCrudRecord; const ASearchText: string): Boolean;
    procedure SortRecords(ARecords: TList; const ASortField: string; AAscending: Boolean);
  public
    constructor Create(const AService: ITaskService);
    function Schema: TCrudSchema;
    function List(const ASearchText, ASortField: string; AAscending: Boolean;
      AFilters: TStrings): TList;
    function CreateRecord(ARecord: TCrudRecord): string;
    procedure UpdateRecord(const AId: string; ARecord: TCrudRecord);
    procedure DeleteRecord(const AId: string);
  end;

implementation

var
  GSortField: string;
  GSortAscending: Boolean;

function CompareTaskCrudRecords(Item1, Item2: Pointer): Integer;
var
  LLeft: string;
  LRight: string;
begin
  LLeft := TCrudRecord(Item1).Value(GSortField);
  LRight := TCrudRecord(Item2).Value(GSortField);
  Result := AnsiCompareText(LLeft, LRight);
  if not GSortAscending then
    Result := -Result;
end;

constructor TTaskCrudProvider.Create(const AService: ITaskService);
begin
  inherited Create;
  FService := AService;
end;

function TTaskCrudProvider.BooleanText(AValue: Boolean): string;
begin
  if AValue then
    Result := 'true'
  else
    Result := 'false';
end;

function TTaskCrudProvider.CreateRecord(ARecord: TCrudRecord): string;
var
  LTask: TTaskItem;
begin
  LTask := FService.CreateTask(ARecord.Value('title'));
  Result := LTask.Id;
  if SameText(ARecord.Value('completed'), 'true') then
    FService.UpdateTask(Result, LTask.Title, True);
end;

procedure TTaskCrudProvider.DeleteRecord(const AId: string);
begin
  FService.DeleteTask(AId);
end;

function TTaskCrudProvider.List(const ASearchText, ASortField: string;
  AAscending: Boolean; AFilters: TStrings): TList;
var
  LTasks: TTaskItemArray;
  I: Integer;
  LRecord: TCrudRecord;
begin
  Result := TList.Create;
  LTasks := FService.ListTasks;
  for I := 0 to Length(LTasks) - 1 do
  begin
    LRecord := RecordFromTask(LTasks[I]);
    if RecordMatchesSearch(LRecord, ASearchText) and RecordMatchesFilters(LRecord, AFilters) then
      Result.Add(LRecord)
    else
      LRecord.Free;
  end;
  SortRecords(Result, ASortField, AAscending);
end;

function TTaskCrudProvider.RecordFromTask(ATask: TTaskItem): TCrudRecord;
begin
  Result := TCrudRecord.Create;
  Result.SetValue('id', ATask.Id);
  Result.SetValue('title', ATask.Title);
  Result.SetValue('completed', BooleanText(ATask.IsCompleted));
  Result.SetValue('createdAt', DateTimeToStr(ATask.CreatedAt));
end;

function TTaskCrudProvider.RecordMatchesFilters(ARecord: TCrudRecord;
  AFilters: TStrings): Boolean;
var
  I: Integer;
  LName: string;
  LValue: string;
begin
  Result := True;
  if AFilters = nil then
    Exit;
  for I := 0 to AFilters.Count - 1 do
  begin
    LName := AFilters.Names[I];
    LValue := Trim(AFilters.Values[LName]);
    if LValue = '' then
      Continue;
    if Pos(UpperCase(LValue), UpperCase(ARecord.Value(LName))) = 0 then
    begin
      Result := False;
      Exit;
    end;
  end;
end;

function TTaskCrudProvider.RecordMatchesSearch(ARecord: TCrudRecord;
  const ASearchText: string): Boolean;
var
  LSearch: string;
begin
  LSearch := UpperCase(Trim(ASearchText));
  Result := (LSearch = '') or (Pos(LSearch, UpperCase(ARecord.Value('title'))) > 0);
end;

function TTaskCrudProvider.Schema: TCrudSchema;
begin
  Result := TCrudSchema.Create;
  Result.AddField(TCrudFieldDef.Create('id', 'Id', cftString, False, False, False, 80));
  Result.AddField(TCrudFieldDef.Create('title', 'Titulo', cftString, True, True, True, 220));
  Result.AddField(TCrudFieldDef.Create('completed', 'Completada', cftBoolean, True, True, False, 80));
  Result.AddField(TCrudFieldDef.Create('createdAt', 'Creada', cftDateTime, True, False, False, 120));
end;

procedure TTaskCrudProvider.SortRecords(ARecords: TList; const ASortField: string;
  AAscending: Boolean);
begin
  if (ARecords = nil) or (ASortField = '') then
    Exit;
  GSortField := ASortField;
  GSortAscending := AAscending;
  ARecords.Sort(CompareTaskCrudRecords);
end;

procedure TTaskCrudProvider.UpdateRecord(const AId: string; ARecord: TCrudRecord);
begin
  FService.UpdateTask(AId, ARecord.Value('title'), SameText(ARecord.Value('completed'), 'true'));
end;

end.
