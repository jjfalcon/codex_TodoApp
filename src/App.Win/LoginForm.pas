unit LoginForm;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  AppCoreLocalization,
  AppCoreAuth,
  AppCoreClock,
  AppCorePreferences,
  AppCoreRepositoryFactory,
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
    FSession: ISessionService;
    FHasher: IPasswordHasher;
    FLoggedInRole: TUserRole;
    FLoggedInUserId: string;
  public
    procedure Configure(const AFactory: IRepositoryFactory);
    procedure ConfigureForTests(const AAuth: IAuthService);
    procedure ApplyLanguage(const ALanguage: string);
    procedure ApplyLocalization(const ALocalization: ILocalizationService; AStrict: Boolean = True);
    property LoggedInRole: TUserRole read FLoggedInRole;
    property LoggedInUserId: string read FLoggedInUserId;
    property SessionService: ISessionService read FSession;
    property PasswordHasher: IPasswordHasher read FHasher;
  end;

var
  FrmLogin: TFrmLogin;

implementation

uses
  AppWinLocalization;

{$R *.dfm}

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

procedure TFrmLogin.ApplyLanguage(const ALanguage: string);
begin
  if LowerCase(ALanguage) = 'en' then
  begin
    Caption := 'Login';
    LblUsername.Caption := 'Username';
    LblPassword.Caption := 'Password';
    BtnLogin.Caption := 'Sign in';
    BtnCancel.Caption := 'Cancel';
  end
  else
  begin
    Caption := 'Login';
    LblUsername.Caption := 'Usuario';
    LblPassword.Caption := 'Contrasena';
    BtnLogin.Caption := 'Entrar';
    BtnCancel.Caption := 'Cancelar';
  end;
end;

procedure TFrmLogin.ApplyLocalization(const ALocalization: ILocalizationService;
  AStrict: Boolean);
begin
  AppWinLocalization.ApplyLocalization(Self, ALocalization, AStrict);
end;

procedure TFrmLogin.Configure(const AFactory: IRepositoryFactory);
var
  LUserService: TUserService;
  LUsers: IUserRepository;
begin
  FHasher := TBasicPasswordHasher.Create;
  LUsers := AFactory.CreateUserRepository;
  FSession := TSessionService.Create(TSystemClock.Create, 15);
  FPreferences := AFactory.CreateLoginPreferencesRepository;

  LUserService := TUserService.Create(LUsers, TSystemClock.Create, FHasher);
  LUserService.EnsureDefaultAdmin;

  FAuth := TAuthService.Create(LUsers, FSession, FPreferences, FHasher);

  EdtUsername.Text := FPreferences.LastUsername;
end;

procedure TFrmLogin.ConfigureForTests(const AAuth: IAuthService);
begin
  FAuth := AAuth;
end;

procedure TFrmLogin.FormCreate(Sender: TObject);
begin
  FLoggedInRole := urNormal;
  FLoggedInUserId := '';
  EdtPassword.PasswordChar := '*';
  LblMessage.Caption := '';
  ApplyLanguage('es');
  ActiveControl := EdtUsername;
end;

end.
