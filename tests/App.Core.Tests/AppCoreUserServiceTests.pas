unit AppCoreUserServiceTests;

interface

procedure RunUserServiceTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCoreAuth,
  AppCoreClock,
  AppCorePreferences,
  AppCoreUser,
  AppCoreUserRepository,
  AppCoreUserService;

type
  TFixedClock = class(TInterfacedObject, IClock)
  private
    FNow: TDateTime;
  public
    constructor Create(const ANow: TDateTime);
    function Now: TDateTime;
  end;

constructor TFixedClock.Create(const ANow: TDateTime);
begin
  inherited Create;
  FNow := ANow;
end;

function TFixedClock.Now: TDateTime;
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
  const AId, AUsername, APassword, ADisplayName, AEmail: string; AActive: Boolean;
  ARole: TUserRole; AFailedAttempts: Integer; ALocked: Boolean);
var
  LUser: TUser;
  LSalt: string;
begin
  LSalt := AUsername + '-salt';
  LUser := TUser.Create(AId, AUsername, ADisplayName,
    AHasher.HashPassword(APassword, LSalt), LSalt, AActive, ARole,
    AEmail, EncodeDate(2026, 6, 1));
  LUser.FailedAttempts := AFailedAttempts;
  LUser.Locked := ALocked;
  ARepository.Add(LUser);
end;

procedure BuildUserServices(var ARepository: TInMemoryUserRepository;
  var AService: TUserService; var AHasher: IPasswordHasher; var AClock: IClock);
begin
  AHasher := TBasicPasswordHasher.Create;
  ARepository := TInMemoryUserRepository.Create;
  AClock := TFixedClock.Create(EncodeDate(2026, 6, 9));

  AddUser(ARepository, AHasher, 'admin', 'admin', 'admin123', 'Administrador',
    'admin@example.com', True, urAdmin, 0, False);
  AddUser(ARepository, AHasher, 'manager', 'manager', 'manager123', 'Manager',
    'manager@example.com', True, urAdmin, 0, False);
  AddUser(ARepository, AHasher, 'user', 'user', 'user123', 'Usuario normal',
    'user@example.com', True, urNormal, 0, False);
  AddUser(ARepository, AHasher, 'disabled', 'disabled', 'disabled123',
    'Usuario inactivo', 'disabled@example.com', False, urNormal, 0, False);
  AddUser(ARepository, AHasher, 'locked', 'locked', 'locked123',
    'Usuario bloqueado', 'locked@example.com', True, urNormal, 3, True);

  AService := TUserService.Create(ARepository, AClock, AHasher);
end;

procedure UserManagementCreatesDefaultAdminOnNewInstallation;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LUser: TUser;
begin
  LHasher := TBasicPasswordHasher.Create;
  LRepository := TInMemoryUserRepository.Create;
  LClock := TFixedClock.Create(EncodeDate(2026, 6, 9));
  LService := TUserService.Create(LRepository, LClock, LHasher);

  LUser := LService.EnsureDefaultAdmin;

  AssertEquals('admin', LUser.Username, 'Default admin should use admin username.');
  AssertTrue(LHasher.VerifyPassword('admin', LUser.Salt, LUser.PasswordHash),
    'Default admin should use admin password.');
  AssertEquals(Ord(urAdmin), Ord(LUser.Role), 'Default admin should be admin.');
  AssertTrue(LUser.Active, 'Default admin should be active.');
  AssertFalse(LUser.Locked, 'Default admin should not be locked.');
end;

procedure CreateUserStoresActiveUnblockedNotDeletedUser;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LUser: TUser;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);

  LUser := LService.CreateUser('admin', '  newuser  ', '  New User  ',
    '  new@example.com  ', 'secret', urNormal);

  AssertEquals('newuser', LUser.Username, 'Username should be trimmed.');
  AssertEquals('New User', LUser.DisplayName, 'Display name should be trimmed.');
  AssertEquals('new@example.com', LUser.Email, 'Email should be trimmed.');
  AssertTrue(LUser.Active, 'New user should be active.');
  AssertFalse(LUser.Locked, 'New user should not be locked.');
  AssertFalse(LUser.Deleted, 'New user should not be deleted.');
  AssertEquals(0, LUser.FailedAttempts, 'New user should not have failed attempts.');
end;

