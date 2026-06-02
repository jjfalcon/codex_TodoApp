unit LoginForm;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  AppCoreAuth,
  AppCorePreferences,
  AppCoreUser,
  AppCoreUserRepository;

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
    FLoggedInRole: TUserRole;

    procedure BuildAuthServices;
    procedure AddUser(const ARepository: TInMemoryUserRepository; const AHasher: IPasswordHasher;
      const AUsername, APassword, ADisplayName: string; AActive: Boolean; ARole: TUserRole;
      AFailedAttempts: Integer; ALocked: Boolean);
  public
    property LoggedInRole: TUserRole read FLoggedInRole;
  end;

var
  FrmLogin: TFrmLogin;

implementation

{$R *.dfm}

uses
  AppCoreClock;

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
  LUsers: IUserRepository;
  LSession: ISessionService;
  LHasher: IPasswordHasher;
begin
  LHasher := TBasicPasswordHasher.Create;
  LRepository := TInMemoryUserRepository.Create;
  LUsers := LRepository;
  LSession := TSessionService.Create(TSystemClock.Create, 15);
  FPreferences := TInMemoryLoginPreferencesRepository.Create;

  AddUser(LRepository, LHasher, 'admin', 'admin123', 'Administrador', True, urAdmin, 0, False);
  AddUser(LRepository, LHasher, 'user', 'user123', 'Usuario normal', True, urNormal, 0, False);
  AddUser(LRepository, LHasher, 'disabled', 'disabled123', 'Usuario inactivo', False, urNormal, 0, False);
  AddUser(LRepository, LHasher, 'locked', 'locked123', 'Usuario bloqueado', True, urNormal, 3, True);

  FAuth := TAuthService.Create(LUsers, LSession, FPreferences, LHasher);
end;

procedure TFrmLogin.FormCreate(Sender: TObject);
begin
  BuildAuthServices;
  FLoggedInRole := urNormal;
  EdtUsername.Text := FPreferences.LastUsername;
  EdtPassword.PasswordChar := '*';
  LblMessage.Caption := '';
end;

end.
