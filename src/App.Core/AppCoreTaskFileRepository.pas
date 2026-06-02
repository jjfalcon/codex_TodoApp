unit AppCoreTaskFileRepository;

interface

uses
  Classes,
  SysUtils,
  AppCoreTaskItem,
  AppCoreTaskRepository;

type
  TFileTaskRepository = class(TInterfacedObject, ITaskRepository)
  private
    FFileName: string;
    FItems: TList;

    function DateTimeToJson(const AValue: TDateTime): string;
    procedure FreeItems;
    function IndexOfId(const AId: string): Integer;
    procedure LoadFromFile;
    function NullOrDateTimeToJson(const AValue: TDateTime): string;
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

function FindFrom(const AText, APattern: string; AStart: Integer): Integer;
var
  I: Integer;
  J: Integer;
  LMatches: Boolean;
begin
  Result := 0;
  if (APattern = '') or (AStart < 1) then
    Exit;

  for I := AStart to Length(AText) - Length(APattern) + 1 do
  begin
    LMatches := True;
    for J := 1 to Length(APattern) do
      if AText[I + J - 1] <> APattern[J] then
      begin
        LMatches := False;
        Break;
      end;

    if LMatches then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function EscapeJson(const AValue: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AValue) do
    case AValue[I] of
      '\':
        Result := Result + '\\';
      '"':
        Result := Result + '\"';
      #13:
        Result := Result + '\r';
      #10:
        Result := Result + '\n';
    else
      Result := Result + AValue[I];
    end;
end;

function UnescapeJson(const AValue: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(AValue) do
  begin
    if (AValue[I] = '\') and (I < Length(AValue)) then
    begin
      Inc(I);
      case AValue[I] of
        '\':
          Result := Result + '\';
        '"':
          Result := Result + '"';
        'r':
          Result := Result + #13;
        'n':
          Result := Result + #10;
      else
        Result := Result + AValue[I];
      end;
    end
    else
      Result := Result + AValue[I];

    Inc(I);
  end;
end;

function ExtractJsonString(const AObject, AName: string): string;
var
  LKey: string;
  LPos: Integer;
  I: Integer;
  LEscaped: Boolean;
begin
  Result := '';
  LKey := '"' + AName + '"';
  LPos := FindFrom(AObject, LKey, 1);
  if LPos = 0 then
    Exit;

  LPos := FindFrom(AObject, ':', LPos + Length(LKey));
  if LPos = 0 then
    Exit;

  Inc(LPos);
  while (LPos <= Length(AObject)) and (AObject[LPos] <= ' ') do
    Inc(LPos);

  if (LPos > Length(AObject)) or (AObject[LPos] <> '"') then
    Exit;

  Inc(LPos);
  LEscaped := False;
  for I := LPos to Length(AObject) do
  begin
    if LEscaped then
    begin
      Result := Result + '\' + AObject[I];
      LEscaped := False;
    end
    else if AObject[I] = '\' then
      LEscaped := True
    else if AObject[I] = '"' then
    begin
      Result := UnescapeJson(Result);
      Exit;
    end
    else
      Result := Result + AObject[I];
  end;
end;

function ExtractJsonDate(const AObject, AName: string): TDateTime;
var
  LValue: string;
begin
  LValue := ExtractJsonString(AObject, AName);
  if LValue = '' then
    Result := 0
  else
    Result := EncodeDate(StrToInt(Copy(LValue, 1, 4)),
      StrToInt(Copy(LValue, 6, 2)), StrToInt(Copy(LValue, 9, 2))) +
      EncodeTime(StrToInt(Copy(LValue, 12, 2)), StrToInt(Copy(LValue, 15, 2)),
      StrToInt(Copy(LValue, 18, 2)), 0);
end;

function ExtractTaskObjects(const AJson: string): TStringList;
var
  I: Integer;
  LStart: Integer;
  LDepth: Integer;
  LInString: Boolean;
  LEscaped: Boolean;
begin
  Result := TStringList.Create;
  LStart := 0;
  LDepth := 0;
  LInString := False;
  LEscaped := False;

  for I := 1 to Length(AJson) do
  begin
    if LInString then
    begin
      if LEscaped then
        LEscaped := False
      else if AJson[I] = '\' then
        LEscaped := True
      else if AJson[I] = '"' then
        LInString := False;
    end
    else
    begin
      if AJson[I] = '"' then
        LInString := True
      else if AJson[I] = '{' then
      begin
        if LDepth = 0 then
          LStart := I;
        Inc(LDepth);
      end
      else if AJson[I] = '}' then
      begin
        Dec(LDepth);
        if (LDepth = 0) and (LStart > 0) then
          Result.Add(Copy(AJson, LStart, I - LStart + 1));
      end;
    end;
  end;
end;

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

function TFileTaskRepository.DateTimeToJson(const AValue: TDateTime): string;
begin
  Result := '"' + FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', AValue) + '"';
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
    LObjects := ExtractTaskObjects(LFile.Text);

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

function TFileTaskRepository.NullOrDateTimeToJson(const AValue: TDateTime): string;
begin
  if AValue = 0 then
    Result := 'null'
  else
    Result := DateTimeToJson(AValue);
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
