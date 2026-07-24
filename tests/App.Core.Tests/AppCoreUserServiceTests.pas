unit AppCoreUserServiceTests;

interface

procedure RunUserServiceTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCoreAuth,
  AppCoreClock,
  AppCoreIniText,
  AppCoreJsonUtils,
  AppCorePreferences,
  AppCoreUser,
  AppCoreUserFileRepository,
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

procedure CreateUserRejectsNonAdminActor;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.CreateUser('user', 'newuser', 'New User',
      'newuser@example.com', 'secret', urNormal);
  except
    on E: EAccessDeniedError do
      Exit;
  end;
  raise Exception.Create('Expected EAccessDeniedError.');
end;

procedure CreateUserRejectsMissingRequiredFields;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.CreateUser('admin', '   ', 'New User',
      'required-user@example.com', 'secret', urNormal);
  except
    on E: EUserValidationError do ;
  else
    raise Exception.Create('Expected username validation error.');
  end;

  try
    LService.CreateUser('admin', 'requireduser', '   ',
      'required-user@example.com', 'secret', urNormal);
  except
    on E: EUserValidationError do ;
  else
    raise Exception.Create('Expected display name validation error.');
  end;

  try
    LService.CreateUser('admin', 'requireduser', 'Required User',
      '   ', 'secret', urNormal);
  except
    on E: EUserValidationError do
      Exit;
  end;
  raise Exception.Create('Expected email validation error.');
end;

procedure CreateUserRejectsBlankPassword;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.CreateUser('admin', 'blankpass', 'Blank Pass',
      'blankpass@example.com', '   ', urNormal);
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

procedure UpdateUserRejectsUnknownUser;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  try
    LService.UpdateUser('admin', 'missing', 'missing', 'Missing',
      'missing@example.com', True, urNormal, False);
  except
    on E: EUserNotFoundError do
      Exit;
  end;
  raise Exception.Create('Expected EUserNotFoundError.');
end;

procedure UpdateUserAllowsKeepingSameUsernameAndEmail;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LUser: TUser;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.UpdateUser('admin', 'user', '  user  ', '  Usuario editado  ',
    '  user@example.com  ', True, urNormal, False);

  LUser := LRepository.FindById('user');
  AssertEquals('user', LUser.Username, 'Username should keep same value.');
  AssertEquals('Usuario editado', LUser.DisplayName, 'Display name should be updated and trimmed.');
  AssertEquals('user@example.com', LUser.Email, 'Email should keep same value.');
end;

procedure ActivateUserMakesInactiveUserActive;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.ActivateUser('admin', 'disabled');
  AssertTrue(LRepository.FindById('disabled').Active, 'Inactive user should become active.');
end;

procedure DeactivateUserMakesUserInactive;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeactivateUser('admin', 'user');
  AssertFalse(LRepository.FindById('user').Active, 'Active user should become inactive.');
end;

procedure BlockUserLocksUser;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.BlockUser('admin', 'user');
  AssertTrue(LRepository.FindById('user').Locked, 'User should be locked.');
end;

procedure UnlockUserClearsLockAndFailedAttempts;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.UnlockUser('admin', 'locked');
  AssertFalse(LRepository.FindById('locked').Locked, 'User should be unlocked.');
  AssertEquals(0, LRepository.FindById('locked').FailedAttempts,
    'Unlock should clear failed attempts.');
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
    LService.DeactivateUser('admin', 'admin');
  except
    on E: ELastAdminError do
      Exit;
  end;
  raise Exception.Create('Expected ELastAdminError.');
end;

procedure UserManagementPreventsBlockingLastActiveAdmin;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'manager', True);
  try
    LService.BlockUser('admin', 'admin');
  except
    on E: ELastAdminError do
      Exit;
  end;
  raise Exception.Create('Expected ELastAdminError.');
end;

procedure UserManagementPreventsDeletingLastActiveAdmin;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'manager', True);
  try
    LService.DeleteUser('admin', 'admin', True);
  except
    on E: ELastAdminError do
      Exit;
  end;
  raise Exception.Create('Expected ELastAdminError.');
end;

procedure UserManagementPreventsDowngradingLastActiveAdmin;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LService.DeleteUser('admin', 'manager', True);
  try
    LService.UpdateUser('admin', 'admin', 'admin', 'Administrador',
      'admin@example.com', True, urNormal, False);
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

procedure FilterUsersReturnsOnlyActiveUsers;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LList: TList;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LList := LService.ListUsers('', [ufActive]);
  try
    AssertEquals(4, LList.Count, 'Active filter should hide inactive users.');
  finally
    LList.Free;
  end;
end;

