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
  AppCoreUserFileRepository,
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
  LUserService: TUserService;
begin
  FHasher := TBasicPasswordHasher.Create;
  FUsers := TFileUserRepository.Create(ExtractFilePath(Application.ExeName) + 'users.json');
  FSession := TSessionService.Create(TSystemClock.Create, 15);
  FPreferences := TInMemoryLoginPreferencesRepository.Create;

  LUserService := TUserService.Create(FUsers, TSystemClock.Create, FHasher);
  LUserService.EnsureDefaultAdmin;

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
