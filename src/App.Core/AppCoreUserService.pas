unit AppCoreUserService;

interface

uses
  Classes,
  SysUtils,
  AppCoreAuth,
  AppCoreClock,
  AppCoreUser,
  AppCoreUserRepository;

type
  EUserValidationError = class(Exception);
  EUserNotFoundError = class(Exception);
  EUserSelfModificationError = class(Exception);
  ELastAdminError = class(Exception);
  EUserDeletedError = class(Exception);
  EDeleteConfirmationRequiredError = class(Exception);

  TUserFilter = (ufActive, ufInactive, ufBlocked, ufDeleted);
  TUserFilters = set of TUserFilter;

  TUserService = class
  private
    FUsers: IUserRepository;
    FClock: IClock;
    FHasher: IPasswordHasher;
    FNextId: Integer;

    function ActiveAdminCountExcept(const AExceptUserId: string): Integer;
    procedure AssertAdminActor(const AActorUserId: string);
    procedure AssertNotSelf(const AActorUserId, ATargetUserId: string);
    procedure AssertCanRemoveAdminAccess(AUser: TUser);
    procedure AssertUserIsEditable(AUser: TUser);
    function FindRequired(const AUserId: string): TUser;
    function MatchesFilters(AUser: TUser; AFilters: TUserFilters): Boolean;
    function MatchesSearch(AUser: TUser; const ASearchText: string): Boolean;
    function NewId: string;
    procedure SetPassword(AUser: TUser; const APassword: string);
    procedure ValidateEmail(const AEmail: string);
    procedure ValidatePassword(const APassword: string);
    procedure ValidateUserData(const AUsername, ADisplayName, AEmail: string;
      const AExistingId: string);
  public
    constructor Create(const AUsers: IUserRepository; const AClock: IClock;
      const AHasher: IPasswordHasher);

    function EnsureDefaultAdmin: TUser;
    function CreateUser(const AActorUserId, AUsername, ADisplayName, AEmail,
      APassword: string; ARole: TUserRole): TUser;
    procedure UpdateUser(const AActorUserId, AUserId, AUsername, ADisplayName,
      AEmail: string; AActive: Boolean; ARole: TUserRole; ALocked: Boolean);
    procedure ActivateUser(const AActorUserId, AUserId: string);
    procedure DeactivateUser(const AActorUserId, AUserId: string);
    procedure BlockUser(const AActorUserId, AUserId: string);
    procedure UnlockUser(const AActorUserId, AUserId: string);
    procedure DeleteUser(const AActorUserId, AUserId: string; AConfirmed: Boolean);
    procedure ChangePassword(const AActorUserId, AUserId, APassword: string);
    function ListUsers(const ASearchText: string; AFilters: TUserFilters): TList;
  end;

implementation

function ContainsText(const AText, ASearchText: string): Boolean;
begin
  Result := Pos(UpperCase(ASearchText), UpperCase(AText)) > 0;
end;

constructor TUserService.Create(const AUsers: IUserRepository; const AClock: IClock;
  const AHasher: IPasswordHasher);
begin
  inherited Create;
  FUsers := AUsers;
  FClock := AClock;
  FHasher := AHasher;
  FNextId := 1;
end;

function TUserService.ActiveAdminCountExcept(const AExceptUserId: string): Integer;
var
  I: Integer;
  LUser: TUser;
begin
  Result := 0;
  for I := 0 to FUsers.All.Count - 1 do
  begin
    LUser := TUser(FUsers.All[I]);
    if (LUser.Id <> AExceptUserId) and LUser.Active and (not LUser.Deleted) and
      (not LUser.Locked) and (LUser.Role = urAdmin) then
      Inc(Result);
  end;
end;

procedure TUserService.AssertAdminActor(const AActorUserId: string);
var
  LActor: TUser;
begin
  LActor := FindRequired(AActorUserId);
  if LActor.Deleted or (not LActor.Active) or LActor.Locked or
    (LActor.Role <> urAdmin) then
    raise EAccessDeniedError.Create('No tiene permisos para acceder a esta funcionalidad.');
end;

procedure TUserService.AssertCanRemoveAdminAccess(AUser: TUser);
begin
  if AUser.Active and (not AUser.Deleted) and (not AUser.Locked) and
    (AUser.Role = urAdmin) and (ActiveAdminCountExcept(AUser.Id) = 0) then
    raise ELastAdminError.Create('Debe existir al menos un administrador activo.');
end;