procedure FilterUsersReturnsOnlyInactiveUsers;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LList: TList;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LList := LService.ListUsers('', [ufInactive]);
  try
    AssertEquals(1, LList.Count, 'Inactive filter should return only inactive users.');
    AssertEquals('disabled', TUser(LList[0]).Username, 'Inactive filter should return disabled user.');
  finally
    LList.Free;
  end;
end;

procedure FilterUsersReturnsOnlyBlockedUsers;
var
  LRepository: TInMemoryUserRepository;
  LService: TUserService;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LList: TList;
begin
  BuildUserServices(LRepository, LService, LHasher, LClock);
  LList := LService.ListUsers('', [ufBlocked]);
  try
    AssertEquals(1, LList.Count, 'Blocked filter should return only blocked users.');
    AssertEquals('locked', TUser(LList[0]).Username, 'Blocked filter should return locked user.');
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

procedure FilePersistenceSavesAndLoadsUsers;
const
  LTestFileName = 'test_users_file.json';
var
  LRepository: TFileUserRepository;
  LHasher: IPasswordHasher;
  LUser: TUser;
  LSalt: string;
begin
  DeleteFile(LTestFileName);
  try
    LHasher := TBasicPasswordHasher.Create;
    LSalt := 'admin-salt';
    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      LUser := TUser.Create('admin', 'admin', 'Administrador',
        LHasher.HashPassword('admin', LSalt), LSalt, True, urAdmin, 'admin@example.com', Now);
      LRepository.Save(LUser);

      AssertTrue(FileExists(LTestFileName), 'File should exist after saving.');
    finally
      LRepository.Free;
    end;

    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      AssertEquals(1, LRepository.All.Count, 'Should load 1 user from file.');
      AssertEquals('admin', LRepository.FindById('admin').Username,
        'Username should match after reload.');
    finally
      LRepository.Free;
    end;
  finally
    DeleteFile(LTestFileName);
  end;
end;

procedure FilePersistencePersistsMultipleFields;
const
  LTestFileName = 'test_users_fields.json';
var
  LRepository: TFileUserRepository;
  LHasher: IPasswordHasher;
  LUser: TUser;
  LSalt: string;
  LNow: TDateTime;
begin
  DeleteFile(LTestFileName);
  try
    LHasher := TBasicPasswordHasher.Create;
    LSalt := 'user-salt';
    LNow := EncodeDate(2026, 6, 9) + EncodeTime(10, 30, 0, 0);
    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      LUser := TUser.Create('user1', 'user1', 'User One',
        LHasher.HashPassword('pass', LSalt), LSalt, True, urNormal,
        'user1@example.com', LNow);
      LUser.Deleted := False;
      LUser.FailedAttempts := 2;
      LUser.Locked := False;
      LUser.LastLoginAt := LNow + 1;
      LRepository.Save(LUser);
    finally
      LRepository.Free;
    end;

    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      LUser := LRepository.FindById('user1');
      AssertEquals('user1', LUser.Username, 'Username should persist.');
      AssertEquals('User One', LUser.DisplayName, 'DisplayName should persist.');
      AssertEquals('user1@example.com', LUser.Email, 'Email should persist.');
      AssertTrue(LUser.Active, 'Active should persist.');
      AssertFalse(LUser.Deleted, 'Deleted should persist.');
      AssertEquals(Ord(urNormal), Ord(LUser.Role), 'Role should persist.');
      AssertEquals(2, LUser.FailedAttempts, 'FailedAttempts should persist.');
      AssertFalse(LUser.Locked, 'Locked should persist.');
      AssertTrue(LUser.LastLoginAt > 0, 'LastLoginAt should persist.');
    finally
      LRepository.Free;
    end;
  finally
    DeleteFile(LTestFileName);
  end;
end;

procedure FilePersistencePersistsUserPreferences;
const
  LTestFileName = 'test_users_preferences.json';
var
  LRepository: TFileUserRepository;
  LUser: TUser;
begin
  DeleteFile(LTestFileName);
  try
    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      LUser := TUser.Create('user1', 'user1', 'User One', 'hash', 'salt',
        True, urNormal, 'user1@example.com', Now);
      LUser.PreferencesText := IniTextWriteValue('', 'User', 'ActiveLanguage', 'en');
      LUser.PreferencesText := IniTextWriteValue(LUser.PreferencesText, 'User',
        'LastMainOption', 'TSK');
      LRepository.Save(LUser);
    finally
      LRepository.Free;
    end;

    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      LUser := LRepository.FindById('user1');
      AssertEquals('en', IniTextReadValue(LUser.PreferencesText, 'User', 'ActiveLanguage'),
        'Active language should persist inside user.');
      AssertEquals('TSK', IniTextReadValue(LUser.PreferencesText, 'User', 'LastMainOption'),
        'Last main option should persist inside user.');
    finally
      LRepository.Free;
    end;
  finally
    DeleteFile(LTestFileName);
  end;
end;