procedure CreateUserRejectsInvalidEmail;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.CreateUser('admin', 'badmail', 'Bad Mail', 'badmail', 'secret', urNormal);
  except
    on E: EUserValidationError do
      Exit;
  end;
  raise Exception.Create('Expected EUserValidationError.');
end;

procedure CreateUserRejectsShortPassword;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.CreateUser('admin', 'shortpass', 'Short Pass', 'short@example.com', '1234', urNormal);
  except
    on E: EUserValidationError do
      Exit;
  end;
  raise Exception.Create('Expected EUserValidationError.');
end;

procedure CreateUserRejectsDuplicateUsername;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.CreateUser('admin', 'user', 'Duplicate', 'duplicate@example.com', 'secret', urNormal);
  except
    on E: EUserValidationError do
      Exit;
  end;
  raise Exception.Create('Expected EUserValidationError.');
end;

procedure CreateUserRejectsDuplicateEmail;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.CreateUser('admin', 'duplicate', 'Duplicate', 'user@example.com', 'secret', urNormal);
  except
    on E: EUserValidationError do
      Exit;
  end;
  raise Exception.Create('Expected EUserValidationError.');
end;

procedure UpdateUserRejectsSelfModification;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.UpdateUser('admin', 'admin', 'admin', 'Administrador',
      'admin@example.com', True, urAdmin, False);
  except
    on E: EUserSelfModificationError do
      Exit;
  end;
  raise Exception.Create('Expected EUserSelfModificationError.');
end;

procedure ChangePasswordReplacesOldCredentials;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LSession: ISessionService;
  LAuth: IAuthService;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LSession := TSessionService.Create(LClock, 15);
  LAuth := TAuthService.Create(LRepository, LSession,
    TInMemoryLoginPreferencesRepository.Create, LHasher);

  LService.ChangePassword('admin', 'user', 'newpass');

  try
    LAuth.Login('user', 'user123');
  except
    on E: EAuthenticationError do ;
  end;
  LAuth.Login('user', 'newpass');
  AssertTrue(LSession.IsActive, 'New password should authenticate.');
end;

procedure DeleteUserMarksUserAsDeleted;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'user', True);
  AssertTrue(LRepository.FindById('user').Deleted, 'Deleted user should be marked as deleted.');
end;

procedure DeleteUserRequiresConfirmation;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.DeleteUser('admin', 'user', False);
  except
    on E: EDeleteConfirmationRequiredError do
      Exit;
  end;
  raise Exception.Create('Expected EDeleteConfirmationRequiredError.');
end;

procedure DeleteUserPreventsFutureLogin;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LSession: ISessionService;
  LAuth: IAuthService;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LSession := TSessionService.Create(LClock, 15);
  LAuth := TAuthService.Create(LRepository, LSession,
    TInMemoryLoginPreferencesRepository.Create, LHasher);

  LService.DeleteUser('admin', 'user', True);
  try
    LAuth.Login('user', 'user123');
  except
    on E: EDeletedUserError do
      Exit;
  end;
  raise Exception.Create('Expected EDeletedUserError.');
end;

procedure DeleteUserRejectsReactivation;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'user', True);
  try
    LService.ActivateUser('admin', 'user');
  except
    on E: EUserDeletedError do
      Exit;
  end;
  raise Exception.Create('Expected EUserDeletedError.');
end;

procedure DeleteUserDoesNotCloseCurrentSession;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LSession: ISessionService;
  LAuth: IAuthService;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LSession := TSessionService.Create(LClock, 15);
  LAuth := TAuthService.Create(LRepository, LSession,
    TInMemoryLoginPreferencesRepository.Create, LHasher);

  LAuth.Login('user', 'user123');
  LService.DeleteUser('admin', 'user', True);

  AssertTrue(LSession.IsActive, 'Deleting user should not close current session.');
end;

procedure ChangeRoleUpdatesPermissionsOnNextLogin;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LSession: ISessionService;
  LAuth: IAuthService;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LSession := TSessionService.Create(LClock, 15);
  LAuth := TAuthService.Create(LRepository, LSession,
    TInMemoryLoginPreferencesRepository.Create, LHasher);

  LAuth.Login('user', 'user123');
  LService.UpdateUser('admin', 'user', 'user', 'Usuario normal',
    'user@example.com', True, urAdmin, False);
  AssertEquals(Ord(urNormal), Ord(LSession.CurrentRole),
    'Current session should keep original role.');

  LAuth.Logout;
  LAuth.Login('user', 'user123');
  AssertEquals(Ord(urAdmin), Ord(LSession.CurrentRole),
    'Next login should use changed role.');
