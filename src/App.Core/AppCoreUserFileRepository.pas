unit AppCoreUserFileRepository;

interface

uses
  Classes,
  SysUtils,
  AppCoreJsonUtils,
  AppCoreUser,
  AppCoreUserRepository;

type
  TFileUserRepository = class(TInterfacedObject, IUserRepository)
  private
    FFileName: string;
    FItems: TList;

    function IndexOfId(const AId: string): Integer;
    function IndexOfUsername(const AUsername: string): Integer;
    function IndexOfEmail(const AEmail: string): Integer;
    procedure FreeItems;
    procedure LoadFromFile;
    procedure SaveToFile;
    function RoleToJson(ARole: TUserRole): string;
    function JsonToRole(const AValue: string): TUserRole;
    function UserToJson(AUser: TUser): string;
    function JsonToUser(const AJson: string): TUser;
  public
    constructor Create(const AFileName: string);
    destructor Destroy; override;

    function All: TList;
    function FindById(const AId: string): TUser;
    function FindByUsername(const AUsername: string): TUser;
    function FindByEmail(const AEmail: string): TUser;
    procedure Save(AUser: TUser);
  end;

implementation

constructor TFileUserRepository.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FItems := TList.Create;
  LoadFromFile;
end;

destructor TFileUserRepository.Destroy;
begin
  FreeItems;
  FItems.Free;
  inherited Destroy;
end;

function TFileUserRepository.All: TList;
begin
  Result := FItems;
end;

function TFileUserRepository.FindById(const AId: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

function TFileUserRepository.FindByUsername(const AUsername: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfUsername(AUsername);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

function TFileUserRepository.FindByEmail(const AEmail: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfEmail(AEmail);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

procedure TFileUserRepository.Save(AUser: TUser);
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AUser.Id);
  if LIndex < 0 then
    FItems.Add(AUser)
  else if TUser(FItems[LIndex]) <> AUser then
  begin
    TObject(FItems[LIndex]).Free;
    FItems[LIndex] := AUser;
  end;
  SaveToFile;
end;

function TFileUserRepository.IndexOfId(const AId: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if TUser(FItems[I]).Id = AId then
    begin
      Result := I;
      Exit;
    end;
end;

function TFileUserRepository.IndexOfUsername(const AUsername: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if UpperCase(TUser(FItems[I]).Username) = UpperCase(AUsername) then
    begin
      Result := I;
      Exit;
    end;
end;

function TFileUserRepository.IndexOfEmail(const AEmail: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if UpperCase(TUser(FItems[I]).Email) = UpperCase(AEmail) then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TFileUserRepository.FreeItems;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TObject(FItems[I]).Free;
  FItems.Clear;
end;

procedure TFileUserRepository.LoadFromFile;
var
  LFile: TStringList;
  LObjects: TStringList;
  I: Integer;
begin
  if not FileExists(FFileName) then
    Exit;

  LFile := TStringList.Create;
  LObjects := nil;
  try
    LFile.LoadFromFile(FFileName);
    LObjects := ExtractJsonObjects(LFile.Text);

    for I := 0 to LObjects.Count - 1 do
      FItems.Add(JsonToUser(LObjects[I]));
  finally
    LObjects.Free;
    LFile.Free;
  end;
end;

procedure TFileUserRepository.SaveToFile;
var
  LFile: TStringList;
  I: Integer;
  LLineEnd: string;
begin
  LFile := TStringList.Create;
  try
    LFile.Add('[');
    for I := 0 to FItems.Count - 1 do
    begin
      if I = FItems.Count - 1 then
        LLineEnd := ''
      else
        LLineEnd := ',';

      LFile.Add('  ' + UserToJson(TUser(FItems[I])) + LLineEnd);
    end;
    LFile.Add(']');
    LFile.SaveToFile(FFileName);
  finally
    LFile.Free;
  end;
end;

function TFileUserRepository.RoleToJson(ARole: TUserRole): string;
begin
  if ARole = urAdmin then
    Result := 'admin'
  else
    Result := 'normal';
end;

function TFileUserRepository.JsonToRole(const AValue: string): TUserRole;
begin
  if AValue = 'admin' then
    Result := urAdmin
  else
    Result := urNormal;
end;

function TFileUserRepository.UserToJson(AUser: TUser): string;
begin
  Result := '{';
  Result := Result + '"id": "' + EscapeJson(AUser.Id) + '",';
  Result := Result + '"username": "' + EscapeJson(AUser.Username) + '",';
  Result := Result + '"displayName": "' + EscapeJson(AUser.DisplayName) + '",';
  Result := Result + '"email": "' + EscapeJson(AUser.Email) + '",';
  Result := Result + '"passwordHash": "' + EscapeJson(AUser.PasswordHash) + '",';
  Result := Result + '"salt": "' + EscapeJson(AUser.Salt) + '",';
  Result := Result + '"active": ' + BoolToJson(AUser.Active) + ',';
  Result := Result + '"deleted": ' + BoolToJson(AUser.Deleted) + ',';
  Result := Result + '"role": "' + RoleToJson(AUser.Role) + '",';
  Result := Result + '"failedAttempts": ' + IntToStr(AUser.FailedAttempts) + ',';
  Result := Result + '"locked": ' + BoolToJson(AUser.Locked) + ',';
  Result := Result + '"createdAt": ' + DateTimeToJson(AUser.CreatedAt) + ',';
  Result := Result + '"lastLoginAt": ' + NullOrDateTimeToJson(AUser.LastLoginAt);
  Result := Result + '}';
end;

function TFileUserRepository.JsonToUser(const AJson: string): TUser;
var
  LId, LUsername, LDisplayName, LEmail: string;
  LPasswordHash, LSalt: string;
  LActive, LDeleted, LLocked: Boolean;
  LRole: TUserRole;
  LFailedAttempts: Integer;
  LCreatedAt, LLastLoginAt: TDateTime;
begin
  LId := ExtractJsonString(AJson, 'id');
  LUsername := ExtractJsonString(AJson, 'username');
  LDisplayName := ExtractJsonString(AJson, 'displayName');
  LEmail := ExtractJsonString(AJson, 'email');
  LPasswordHash := ExtractJsonString(AJson, 'passwordHash');
  LSalt := ExtractJsonString(AJson, 'salt');
  LActive := ExtractJsonBool(AJson, 'active');
  LDeleted := ExtractJsonBool(AJson, 'deleted');
  LRole := JsonToRole(ExtractJsonString(AJson, 'role'));
  LFailedAttempts := ExtractJsonInteger(AJson, 'failedAttempts');
  LLocked := ExtractJsonBool(AJson, 'locked');
  LCreatedAt := ExtractJsonDate(AJson, 'createdAt');
  LLastLoginAt := ExtractJsonDate(AJson, 'lastLoginAt');

  Result := TUser.Create(LId, LUsername, LDisplayName, LPasswordHash, LSalt,
    LActive, LRole, LEmail, LCreatedAt);
  Result.Deleted := LDeleted;
  Result.FailedAttempts := LFailedAttempts;
  Result.Locked := LLocked;
  Result.LastLoginAt := LLastLoginAt;
end;

end.