procedure FilePersistenceRoundTripsPasswordHashAndSalt;
const
  LTestFileName = 'test_users_hash.json';
var
  LRepository: TFileUserRepository;
  LHasher: IPasswordHasher;
  LUser: TUser;
  LSalt: string;
  LHash: string;
begin
  DeleteFile(LTestFileName);
  try
    LHasher := TBasicPasswordHasher.Create;
    LSalt := 'jjfalcon-salt';
    LHash := LHasher.HashPassword('jjfalcon', LSalt);
    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      LUser := TUser.Create('user-1', 'jjfalcon', 'jjfalcon',
        LHash, LSalt, True, urNormal, 'jjfalcon@example.com', Now);
      LRepository.Save(LUser);
    finally
      LRepository.Free;
    end;

    LRepository := TFileUserRepository.Create(LTestFileName);
    try
      AssertEquals(1, LRepository.All.Count, 'Should load 1 user.');
      LUser := LRepository.FindByUsername('jjfalcon');
      AssertTrue(LUser <> nil, 'User jjfalcon should exist after reload.');
      AssertEquals(LSalt, LUser.Salt, 'Salt should persist through file round-trip.');
      AssertEquals(LHash, LUser.PasswordHash, 'PasswordHash should persist through file round-trip.');
      AssertTrue(LHasher.VerifyPassword('jjfalcon', LUser.Salt, LUser.PasswordHash),
        'Password verification should succeed after file round-trip.');
    finally
      LRepository.Free;
    end;
  finally
    DeleteFile(LTestFileName);
  end;
end;

procedure LoginSucceedsAfterFilePersistenceCreateUser;
const
  LTestFileName = 'test_users_login.json';
var
  LRepository: IUserRepository;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LService: TUserService;
  LSession: ISessionService;
  LAuth: IAuthService;
  LAdmin: TUser;
  LUser: TUser;
begin
  LService := nil;
  DeleteFile(LTestFileName);
  try
    LHasher := TBasicPasswordHasher.Create;
    LClock := TFixedClock.Create(EncodeDate(2026, 6, 9));
    LRepository := TFileUserRepository.Create(LTestFileName);
    LService := TUserService.Create(LRepository, LClock, LHasher);

    LAdmin := LService.EnsureDefaultAdmin;

    LUser := LService.CreateUser(LAdmin.Id, 'jjfalcon', 'jjfalcon',
      'jjfalcon@example.com', 'jjfalcon', urNormal);

    AssertTrue(LUser <> nil, 'User should be created.');
    AssertEquals('jjfalcon', LUser.Username, 'Username should match.');

    LSession := TSessionService.Create(LClock, 15);
    LAuth := TAuthService.Create(LRepository, LSession,
      TInMemoryLoginPreferencesRepository.Create, LHasher);

    LAuth.Login('jjfalcon', 'jjfalcon');
    AssertTrue(LSession.IsActive, 'Login should succeed after file persistence create user.');
  finally
    LService.Free;
    DeleteFile(LTestFileName);
  end;
end;

procedure LoginSucceedsAfterFileReload;
const
  LTestFileName = 'test_users_reload.json';
var
  LRepository: IUserRepository;
  LHasher: IPasswordHasher;
  LClock: IClock;
  LService: TUserService;
  LSession: ISessionService;
  LAuth: IAuthService;
  LAdmin: TUser;
  LUser: TUser;
begin
  LService := nil;
  DeleteFile(LTestFileName);
  try
    LHasher := TBasicPasswordHasher.Create;
    LClock := TFixedClock.Create(EncodeDate(2026, 6, 9));
    LRepository := TFileUserRepository.Create(LTestFileName);
    LService := TUserService.Create(LRepository, LClock, LHasher);

    LAdmin := LService.EnsureDefaultAdmin;
    LUser := LService.CreateUser(LAdmin.Id, 'jjfalcon', 'User',
      'jjfalcon@example.com', 'jjfalcon', urNormal);
    AssertTrue(LUser <> nil, 'User should be created.');
  finally
    LService.Free;
  end;

  LRepository := TFileUserRepository.Create(LTestFileName);
  try
    LSession := TSessionService.Create(LClock, 15);
    LAuth := TAuthService.Create(LRepository, LSession,
      TInMemoryLoginPreferencesRepository.Create, LHasher);

    LAuth.Login('jjfalcon', 'jjfalcon');
    AssertTrue(LSession.IsActive, 'Login should succeed after file reload.');
  finally
    DeleteFile(LTestFileName);
  end;
end;