end;

procedure UserManagementPreventsRemovingLastActiveAdmin;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'manager', True);
  try
    LService.DeactivateUser('manager', 'admin');
  except
    on E: ELastAdminError do
      Exit;
  end;
  raise Exception.Create('Expected ELastAdminError.');
end;

procedure SearchUsersMatchesUsernameDisplayNameAndEmail;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LList: TList;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LList := LService.ListUsers('manager@example', []);
  try
    AssertEquals(1, LList.Count, 'Search should match email.');
    AssertEquals('manager', TUser(LList[0]).Username, 'Search should return manager.');
  finally
    LList.Free;
  end;
end;

procedure ListUsersExcludesDeletedUsersByDefault;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LList: TList;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'user', True);
  LList := LService.ListUsers('', []);
  try
    AssertEquals(4, LList.Count, 'Default list should hide deleted users.');
  finally
    LList.Free;
  end;
end;

procedure FilterUsersReturnsDeletedUsersWhenRequested;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LList: TList;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'user', True);
  LList := LService.ListUsers('', [ufDeleted]);
  try
    AssertEquals(1, LList.Count, 'Deleted filter should show deleted users.');
    AssertEquals('user', TUser(LList[0]).Username, 'Deleted filter should return deleted user.');
  finally
    LList.Free;
  end;
end;

procedure LoginUpdatesUserLastLoginAt;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LSession: ISessionService;
  LAuth: IAuthService;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LSession := TSessionService.Create(LClock, 15);
  LAuth := TAuthService.Create(LRepository, LSession,
    TInMemoryLoginPreferencesRepository.Create, LHasher);

  LAuth.Login('user', 'user123');

  AssertTrue(LRepository.FindById('user').LastLoginAt > 0,
    'Login should update last login date.');
end;

procedure RunUserServiceTests(var AFailures: Integer);
begin
  RunTest('UserManagement_creates_default_admin_on_new_installation', UserManagementCreatesDefaultAdminOnNewInstallation, AFailures);
  RunTest('CreateUser_stores_active_unblocked_not_deleted_user', CreateUserStoresActiveUnblockedNotDeletedUser, AFailures);
  RunTest('CreateUser_rejects_invalid_email', CreateUserRejectsInvalidEmail, AFailures);
  RunTest('CreateUser_rejects_short_password', CreateUserRejectsShortPassword, AFailures);
  RunTest('CreateUser_rejects_duplicate_username', CreateUserRejectsDuplicateUsername, AFailures);
  RunTest('CreateUser_rejects_duplicate_email', CreateUserRejectsDuplicateEmail, AFailures);
  RunTest('UpdateUser_rejects_self_modification', UpdateUserRejectsSelfModification, AFailures);
  RunTest('ChangePassword_replaces_old_credentials', ChangePasswordReplacesOldCredentials, AFailures);
  RunTest('DeleteUser_marks_user_as_deleted', DeleteUserMarksUserAsDeleted, AFailures);
  RunTest('DeleteUser_requires_confirmation', DeleteUserRequiresConfirmation, AFailures);
  RunTest('DeleteUser_prevents_future_login', DeleteUserPreventsFutureLogin, AFailures);
  RunTest('DeleteUser_rejects_reactivation', DeleteUserRejectsReactivation, AFailures);
  RunTest('DeleteUser_does_not_close_current_session', DeleteUserDoesNotCloseCurrentSession, AFailures);
  RunTest('ChangeRole_updates_permissions_on_next_login', ChangeRoleUpdatesPermissionsOnNextLogin, AFailures);
  RunTest('SearchUsers_matches_username_display_name_and_email', SearchUsersMatchesUsernameDisplayNameAndEmail, AFailures);
  RunTest('ListUsers_excludes_deleted_users_by_default', ListUsersExcludesDeletedUsersByDefault, AFailures);
  RunTest('FilterUsers_returns_deleted_users_when_requested', FilterUsersReturnsDeletedUsersWhenRequested, AFailures);
  RunTest('Login_updates_user_last_login_at', LoginUpdatesUserLastLoginAt, AFailures);
end;

end.
