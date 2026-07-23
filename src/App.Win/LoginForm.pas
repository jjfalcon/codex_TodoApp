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
  AppCoreDiagnostics,
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
    FDiagnostics: IDiagnosticsLogger;
    FLoggedInRole: TUserRole;
    FLoggedInUserId: string;
  public
    procedure Configure(const AFactory: IRepositoryFactory);
    procedure ConfigureDiagnostics(const ADiagnostics: IDiagnosticsLogger);
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
  LTimer: TDiagnosticTimer;
begin
  LblMessage.Caption := '';
  LTimer := TDiagnosticTimer.Create;
  try
    try
      LTimer.Start;
      LUser := FAuth.Login(EdtUsername.Text, EdtPassword.Text);
      FLoggedInRole := LUser.Role;
      FLoggedInUserId := LUser.Id;
      if FDiagnostics <> nil then
        FDiagnostics.Timing('Auth.Login', 'result=ok username=' + EdtUsername.Text,
          LTimer.ElapsedMs);
      ModalResult := mrOk;
    except
      on E: ELoginValidationError do
      begin
        if FDiagnostics <> nil then
          FDiagnostics.Timing('Auth.Login', 'result=validation_error username=' + EdtUsername.Text,
            LTimer.ElapsedMs);
        LblMessage.Caption := E.Message;
      end;
      on E: EAuthenticationError do
      begin
        if FDiagnostics <> nil then
          FDiagnostics.Timing('Auth.Login', 'result=authentication_error username=' + EdtUsername.Text,
            LTimer.ElapsedMs);
        LblMessage.Caption := E.Message;
      end;
      on E: EInactiveUserError do
      begin
        if FDiagnostics <> nil then
          FDiagnostics.Timing('Auth.Login', 'result=inactive_user username=' + EdtUsername.Text,
            LTimer.ElapsedMs);
        LblMessage.Caption := E.Message;
      end;
      on E: EUserLockedError do
      begin
        if FDiagnostics <> nil then
          FDiagnostics.Timing('Auth.Login', 'result=locked_user username=' + EdtUsername.Text,
            LTimer.ElapsedMs);
        LblMessage.Caption := E.Message;
      end;
    end;
  finally
    LTimer.Free;
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
    LblPassword.Caption := 'Contraseña';
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

procedure TFrmLogin.ConfigureDiagnostics(const ADiagnostics: IDiagnosticsLogger);
begin
  FDiagnostics := ADiagnostics;
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
