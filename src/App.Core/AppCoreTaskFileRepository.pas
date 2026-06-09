unit AppCoreTaskFileRepository;

interface

uses
  Classes,
  SysUtils,
  AppCoreJsonUtils,
  AppCoreTaskItem,
  AppCoreTaskRepository;

type
  TFileTaskRepository = class(TInterfacedObject, ITaskRepository)
  private
    FFileName: string;
    FItems: TList;

    procedure FreeItems;
    function IndexOfId(const AId: string): Integer;
    procedure LoadFromFile;
    procedure SaveToFile;
    function StatusToJson(AStatus: TTaskStatus): string;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    procedure Add(ATask: TTaskItem);
    procedure Delete(const AId: string);
    function FindById(const AId: string): TTaskItem;
    function ListAll: TTaskItemArray;
    procedure Save(ATask: TTaskItem);
  end;

implementation

constructor TFileTaskRepository.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FItems := TList.Create;
  LoadFromFile;
end;

destructor TFileTaskRepository.Destroy;
begin
  FreeItems;
  FItems.Free;
  inherited Destroy;
end;

procedure TFileTaskRepository.Add(ATask: TTaskItem);
begin
  FItems.Add(ATask);
  SaveToFile;
end;

procedure TFileTaskRepository.Delete(const AId: string);
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex >= 0 then
  begin
    TObject(FItems[LIndex]).Free;
    FItems.Delete(LIndex);
    SaveToFile;
  end;
end;

function TFileTaskRepository.FindById(const AId: string): TTaskItem;
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex < 0 then
    Result := nil
  else
    Result := TTaskItem(FItems[LIndex]);
end;

procedure TFileTaskRepository.FreeItems;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TObject(FItems[I]).Free;
  FItems.Clear;
end;

function TFileTaskRepository.IndexOfId(const AId: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if TTaskItem(FItems[I]).Id = AId then
    begin
      Result := I;
      Exit;
    end;
end;

function TFileTaskRepository.ListAll: TTaskItemArray;
var
  I: Integer;
begin
  SetLength(Result, FItems.Count);
  for I := 0 to FItems.Count - 1 do
    Result[I] := TTaskItem(FItems[I]);
end;

procedure TFileTaskRepository.LoadFromFile;
var
  LFile: TStringList;
  LObjects: TStringList;
  I: Integer;
  LTask: TTaskItem;
  LStatus: string;
begin
  if not FileExists(FFileName) then
    Exit;

  LFile := TStringList.Create;
  LObjects := nil;
  try
    LFile.LoadFromFile(FFileName);
    LObjects := ExtractJsonObjects(LFile.Text);

    for I := 0 to LObjects.Count - 1 do
    begin
      LTask := TTaskItem.Create(ExtractJsonString(LObjects[I], 'id'),
        ExtractJsonString(LObjects[I], 'title'),
        ExtractJsonDate(LObjects[I], 'createdAt'));
      LTask.CompletedAt := ExtractJsonDate(LObjects[I], 'completedAt');

      LStatus := ExtractJsonString(LObjects[I], 'status');
      if LStatus = 'completed' then
        LTask.Status := tsCompleted
      else
        LTask.Status := tsPending;

      FItems.Add(LTask);
    end;
  finally
    LObjects.Free;
    LFile.Free;
  end;
end;

procedure TFileTaskRepository.Save(ATask: TTaskItem);
begin
  SaveToFile;
end;

procedure TFileTaskRepository.SaveToFile;
var
  LFile: TStringList;
  I: Integer;
  LTask: TTaskItem;
  LLineEnd: string;
begin
  LFile := TStringList.Create;
  try
    LFile.Add('[');
    for I := 0 to FItems.Count - 1 do
    begin
      LTask := TTaskItem(FItems[I]);
      if I = FItems.Count - 1 then
        LLineEnd := ''
      else
        LLineEnd := ',';

      LFile.Add('  {');
      LFile.Add('    "id": "' + EscapeJson(LTask.Id) + '",');
      LFile.Add('    "title": "' + EscapeJson(LTask.Title) + '",');
      LFile.Add('    "createdAt": ' + DateTimeToJson(LTask.CreatedAt) + ',');
      LFile.Add('    "completedAt": ' + NullOrDateTimeToJson(LTask.CompletedAt) + ',');
      LFile.Add('    "status": "' + StatusToJson(LTask.Status) + '"');
      LFile.Add('  }' + LLineEnd);
    end;
    LFile.Add(']');
    LFile.SaveToFile(FFileName);
  finally
    LFile.Free;
  end;
end;

function TFileTaskRepository.StatusToJson(AStatus: TTaskStatus): string;
begin
  if AStatus = tsCompleted then
    Result := 'completed'
  else
    Result := 'pending';
end;

end.
