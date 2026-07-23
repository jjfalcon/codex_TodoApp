unit AppCoreCrud;

interface

uses
  Classes,
  SysUtils;

type
  TCrudEditMode = (emNone, emGrid, emDetail);
  TCrudFieldType = (cftString, cftBoolean, cftInteger, cftDateTime);

  TCrudFieldDef = class
  private
    FName: string;
    FCaption: string;
    FFieldType: TCrudFieldType;
    FVisible: Boolean;
    FEditable: Boolean;
    FRequired: Boolean;
    FWidth: Integer;
  public
    constructor Create(const AName, ACaption: string; AFieldType: TCrudFieldType;
      AVisible, AEditable, ARequired: Boolean; AWidth: Integer);
    property Name: string read FName;
    property Caption: string read FCaption;
    property FieldType: TCrudFieldType read FFieldType;
    property Visible: Boolean read FVisible;
    property Editable: Boolean read FEditable;
    property Required: Boolean read FRequired;
    property Width: Integer read FWidth;
  end;

  TCrudSchema = class
  private
    FFields: TList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddField(AField: TCrudFieldDef);
    function FieldCount: Integer;
    function FieldAt(AIndex: Integer): TCrudFieldDef;
    function FieldByName(const AName: string): TCrudFieldDef;
  end;

  TCrudRecord = class
  private
    FValues: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function Value(const AName: string): string;
    procedure SetValue(const AName, AValue: string);
  end;

  ICrudProvider = interface
    ['{2776C0F0-5A2B-44B5-A49A-7BB76C22B9D2}']
    function Schema: TCrudSchema;
    function List(const ASearchText, ASortField: string; AAscending: Boolean;
      AFilters: TStrings): TList;
    function CreateRecord(ARecord: TCrudRecord): string;
    procedure UpdateRecord(const AId: string; ARecord: TCrudRecord);
    procedure DeleteRecord(const AId: string);
  end;

  ICrudGridLayoutRepository = interface
    ['{599E673B-9BA6-4A4A-B9CE-38BDB406AA33}']
    function ReadGridValue(const AGridKey, AName: string): string;
    procedure WriteGridValue(const AGridKey, AName, AValue: string);
  end;

procedure FreeCrudRecordList(AList: TList);

implementation

constructor TCrudFieldDef.Create(const AName, ACaption: string;
  AFieldType: TCrudFieldType; AVisible, AEditable, ARequired: Boolean;
  AWidth: Integer);
begin
  inherited Create;
  FName := AName;
  FCaption := ACaption;
  FFieldType := AFieldType;
  FVisible := AVisible;
  FEditable := AEditable;
  FRequired := ARequired;
  FWidth := AWidth;
end;

constructor TCrudSchema.Create;
begin
  inherited Create;
  FFields := TList.Create;
end;

destructor TCrudSchema.Destroy;
var
  I: Integer;
begin
  for I := 0 to FFields.Count - 1 do
    TObject(FFields[I]).Free;
  FFields.Free;
  inherited Destroy;
end;

procedure TCrudSchema.AddField(AField: TCrudFieldDef);
begin
  FFields.Add(AField);
end;

function TCrudSchema.FieldAt(AIndex: Integer): TCrudFieldDef;
begin
  Result := TCrudFieldDef(FFields[AIndex]);
end;

function TCrudSchema.FieldByName(const AName: string): TCrudFieldDef;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to FFields.Count - 1 do
    if SameText(FieldAt(I).Name, AName) then
    begin
      Result := FieldAt(I);
      Exit;
    end;
end;

function TCrudSchema.FieldCount: Integer;
begin
  Result := FFields.Count;
end;

constructor TCrudRecord.Create;
begin
  inherited Create;
  FValues := TStringList.Create;
end;

destructor TCrudRecord.Destroy;
begin
  FValues.Free;
  inherited Destroy;
end;

function TCrudRecord.Value(const AName: string): string;
begin
  Result := FValues.Values[AName];
end;

procedure TCrudRecord.SetValue(const AName, AValue: string);
begin
  FValues.Values[AName] := AValue;
end;

procedure FreeCrudRecordList(AList: TList);
var
  I: Integer;
begin
  if AList = nil then
    Exit;
  for I := 0 to AList.Count - 1 do
    TObject(AList[I]).Free;
  AList.Free;
end;

end.
