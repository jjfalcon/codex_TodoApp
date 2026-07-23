unit AppCoreUserCrudProvider;

interface

uses
  Classes,
  SysUtils,
  AppCoreCrud,
  AppCoreUser,
  AppCoreUserService;

type
  TUserCrudProvider = class(TInterfacedObject, ICrudProvider)
  private
    FService: TUserService;
    FActorUserId: string;
    function BooleanText(AValue: Boolean): string;
    function RecordFromUser(AUser: TUser): TCrudRecord;
    function RoleFromText(const AValue: string): TUserRole;
    function RoleText(ARole: TUserRole): string;
    function RecordMatchesFilters(ARecord: TCrudRecord; AFilters: TStrings): Boolean;
    function RecordMatchesSearch(ARecord: TCrudRecord; const ASearchText: string): Boolean;
    procedure SortRecords(ARecords: TList; const ASortField: string; AAscending: Boolean);
  public
    constructor Create(AService: TUserService; const AActorUserId: string);
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

function CompareCrudRecords(Item1, Item2: Pointer): Integer;
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

constructor TUserCrudProvider.Create(AService: TUserService;
  const AActorUserId: string);
begin
  inherited Create;
  FService := AService;
  FActorUserId := AActorUserId;
end;

function TUserCrudProvider.BooleanText(AValue: Boolean): string;
begin
  if AValue then
    Result := 'true'
  else
    Result := 'false';
end;

function TUserCrudProvider.CreateRecord(ARecord: TCrudRecord): string;
var
  LUser: TUser;
begin
  LUser := FService.CreateUser(FActorUserId, ARecord.Value('username'),
    ARecord.Value('displayName'), ARecord.Value('email'),
    ARecord.Value('password'), RoleFromText(ARecord.Value('role')));
  Result := LUser.Id;
end;

procedure TUserCrudProvider.DeleteRecord(const AId: string);
begin
  FService.DeleteUser(FActorUserId, AId, True);
end;

function TUserCrudProvider.List(const ASearchText, ASortField: string;
  AAscending: Boolean; AFilters: TStrings): TList;
var
  LUsers: TList;
  I: Integer;
  LRecord: TCrudRecord;
begin
  Result := TList.Create;
  LUsers := FService.ListUsers('', []);
  try
    for I := 0 to LUsers.Count - 1 do
    begin
      LRecord := RecordFromUser(TUser(LUsers[I]));
      if RecordMatchesSearch(LRecord, ASearchText) and RecordMatchesFilters(LRecord, AFilters) then
        Result.Add(LRecord)
      else
        LRecord.Free;
    end;
  finally
    LUsers.Free;
  end;
  SortRecords(Result, ASortField, AAscending);
end;

function TUserCrudProvider.RecordMatchesFilters(ARecord: TCrudRecord;
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

function TUserCrudProvider.RecordFromUser(AUser: TUser): TCrudRecord;
begin
  Result := TCrudRecord.Create;
  Result.SetValue('id', AUser.Id);
  Result.SetValue('username', AUser.Username);
  Result.SetValue('displayName', AUser.DisplayName);
  Result.SetValue('email', AUser.Email);
  Result.SetValue('role', RoleText(AUser.Role));
  Result.SetValue('active', BooleanText(AUser.Active));
  Result.SetValue('locked', BooleanText(AUser.Locked));
  Result.SetValue('password', '');
end;

function TUserCrudProvider.RecordMatchesSearch(ARecord: TCrudRecord;
  const ASearchText: string): Boolean;
var
  LSearch: string;
begin
  LSearch := UpperCase(Trim(ASearchText));
  Result := (LSearch = '') or
    (Pos(LSearch, UpperCase(ARecord.Value('username'))) > 0) or
    (Pos(LSearch, UpperCase(ARecord.Value('displayName'))) > 0) or
    (Pos(LSearch, UpperCase(ARecord.Value('email'))) > 0);
end;

function TUserCrudProvider.RoleFromText(const AValue: string): TUserRole;
begin
  if SameText(AValue, 'admin') then
    Result := urAdmin
  else
    Result := urNormal;
end;

function TUserCrudProvider.RoleText(ARole: TUserRole): string;
begin
  if ARole = urAdmin then
    Result := 'admin'
  else
    Result := 'user';
end;

function TUserCrudProvider.Schema: TCrudSchema;
begin
  Result := TCrudSchema.Create;
  Result.AddField(TCrudFieldDef.Create('id', 'Id', cftString, False, False, False, 80));
  Result.AddField(TCrudFieldDef.Create('username', 'Usuario', cftString, True, True, True, 120));
  Result.AddField(TCrudFieldDef.Create('displayName', 'Nombre', cftString, True, True, True, 160));
  Result.AddField(TCrudFieldDef.Create('email', 'Email', cftString, True, True, True, 180));
  Result.AddField(TCrudFieldDef.Create('role', 'Rol', cftString, True, True, True, 80));
  Result.AddField(TCrudFieldDef.Create('active', 'Activo', cftBoolean, True, True, False, 60));
  Result.AddField(TCrudFieldDef.Create('locked', 'Bloqueado', cftBoolean, True, True, False, 80));
  Result.AddField(TCrudFieldDef.Create('password', 'Password', cftString, False, True, False, 120));
end;

procedure TUserCrudProvider.SortRecords(ARecords: TList; const ASortField: string;
  AAscending: Boolean);
begin
  if (ARecords = nil) or (ASortField = '') then
    Exit;
  GSortField := ASortField;
  GSortAscending := AAscending;
  ARecords.Sort(CompareCrudRecords);
end;

procedure TUserCrudProvider.UpdateRecord(const AId: string; ARecord: TCrudRecord);
begin
  FService.UpdateUser(FActorUserId, AId, ARecord.Value('username'),
    ARecord.Value('displayName'), ARecord.Value('email'),
    SameText(ARecord.Value('active'), 'true'), RoleFromText(ARecord.Value('role')),
    SameText(ARecord.Value('locked'), 'true'));
  if Trim(ARecord.Value('password')) <> '' then
    FService.ChangePassword(FActorUserId, AId, ARecord.Value('password'));
end;

end.
