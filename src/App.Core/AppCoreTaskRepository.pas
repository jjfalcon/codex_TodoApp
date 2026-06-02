unit AppCoreTaskRepository;

interface

uses
  Classes,
  AppCoreTaskItem;

type
  ITaskRepository = interface
    ['{B26A65C2-7DA2-4B90-8A41-6609427F4A6E}']
    procedure Add(ATask: TTaskItem);
    procedure Delete(const AId: string);
    function FindById(const AId: string): TTaskItem;
    function ListAll: TTaskItemArray;
    procedure Save(ATask: TTaskItem);
  end;

  TInMemoryTaskRepository = class(TInterfacedObject, ITaskRepository)
  private
    FItems: TList;
    function IndexOfId(const AId: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(ATask: TTaskItem);
    procedure Delete(const AId: string);
    function FindById(const AId: string): TTaskItem;
    function ListAll: TTaskItemArray;
    procedure Save(ATask: TTaskItem);
  end;

implementation

constructor TInMemoryTaskRepository.Create;
begin
  inherited Create;
  FItems := TList.Create;
end;

destructor TInMemoryTaskRepository.Destroy;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TObject(FItems[I]).Free;

  FItems.Free;
  inherited Destroy;
end;

procedure TInMemoryTaskRepository.Add(ATask: TTaskItem);
begin
  FItems.Add(ATask);
end;

procedure TInMemoryTaskRepository.Delete(const AId: string);
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex >= 0 then
  begin
    TObject(FItems[LIndex]).Free;
    FItems.Delete(LIndex);
  end;
end;

function TInMemoryTaskRepository.FindById(const AId: string): TTaskItem;
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex < 0 then
    Result := nil
  else
    Result := TTaskItem(FItems[LIndex]);
end;

function TInMemoryTaskRepository.IndexOfId(const AId: string): Integer;
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

function TInMemoryTaskRepository.ListAll: TTaskItemArray;
var
  I: Integer;
begin
  SetLength(Result, FItems.Count);
  for I := 0 to FItems.Count - 1 do
    Result[I] := TTaskItem(FItems[I]);
end;

procedure TInMemoryTaskRepository.Save(ATask: TTaskItem);
begin
  { In-memory tasks are stored by reference, so no copy is required. }
end;

end.
