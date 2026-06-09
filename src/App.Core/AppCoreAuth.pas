unit AppCoreAuth;

interface

uses
  SysUtils,
  AppCoreClock,
  AppCorePreferences,
  AppCoreUser,
  AppCoreUserRepository;

type
  ELoginValidationError = class(Exception);
  EAuthenticationError = class(Exception);
  EInactiveUserError = class(Exception);
  EUserLockedError = class(Exception);
  EDeletedUserError = class(Exception);
  ESessionRequiredError = class(Exception);
  ESessionExpiredError = class(Exception);
  EAccessDeniedError = class(Exception);

  TPermissionRequirement = (prAuthenticated, prAdmin);

  IPasswordHasher = interface
    ['{56AB0E2D-83D5-4F8E-875F-2D735A4E4D0A}']
    function HashPassword(const APassword, ASalt: string): string;
    function VerifyPassword(const APassword, ASalt, AHash: string): Boolean;
  end;

  TBasicPasswordHasher = class(TInterfacedObject, IPasswordHasher)
  public
    function HashPassword(const APassword, ASalt: string): string;
    function VerifyPassword(const APassword, ASalt, AHash: string): Boolean;
  end;

  ISessionService = interface
    ['{527E2DF8-0798-47D1-8E8E-C7B713C8F04B}']
    procedure StartSession(AUser: TUser);
    procedure Logout;
    function IsActive: Boolean;
    function CurrentUser: TUser;
    function CurrentRole: TUserRole;
    function LastActivityAt: TDateTime;
    procedure RegisterActivity;
    procedure RequireActiveSession;
  end;

  TSessionService = class(TInterfacedObject, ISessionService)
  private
    FClock: IClock;
    FTimeoutMinutes: Integer;
    FCurrentUser: TUser;
    FCurrentRole: TUserRole;
    FStartedAt: TDateTime;
    FLastActivityAt: TDateTime;
    FActive: Boolean;
    function IsExpired: Boolean;
    procedure ExpireIfNeeded;
  public
    constructor Create(const AClock: IClock; ATimeoutMinutes: Integer);

    procedure StartSession(AUser: TUser);
    procedure Logout;
    function IsActive: Boolean;
    function CurrentUser: TUser;
    function CurrentRole: TUserRole;
    function LastActivityAt: TDateTime;
    procedure RegisterActivity;
    procedure RequireActiveSession;
  end;

  IAuthService = interface
    ['{7FD0CC27-C1E5-4BE0-B680-179497B5F7C1}']
    function Login(const AUsername, APassword: string): TUser;
    procedure Logout;
  end;

  TAuthService = class(TInterfacedObject, IAuthService)
  private
    FUsers: IUserRepository;
    FSessions: ISessionService;
    FPreferences: ILoginPreferencesRepository;
    FHasher: IPasswordHasher;
    FMaxFailedAttempts: Integer;

    procedure RememberUsername(const AUsername: string);
    procedure ValidateCredentialsInput(const AUsername, APassword: string);
    procedure RegisterWrongPassword(AUser: TUser);
  public
    constructor Create(const AUsers: IUserRepository; const ASessions: ISessionService;
      const APreferences: ILoginPreferencesRepository; const AHasher: IPasswordHasher);

    function Login(const AUsername, APassword: string): TUser;
    procedure Logout;
  end;

  IPermissionService = interface
    ['{922780C7-2BF3-478B-B70D-1524970D7AB0}']
    function CanAccess(ARequirement: TPermissionRequirement): Boolean;
    procedure RequireAccess(ARequirement: TPermissionRequirement);
  end;

  TPermissionService = class(TInterfacedObject, IPermissionService)
  private
    FSessions: ISessionService;
  public
    constructor Create(const ASessions: ISessionService);
    function CanAccess(ARequirement: TPermissionRequirement): Boolean;
    procedure RequireAccess(ARequirement: TPermissionRequirement);
  end;

implementation

function TBasicPasswordHasher.HashPassword(const APassword, ASalt: string): string;
var
  I: Integer;
  LValue: Longint;
  LInput: string;
begin
  LInput := ASalt + ':' + APassword;
  LValue := 5381;
  for I := 1 to Length(LInput) do
    LValue := ((LValue shl 5) + LValue) xor Ord(LInput[I]);

  Result := IntToHex(LValue, 8);
end;

function TBasicPasswordHasher.VerifyPassword(const APassword, ASalt,
  AHash: string): Boolean;
begin
  Result := HashPassword(APassword, ASalt) = AHash;
end;

constructor TSessionService.Create(const AClock: IClock; ATimeoutMinutes: Integer);
begin
  inherited Create;
  FClock := AClock;
  FTimeoutMinutes := ATimeoutMinutes;
  FCurrentUser := nil;
  FCurrentRole := urNormal;
  FStartedAt := 0;
  FLastActivityAt := 0;
  FActive := False;
end;

function TSessionService.CurrentRole: TUserRole;
begin
  RequireActiveSession;
  Result := FCurrentRole;
end;