procedure TUserService.AssertNotSelf(const AActorUserId, ATargetUserId: string);
begin
  if AActorUserId = ATargetUserId then
    raise EUserSelfModificationError.Create('No puede modificar su propio usuario desde esta pantalla.');
end;

procedure TUserService.AssertUserIsEditable(AUser: TUser);
begin
  if AUser.Deleted then
    raise EUserDeletedError.Create('El usuario esta eliminado.');
end;

procedure TUserService.ActivateUser(const AActorUserId, AUserId: string);
var
  LUser: TUser;
begin
  AssertAdminActor(AActorUserId);
  AssertNotSelf(AActorUserId, AUserId);
  LUser := FindRequired(AUserId);
  AssertUserIsEditable(LUser);
  LUser.Active := True;
  FUsers.Save(LUser);
end;

procedure TUserService.BlockUser(const AActorUserId, AUserId: string);
var
  LUser: TUser;
begin
  AssertAdminActor(AActorUserId);
  AssertNotSelf(AActorUserId, AUserId);
  LUser := FindRequired(AUserId);
  AssertUserIsEditable(LUser);
  AssertCanRemoveAdminAccess(LUser);
  LUser.Locked := True;
  FUsers.Save(LUser);
end;

procedure TUserService.ChangePassword(const AActorUserId, AUserId,
  APassword: string);
var
  LUser: TUser;
begin
  AssertAdminActor(AActorUserId);
  AssertNotSelf(AActorUserId, AUserId);
  LUser := FindRequired(AUserId);
  AssertUserIsEditable(LUser);
  SetPassword(LUser, APassword);
  FUsers.Save(LUser);
end;

function TUserService.CreateUser(const AActorUserId, AUsername, ADisplayName,
  AEmail, APassword: string; ARole: TUserRole): TUser;
var
  LUsername: string;
  LDisplayName: string;
  LEmail: string;
begin
  AssertAdminActor(AActorUserId);
  LUsername := Trim(AUsername);
  LDisplayName := Trim(ADisplayName);
  LEmail := Trim(AEmail);
  ValidateUserData(LUsername, LDisplayName, LEmail, '');
  ValidatePassword(APassword);

  Result := TUser.Create(NewId, LUsername, LDisplayName, '', '', True, ARole,
    LEmail, FClock.Now);
  Result.Deleted := False;
  SetPassword(Result, APassword);
  FUsers.Save(Result);
end;

procedure TUserService.DeactivateUser(const AActorUserId, AUserId: string);
var
  LUser: TUser;
begin
  AssertAdminActor(AActorUserId);
  AssertNotSelf(AActorUserId, AUserId);
  LUser := FindRequired(AUserId);
  AssertUserIsEditable(LUser);
  AssertCanRemoveAdminAccess(LUser);
  LUser.Active := False;
  FUsers.Save(LUser);
end;

procedure TUserService.DeleteUser(const AActorUserId, AUserId: string;
  AConfirmed: Boolean);
var
  LUser: TUser;
begin
  AssertAdminActor(AActorUserId);
  AssertNotSelf(AActorUserId, AUserId);
  if not AConfirmed then
    raise EDeleteConfirmationRequiredError.Create('Esta seguro de que desea eliminar este usuario?');

  LUser := FindRequired(AUserId);
  AssertUserIsEditable(LUser);
  AssertCanRemoveAdminAccess(LUser);
  LUser.Deleted := True;
  FUsers.Save(LUser);
end;

function TUserService.EnsureDefaultAdmin: TUser;
begin
  Result := FUsers.FindByUsername('admin');
  if Result <> nil then
    Exit;

  Result := TUser.Create(NewId, 'admin', 'Administrador', '', '', True, urAdmin,
    'admin@example.local', FClock.Now);
  SetPassword(Result, 'admin');
  FUsers.Save(Result);
end;

function TUserService.FindRequired(const AUserId: string): TUser;
begin
  Result := FUsers.FindById(AUserId);
  if Result = nil then
    raise EUserNotFoundError.Create('El usuario no existe.');
end;

function TUserService.ListUsers(const ASearchText: string;
  AFilters: TUserFilters): TList;
var
  I: Integer;
  LUser: TUser;
begin
  Result := TList.Create;
  for I := 0 to FUsers.All.Count - 1 do
  begin
    LUser := TUser(FUsers.All[I]);
    if MatchesFilters(LUser, AFilters) and MatchesSearch(LUser, Trim(ASearchText)) then
      Result.Add(LUser);
  end;
end;