procedure RunUserServiceTests(var AFailures: Integer);
begin
  RunTest('UserManagement_creates_default_admin_on_new_installation', UserManagementCreatesDefaultAdminOnNewInstallation, AFailures);
  RunTest('CreateUser_stores_active_unblocked_not_deleted_user', CreateUserStoresActiveUnblockedNotDeletedUser, AFailures);
  RunTest('CreateUser_rejects_invalid_email', CreateUserRejectsInvalidEmail, AFailures);
  RunTest('CreateUser_rejects_short_password', CreateUserRejectsShortPassword, AFailures);
  RunTest('CreateUser_rejects_duplicate_username', CreateUserRejectsDuplicateUsername, AFailures);
  RunTest('CreateUser_rejects_duplicate_email', CreateUserRejectsDuplicateEmail, AFailures);
  RunTest('CreateUser_rejects_non_admin_actor', CreateUserRejectsNonAdminActor, AFailures);
  RunTest('CreateUser_rejects_missing_required_fields', CreateUserRejectsMissingRequiredFields, AFailures);
  RunTest('CreateUser_rejects_blank_password', CreateUserRejectsBlankPassword, AFailures);
  RunTest('UpdateUser_rejects_self_modification', UpdateUserRejectsSelfModification, AFailures);
  RunTest('UpdateUser_rejects_unknown_user', UpdateUserRejectsUnknownUser, AFailures);
  RunTest('UpdateUser_allows_keeping_same_username_and_email', UpdateUserAllowsKeepingSameUsernameAndEmail, AFailures);
  RunTest('ActivateUser_makes_inactive_user_active', ActivateUserMakesInactiveUserActive, AFailures);
  RunTest('DeactivateUser_makes_user_inactive', DeactivateUserMakesUserInactive, AFailures);
  RunTest('BlockUser_locks_user', BlockUserLocksUser, AFailures);
  RunTest('UnlockUser_clears_lock_and_failed_attempts', UnlockUserClearsLockAndFailedAttempts, AFailures);
  RunTest('ChangePassword_replaces_old_credentials', ChangePasswordReplacesOldCredentials, AFailures);
  RunTest('DeleteUser_marks_user_as_deleted', DeleteUserMarksUserAsDeleted, AFailures);
  RunTest('DeleteUser_requires_confirmation', DeleteUserRequiresConfirmation, AFailures);
  RunTest('DeleteUser_prevents_future_login', DeleteUserPreventsFutureLogin, AFailures);
  RunTest('DeleteUser_rejects_reactivation', DeleteUserRejectsReactivation, AFailures);
  RunTest('DeleteUser_does_not_close_current_session', DeleteUserDoesNotCloseCurrentSession, AFailures);
  RunTest('ChangeRole_updates_permissions_on_next_login', ChangeRoleUpdatesPermissionsOnNextLogin, AFailures);
  RunTest('UserManagement_prevents_deactivating_last_active_admin', UserManagementPreventsRemovingLastActiveAdmin, AFailures);
  RunTest('UserManagement_prevents_blocking_last_active_admin', UserManagementPreventsBlockingLastActiveAdmin, AFailures);
  RunTest('UserManagement_prevents_deleting_last_active_admin', UserManagementPreventsDeletingLastActiveAdmin, AFailures);
  RunTest('UserManagement_prevents_downgrading_last_active_admin', UserManagementPreventsDowngradingLastActiveAdmin, AFailures);
  RunTest('SearchUsers_matches_username_display_name_and_email', SearchUsersMatchesUsernameDisplayNameAndEmail, AFailures);
  RunTest('ListUsers_excludes_deleted_users_by_default', ListUsersExcludesDeletedUsersByDefault, AFailures);
  RunTest('FilterUsers_returns_deleted_users_when_requested', FilterUsersReturnsDeletedUsersWhenRequested, AFailures);
  RunTest('FilterUsers_returns_only_active_users', FilterUsersReturnsOnlyActiveUsers, AFailures);
  RunTest('FilterUsers_returns_only_inactive_users', FilterUsersReturnsOnlyInactiveUsers, AFailures);
  RunTest('FilterUsers_returns_only_blocked_users', FilterUsersReturnsOnlyBlockedUsers, AFailures);
  RunTest('Login_updates_user_last_login_at', LoginUpdatesUserLastLoginAt, AFailures);
  RunTest('FilePersistence_saves_and_loads_users', FilePersistenceSavesAndLoadsUsers, AFailures);
  RunTest('FilePersistence_persists_multiple_fields', FilePersistencePersistsMultipleFields, AFailures);
  RunTest('FilePersistence_persists_user_preferences', FilePersistencePersistsUserPreferences, AFailures);
  RunTest('FilePersistence_round_trips_password_hash_and_salt', FilePersistenceRoundTripsPasswordHashAndSalt, AFailures);
  RunTest('Login_succeeds_after_file_persistence_create_user', LoginSucceedsAfterFilePersistenceCreateUser, AFailures);
  RunTest('Login_succeeds_after_file_reload', LoginSucceedsAfterFileReload, AFailures);
end;

end.