function TSessionService.CurrentUser: TUser;
begin
  RequireActiveSession;
  Result := FCurrentUser;
end;

procedure TSessionService.ExpireIfNeeded;
begin
  if FActive and IsExpired then
  begin
    FActive := False;
    FCurrentUser := nil;
    FCurrentRole := urNormal;
    raise ESessionExpiredError.Create('La sesion ha expirado por inactividad.');
  end;
end;

function TSessionService.IsActive: Boolean;
begin
  if FActive and IsExpired then
  begin
    FActive := False;
    FCurrentUser := nil;
    FCurrentRole := urNormal;
  end;

  Result := FActive;
end;

function TSessionService.IsExpired: Boolean;
begin
  Result := FActive and (FTimeoutMinutes > 0) and
    ((FClock.Now - FLastActivityAt) * 24 * 60 > FTimeoutMinutes);
end;

function TSessionService.LastActivityAt: TDateTime;
begin
  Result := FLastActivityAt;
end;

procedure TSessionService.Logout;
begin
  FCurrentUser := nil;
  FCurrentRole := urNormal;
  FStartedAt := 0;
  FLastActivityAt := 0;
  FActive := False;
end;

procedure TSessionService.RegisterActivity;
begin
  ExpireIfNeeded;
  if not FActive then
    raise ESessionRequiredError.Create('Debe iniciar sesion para acceder a la aplicacion.');

  FLastActivityAt := FClock.Now;
end;

procedure TSessionService.RequireActiveSession;
begin
  ExpireIfNeeded;
  if not FActive then
    raise ESessionRequiredError.Create('Debe iniciar sesion para acceder a la aplicacion.');
end;

procedure TSessionService.StartSession(AUser: TUser);
begin
  FCurrentUser := AUser;
  FCurrentRole := AUser.Role;
  FStartedAt := FClock.Now;
  FLastActivityAt := FStartedAt;
  FActive := True;
end;

constructor TAuthService.Create(const AUsers: IUserRepository;
  const ASessions: ISessionService; const APreferences: ILoginPreferencesRepository;
  const AHasher: IPasswordHasher);
begin
  inherited Create;
  FUsers := AUsers;
  FSessions := ASessions;
  FPreferences := APreferences;
  FHasher := AHasher;
  FMaxFailedAttempts := 3;
end;

function TAuthService.Login(const AUsername, APassword: string): TUser;
var
  LUsername: string;
  LUser: TUser;
begin
  LUsername := Trim(AUsername);
  RememberUsername(LUsername);
  ValidateCredentialsInput(LUsername, APassword);

  LUser := FUsers.FindByUsername(LUsername);
  if LUser = nil then
    raise EAuthenticationError.Create('Usuario o contrasena incorrectos.');

  if LUser.Deleted then
    raise EDeletedUserError.Create('El usuario esta eliminado.');

  if not LUser.Active then
    raise EInactiveUserError.Create('El usuario no esta activo.');

  if LUser.Locked then
    raise EUserLockedError.Create('El usuario esta bloqueado por demasiados intentos fallidos.');

  if not FHasher.VerifyPassword(APassword, LUser.Salt, LUser.PasswordHash) then
  begin
    RegisterWrongPassword(LUser);
    raise EAuthenticationError.Create('Usuario o contrasena incorrectos.');
  end;

  LUser.FailedAttempts := 0;
  FSessions.StartSession(LUser);
  LUser.LastLoginAt := FSessions.LastActivityAt;
  FUsers.Save(LUser);
  Result := LUser;
end;

procedure TAuthService.Logout;
begin
  FSessions.Logout;
end;

procedure TAuthService.RegisterWrongPassword(AUser: TUser);
begin
  AUser.FailedAttempts := AUser.FailedAttempts + 1;
  if AUser.FailedAttempts >= FMaxFailedAttempts then
    AUser.Locked := True;
  FUsers.Save(AUser);
end;

procedure TAuthService.RememberUsername(const AUsername: string);
begin
  if AUsername <> '' then
    FPreferences.SetLastUsername(AUsername);
end;

procedure TAuthService.ValidateCredentialsInput(const AUsername, APassword: string);
begin
  if Trim(AUsername) = '' then
    raise ELoginValidationError.Create('El usuario es obligatorio.');

  if Trim(APassword) = '' then
    raise ELoginValidationError.Create('La contrasena es obligatoria.');
end;

constructor TPermissionService.Create(const ASessions: ISessionService);
begin
  inherited Create;
  FSessions := ASessions;
end;

function TPermissionService.CanAccess(ARequirement: TPermissionRequirement): Boolean;
begin
  Result := False;
  if not FSessions.IsActive then
    Exit;

  if ARequirement = prAuthenticated then
    Result := True
  else
    Result := FSessions.CurrentRole = urAdmin;
end;

procedure TPermissionService.RequireAccess(ARequirement: TPermissionRequirement);
begin
  FSessions.RequireActiveSession;
  if not CanAccess(ARequirement) then
    raise EAccessDeniedError.Create('No tiene permisos para acceder a esta funcionalidad.');

  FSessions.RegisterActivity;
end;

end.
