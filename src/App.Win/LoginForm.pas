unit LoginForm;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  AppCoreAuth,
  AppCoreClock,
  AppCorePreferences,
  AppCoreUser,
  AppCoreUserRepository,
  AppCoreUserService;

type
  TFrmLogin = class(TForm)
    LblUsername: TLabel;
    EdtUsername: TEdit;
    LblPassword: TLabel;
    EdtPassword: TEdit;
    BtnLogin: TButton;
    BtnCancel: TButton;
    LblMessage: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure BtnLoginClick(Sender: TObject);
  private
    FAuth: IAuthService;
    FPreferences: ILoginPreferencesRepository;
    FUsers: IUserRepository;
    FSession: ISessionService;
    FHasher: IPasswordHasher;
    FLoggedInRole: TUserRole;
    FLoggedInUserId: string;

    procedure BuildAuthServices;
    procedure AddUser(const ARepository: TInMemoryUserRepository; const AHasher: IPasswordHasher;
      const AUsername, APassword, ADisplayName: string; AActive: Boolean; ARole: TUserRole;
      AFailedAttempts: Integer; ALocked: Boolean);
  public
    property LoggedInRole: TUserRole read FLoggedInRole;
    property LoggedInUserId: string read FLoggedInUserId;
    property UserRepository: IUserRepository read FUsers;
    property SessionService: ISessionService read FSession;
    property PasswordHasher: IPasswordHasher read FHasher;
  end;

var
  FrmLogin: TFrmLogin;

implementation

{$R *.dfm}

procedure TFrmLogin.AddUser(const ARepository: TInMemoryUserRepository;
  const AHasher: IPasswordHasher; const AUsername, APassword,
  ADisplayName: string; AActive: Boolean; ARole: TUserRole;
  AFailedAttempts: Integer; ALocked: Boolean);
var
  LUser: TUser;
  LSalt: string;
begin
  LSalt := AUsername + '-salt';
  LUser := TUser.Create(AUsername, AUsername, ADisplayName,
    AHasher.HashPassword(APassword, LSalt), LSalt, AActive, ARole);
  LUser.Email := AUsername + '@example.com';
  LUser.FailedAttempts := AFailedAttempts;
  LUser.Locked := ALocked;
  ARepository.Add(LUser);
end;

procedure TFrmLogin.BtnLoginClick(Sender: TObject);
var
  LUser: TUser;
begin
  LblMessage.Caption := '';
  try
    LUser := FAuth.Login(EdtUsername.Text, EdtPassword.Text);
    FLoggedInRole := LUser.Role;
    FLoggedInUserId := LUser.Id;
    ModalResult := mrOk;
  except
    on E: ELoginValidationError do
      LblMessage.Caption := E.Message;
    on E: EAuthenticationError do
      LblMessage.Caption := E.Message;
    on E: EInactiveUserError do
      LblMessage.Caption := E.Message;
    on E: EUserLockedError do
      LblMessage.Caption := E.Message;
  end;
end;

procedure TFrmLogin.BuildAuthServices;
var
  LRepository: TInMemoryUserRepository;
  LUserService: TUserService;
begin
  FHasher := TBasicPasswordHasher.Create;
  LRepository := TInMemoryUserRepository.Create;
  FUsers := LRepository;
  FSession := TSessionService.Create(TSystemClock.Create, 15);
  FPreferences := TInMemoryLoginPreferencesRepository.Create;

  LUserService := TUserService.Create(FUsers, TSystemClock.Create, FHasher);
  LUserService.EnsureDefaultAdmin;
  AddUser(LRepository, FHasher, 'user', 'user123', 'Usuario normal', True, urNormal, 0, False);
  AddUser(LRepository, FHasher, 'disabled', 'disabled123', 'Usuario inactivo', False, urNormal, 0, False);
  AddUser(LRepository, FHasher, 'locked', 'locked123', 'Usuario bloqueado', True, urNormal, 3, True);

  FAuth := TAuthService.Create(FUsers, FSession, FPreferences, FHasher);
end;

procedure TFrmLogin.FormCreate(Sender: TObject);
begin
  BuildAuthServices;
  FLoggedInRole := urNormal;
  FLoggedInUserId := '';
  EdtUsername.Text := FPreferences.LastUsername;
  EdtPassword.PasswordChar := '*';
  LblMessage.Caption := '';
end;

end.