function TUserService.MatchesFilters(AUser: TUser;
  AFilters: TUserFilters): Boolean;
begin
  if AUser.Deleted then
  begin
    Result := ufDeleted in AFilters;
    Exit;
  end;

  if ufDeleted in AFilters then
  begin
    Result := False;
    Exit;
  end;

  Result := True;
  if (ufActive in AFilters) and (not AUser.Active) then
    Result := False;
  if (ufInactive in AFilters) and AUser.Active then
    Result := False;
  if (ufBlocked in AFilters) and (not AUser.Locked) then
    Result := False;
end;

function TUserService.MatchesSearch(AUser: TUser;
  const ASearchText: string): Boolean;
begin
  Result := (ASearchText = '') or ContainsText(AUser.Username, ASearchText) or
    ContainsText(AUser.DisplayName, ASearchText) or ContainsText(AUser.Email, ASearchText);
end;

function TUserService.NewId: string;
begin
  Result := 'user-' + IntToStr(FNextId);
  Inc(FNextId);
end;

procedure TUserService.SetPassword(AUser: TUser; const APassword: string);
begin
  ValidatePassword(APassword);
  AUser.Salt := AUser.Username + '-salt';
  AUser.PasswordHash := FHasher.HashPassword(APassword, AUser.Salt);
end;

procedure TUserService.UnlockUser(const AActorUserId, AUserId: string);
var
  LUser: TUser;
begin
  AssertAdminActor(AActorUserId);
  AssertNotSelf(AActorUserId, AUserId);
  LUser := FindRequired(AUserId);
  AssertUserIsEditable(LUser);
  LUser.Locked := False;
  LUser.FailedAttempts := 0;
  FUsers.Save(LUser);
end;

procedure TUserService.UpdateUser(const AActorUserId, AUserId, AUsername,
  ADisplayName, AEmail: string; AActive: Boolean; ARole: TUserRole;
  ALocked: Boolean);
var
  LUser: TUser;
  LUsername: string;
  LDisplayName: string;
  LEmail: string;
begin
  AssertAdminActor(AActorUserId);
  AssertNotSelf(AActorUserId, AUserId);
  LUser := FindRequired(AUserId);
  AssertUserIsEditable(LUser);

  if ((not AActive) or ALocked or (ARole <> urAdmin)) then
    AssertCanRemoveAdminAccess(LUser);

  LUsername := Trim(AUsername);
  LDisplayName := Trim(ADisplayName);
  LEmail := Trim(AEmail);
  ValidateUserData(LUsername, LDisplayName, LEmail, AUserId);

  LUser.Username := LUsername;
  LUser.DisplayName := LDisplayName;
  LUser.Email := LEmail;
  LUser.Active := AActive;
  LUser.Role := ARole;
  LUser.Locked := ALocked;
  FUsers.Save(LUser);
end;

procedure TUserService.ValidateEmail(const AEmail: string);
var
  LAtPos: Integer;
  LDotPos: Integer;
begin
  LAtPos := Pos('@', AEmail);
  LDotPos := LastDelimiter('.', AEmail);
  if (LAtPos <= 1) or (LDotPos <= LAtPos + 1) or (LDotPos = Length(AEmail)) then
    raise EUserValidationError.Create('El email no tiene un formato valido.');
end;

procedure TUserService.ValidatePassword(const APassword: string);
begin
  if Trim(APassword) = '' then
    raise EUserValidationError.Create('La contrasena es obligatoria.');

  if Length(APassword) <= 4 then
    raise EUserValidationError.Create('La contrasena debe tener mas de 4 caracteres.');
end;

procedure TUserService.ValidateUserData(const AUsername, ADisplayName,
  AEmail: string; const AExistingId: string);
var
  LExisting: TUser;
begin
  if AUsername = '' then
    raise EUserValidationError.Create('El usuario es obligatorio.');
  if ADisplayName = '' then
    raise EUserValidationError.Create('El nombre visible es obligatorio.');
  if AEmail = '' then
    raise EUserValidationError.Create('El email es obligatorio.');

  ValidateEmail(AEmail);

  LExisting := FUsers.FindByUsername(AUsername);
  if (LExisting <> nil) and (LExisting.Id <> AExistingId) then
    raise EUserValidationError.Create('Ya existe un usuario con ese nombre.');

  LExisting := FUsers.FindByEmail(AEmail);
  if (LExisting <> nil) and (LExisting.Id <> AExistingId) then
    raise EUserValidationError.Create('Ya existe un usuario con ese email.');
end;

end.
