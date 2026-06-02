unit AppCoreAuthServiceTests;

interface

procedure RunAuthServiceTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCoreAuth,
  AppCoreClock,
  AppCorePreferences,
  AppCoreUser,
  AppCoreUserRepository;

type
  TMutableClock = class(TInterfacedObject, IClock)
  private
    FNow: TDateTime;
  public
    constructor Create(const ANow: TDateTime);
    procedure AdvanceMinutes(AMinutes: Integer);
    function Now: TDateTime;
  end;

constructor TMutableClock.Create(const ANow: TDateTime);
begin
  inherited Create;
  FNow := ANow;
end;

procedure TMutableClock.AdvanceMinutes(AMinutes: Integer);
begin
  FNow := FNow + (AMinutes / (24 * 60));
end;

function TMutableClock.Now: TDateTime;
begin
  Result := FNow;
end;

procedure AssertEquals(const AExpected, AActual: string; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure AssertEquals(AExpected, AActual: Integer; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected ' + IntToStr(AExpected) + ', got ' + IntToStr(AActual) + '.');
end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
end;

procedure AssertFalse(AValue: Boolean; const AMessage: string);
begin
  if AValue then
    raise Exception.Create(AMessage);
end;

procedure RunTest(const AName: string; AProc: TProcedure; var AFailures: Integer);
begin
  try
    AProc;
    Writeln('[OK] ', AName);
  except
    on E: Exception do
    begin
      Inc(AFailures);
      Writeln('[FAIL] ', AName, ': ', E.Message);
    end;
  end;
end;

procedure AddUser(const ARepository: TInMemoryUserRepository; const AHasher: IPasswordHasher;
  const AUsername, APassword, ADisplayName: string; AActive: Boolean; ARole: TUserRole;
  AFailedAttempts: Integer; ALocked: Boolean);
var
  LUser: TUser;
  LSalt: string;
begin
  LSalt := AUsername + '-salt';
  LUser := TUser.Create(AUsername, AUsername, ADisplayName,
    AHasher.HashPassword(APassword, LSalt), LSalt, AActive, ARole);
  LUser.FailedAttempts := AFailedAttempts;
  LUser.Locked := ALocked;
  ARepository.Add(LUser);
end;

procedure BuildServices(var ARepository: TInMemoryUserRepository; var AClock: TMutableClock;
  var ASessions: ISessionService; var APreferences: ILoginPreferencesRepository;
  var AAuth: IAuthService; var APermissions: IPermissionService; var AHasher: IPasswordHasher);
begin
  AHasher := TBasicPasswordHasher.Create;
  ARepository := TInMemoryUserRepository.Create;
  AClock := TMutableClock.Create(EncodeDate(2026, 6, 2));
  ASessions := TSessionService.Create(AClock, 15);
  APreferences := TInMemoryLoginPreferencesRepository.Create;
  AAuth := TAuthService.Create(ARepository, ASessions, APreferences, AHasher);
  APermissions := TPermissionService.Create(ASessions);

  AddUser(ARepository, AHasher, 'admin', 'admin123', 'Administrador', True, urAdmin, 0, False);
  AddUser(ARepository, AHasher, 'user', 'user123', 'Usuario normal', True, urNormal, 0, False);
  AddUser(ARepository, AHasher, 'disabled', 'disabled123', 'Usuario inactivo', False, urNormal, 0, False);
  AddUser(ARepository, AHasher, 'locked', 'locked123', 'Usuario bloqueado', True, urNormal, 3, True);
end;

procedure ExpectLoginValidationError(const AUsername, APassword: string);
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login(AUsername, APassword);
  except
    on E: ELoginValidationError do
      Exit;
  end;

  raise Exception.Create('Expected ELoginValidationError.');
end;

procedure ExpectAuthenticationError(const AUsername, APassword: string);
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login(AUsername, APassword);
  except
    on E: EAuthenticationError do
      Exit;
  end;

  raise Exception.Create('Expected EAuthenticationError.');
end;

procedure LoginRejectsEmptyUsername;
begin
  ExpectLoginValidationError('   ', 'admin123');
end;

procedure LoginRejectsEmptyPassword;
begin
  ExpectLoginValidationError('admin', '   ');
end;

procedure LoginRejectsUnknownUser;
begin
  ExpectAuthenticationError('missing', 'admin123');
end;

procedure LoginRejectsWrongPassword;
begin
  ExpectAuthenticationError('admin', 'wrong');
end;

procedure LoginRejectsInactiveUser;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login('disabled', 'disabled123');
  except
    on E: EInactiveUserError do
      Exit;
  end;

  raise Exception.Create('Expected EInactiveUserError.');
end;

procedure LoginIncrementsFailedAttemptsForWrongPassword;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
  LUser: TUser;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login('user', 'wrong');
  except
    on E: EAuthenticationError do ;
  end;

  LUser := LRepository.FindByUsername('user');
  AssertEquals(1, LUser.FailedAttempts, 'Wrong password should increment failed attempts.');
end;

procedure LoginLocksUserAfterThreeConsecutiveFailures;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
  LUser: TUser;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LUser := LRepository.FindByUsername('user');
  LUser.FailedAttempts := 2;
  try
    LAuth.Login('user', 'wrong');
  except
    on E: EAuthenticationError do ;
  end;

  AssertTrue(LUser.Locked, 'Third consecutive failure should lock user.');
end;

procedure LoginRejectsLockedUserEvenWithValidPassword;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login('locked', 'locked123');
  except
    on E: EUserLockedError do
      Exit;
  end;

  raise Exception.Create('Expected EUserLockedError.');
end;

procedure LoginResetsFailedAttemptsAfterSuccessfulLogin;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
  LUser: TUser;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LUser := LRepository.FindByUsername('user');
  LUser.FailedAttempts := 2;

  LAuth.Login('user', 'user123');

  AssertEquals(0, LUser.FailedAttempts, 'Successful login should reset failed attempts.');
end;

procedure LoginDoesNotCountEmptyFieldsAsFailedAttempts;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
  LUser: TUser;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login('user', ' ');
  except
    on E: ELoginValidationError do ;
  end;

  LUser := LRepository.FindByUsername('user');
  AssertEquals(0, LUser.FailedAttempts, 'Validation errors should not count as failed attempts.');
end;

procedure LoginDoesNotCountUnknownUserAsFailedAttempt;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login('missing', 'wrong');
  except
    on E: EAuthenticationError do ;
  end;

  AssertTrue(LRepository.FindByUsername('missing') = nil, 'Unknown login should not create a user.');
end;

procedure LoginCreatesActiveSessionForValidCredentials;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('admin', 'admin123');
  AssertTrue(LSessions.IsActive, 'Valid credentials should create an active session.');
end;

procedure LoginStoresUserRoleInSession;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('admin', 'admin123');
  AssertEquals(Ord(urAdmin), Ord(LSessions.CurrentRole), 'Session should store user role.');
end;

procedure LogoutClearsActiveSession;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('admin', 'admin123');
  LAuth.Logout;
  AssertFalse(LSessions.IsActive, 'Logout should clear active session.');
end;

procedure SessionReportsAuthenticatedUser;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('admin', 'admin123');
  AssertEquals('admin', LSessions.CurrentUser.Username, 'Session should expose authenticated user.');
end;

procedure SessionExpiresAfterInactivityLimit;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('admin', 'admin123');
  LClock.AdvanceMinutes(16);
  AssertFalse(LSessions.IsActive, 'Session should expire after inactivity limit.');
end;

procedure SessionUpdatesLastActivityWhenUserPerformsProtectedAction;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
  LPrevious: TDateTime;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('admin', 'admin123');
  LPrevious := LSessions.LastActivityAt;
  LClock.AdvanceMinutes(5);
  LPermissions.RequireAccess(prAuthenticated);
  AssertTrue(LSessions.LastActivityAt > LPrevious, 'Protected activity should update last activity.');
end;

procedure PermissionAllowsAdminFeatureForAdmin;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('admin', 'admin123');
  AssertTrue(LPermissions.CanAccess(prAdmin), 'Admin should access admin features.');
end;

procedure PermissionRejectsAdminFeatureForNormalUser;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('user', 'user123');
  AssertFalse(LPermissions.CanAccess(prAdmin), 'Normal user should not access admin features.');
end;

procedure LoginPrefillsLastUsedUsername;
var
  LPreferences: ILoginPreferencesRepository;
begin
  LPreferences := TInMemoryLoginPreferencesRepository.Create;
  LPreferences.SetLastUsername('admin');
  AssertEquals('admin', LPreferences.LastUsername, 'Login should be able to prefill last used username.');
end;

procedure LoginUpdatesLastUsedUsernameAfterAttempt;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  try
    LAuth.Login('user', 'wrong');
  except
    on E: EAuthenticationError do ;
  end;

  AssertEquals('user', LPreferences.LastUsername, 'Login attempt should update last used username.');
end;

procedure LoginDoesNotClearLastUsedUsernameWhenUsernameIsEmpty;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LPreferences.SetLastUsername('admin');
  try
    LAuth.Login(' ', 'admin123');
  except
    on E: ELoginValidationError do ;
  end;

  AssertEquals('admin', LPreferences.LastUsername, 'Empty username should not clear last used username.');
end;

procedure UsernameIsTrimmedBeforeAuthentication;
var
  LRepository: TInMemoryUserRepository;
  LClock: TMutableClock;
  LSessions: ISessionService;
  LPreferences: ILoginPreferencesRepository;
  LAuth: IAuthService;
  LPermissions: IPermissionService;
  LHasher: IPasswordHasher;
begin
  BuildServices(LRepository, LClock, LSessions, LPreferences, LAuth, LPermissions, LHasher);
  LAuth.Login('  admin  ', 'admin123');
  AssertTrue(LSessions.IsActive, 'Username should be trimmed before authentication.');
end;

procedure RunAuthServiceTests(var AFailures: Integer);
begin
  RunTest('Login_rejects_empty_username', LoginRejectsEmptyUsername, AFailures);
  RunTest('Login_rejects_empty_password', LoginRejectsEmptyPassword, AFailures);
  RunTest('Login_rejects_unknown_user', LoginRejectsUnknownUser, AFailures);
  RunTest('Login_rejects_wrong_password', LoginRejectsWrongPassword, AFailures);
  RunTest('Login_rejects_inactive_user', LoginRejectsInactiveUser, AFailures);
  RunTest('Login_increments_failed_attempts_for_wrong_password', LoginIncrementsFailedAttemptsForWrongPassword, AFailures);
  RunTest('Login_locks_user_after_three_consecutive_failures', LoginLocksUserAfterThreeConsecutiveFailures, AFailures);
  RunTest('Login_rejects_locked_user_even_with_valid_password', LoginRejectsLockedUserEvenWithValidPassword, AFailures);
  RunTest('Login_resets_failed_attempts_after_successful_login', LoginResetsFailedAttemptsAfterSuccessfulLogin, AFailures);
  RunTest('Login_does_not_count_empty_fields_as_failed_attempts', LoginDoesNotCountEmptyFieldsAsFailedAttempts, AFailures);
  RunTest('Login_does_not_count_unknown_user_as_failed_attempt', LoginDoesNotCountUnknownUserAsFailedAttempt, AFailures);
  RunTest('Login_creates_active_session_for_valid_credentials', LoginCreatesActiveSessionForValidCredentials, AFailures);
  RunTest('Login_stores_user_role_in_session', LoginStoresUserRoleInSession, AFailures);
  RunTest('Logout_clears_active_session', LogoutClearsActiveSession, AFailures);
  RunTest('Session_reports_authenticated_user', SessionReportsAuthenticatedUser, AFailures);
  RunTest('Session_expires_after_inactivity_limit', SessionExpiresAfterInactivityLimit, AFailures);
  RunTest('Session_updates_last_activity_when_user_performs_protected_action', SessionUpdatesLastActivityWhenUserPerformsProtectedAction, AFailures);
  RunTest('Permission_allows_admin_feature_for_admin', PermissionAllowsAdminFeatureForAdmin, AFailures);
  RunTest('Permission_rejects_admin_feature_for_normal_user', PermissionRejectsAdminFeatureForNormalUser, AFailures);
  RunTest('Login_prefills_last_used_username', LoginPrefillsLastUsedUsername, AFailures);
  RunTest('Login_updates_last_used_username_after_attempt', LoginUpdatesLastUsedUsernameAfterAttempt, AFailures);
  RunTest('Login_does_not_clear_last_used_username_when_username_is_empty', LoginDoesNotClearLastUsedUsernameWhenUsernameIsEmpty, AFailures);
  RunTest('Username_is_trimmed_before_authentication', UsernameIsTrimmedBeforeAuthentication, AFailures);
end;

end.
