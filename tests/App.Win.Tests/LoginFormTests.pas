unit LoginFormTests;

interface

procedure RunLoginFormTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  Controls,
  Forms,
  LoginForm,
  AppCoreAuth,
  AppCoreUser;

type
  TTestProc = procedure;

  TFakeAuthService = class(TInterfacedObject, IAuthService)
  private
    FLoginCalls: Integer;
    FLastUsername: string;
    FLastPassword: string;
    FErrorMessage: string;
    FUser: TUser;
  public
    constructor Create;
    destructor Destroy; override;
    function Login(const AUsername, APassword: string): TUser;
    procedure Logout;
    procedure FailWith(AError: Exception);
    property LoginCalls: Integer read FLoginCalls;
    property LastUsername: string read FLastUsername;
    property LastPassword: string read FLastPassword;
  end;

constructor TFakeAuthService.Create;
begin
  inherited Create;
  FUser := TUser.Create('u-1', 'admin', 'Administrador', 'hash', 'salt', True, urAdmin);
end;

destructor TFakeAuthService.Destroy;
begin
  FUser.Free;
  inherited Destroy;
end;

procedure TFakeAuthService.FailWith(AError: Exception);
begin
  FErrorMessage := AError.Message;
  AError.Free;
end;

function TFakeAuthService.Login(const AUsername, APassword: string): TUser;
begin
  Inc(FLoginCalls);
  FLastUsername := AUsername;
  FLastPassword := APassword;

  if FErrorMessage <> '' then
    raise EAuthenticationError.Create(FErrorMessage);

  Result := FUser;
end;

procedure TFakeAuthService.Logout;
begin
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

procedure RunTest(const AName: string; AProc: TTestProc; var AFailures: Integer);
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

function CreateLoginForm(const AAuth: IAuthService): TFrmLogin;
begin
  Result := TFrmLogin.Create(nil);
  Result.ConfigureForTests(AAuth);
end;

procedure LoginFormSetsInitialFocusToUsername;
var
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LAuth := TFakeAuthService.Create;
  LForm := CreateLoginForm(LAuth);
  try
    AssertTrue(LForm.ActiveControl = LForm.EdtUsername, 'Login form should focus username first.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormMasksPasswordInput;
var
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LAuth := TFakeAuthService.Create;
  LForm := CreateLoginForm(LAuth);
  try
    AssertTrue(LForm.EdtPassword.PasswordChar <> #0, 'Password edit should mask typed text.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormHasExpectedTabOrder;
var
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LAuth := TFakeAuthService.Create;
  LForm := CreateLoginForm(LAuth);
  try
    AssertEquals(0, LForm.EdtUsername.TabOrder, 'Username should be first in tab order.');
    AssertEquals(1, LForm.EdtPassword.TabOrder, 'Password should be second in tab order.');
    AssertEquals(2, LForm.BtnLogin.TabOrder, 'Login button should be third in tab order.');
    AssertEquals(3, LForm.BtnCancel.TabOrder, 'Cancel button should be fourth in tab order.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormCallsAuthOnAccept;
var
  LFakeAuth: TFakeAuthService;
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LFakeAuth := TFakeAuthService.Create;
  LAuth := LFakeAuth;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.EdtUsername.Text := 'admin';
    LForm.EdtPassword.Text := 'admin123';
    LForm.BtnLoginClick(nil);

    AssertEquals(1, LFakeAuth.LoginCalls, 'Login click should call auth once.');
    AssertEquals('admin', LFakeAuth.LastUsername, 'Login click should pass username.');
    AssertEquals('admin123', LFakeAuth.LastPassword, 'Login click should pass password.');
    AssertEquals(Ord(urAdmin), Ord(LForm.LoggedInRole), 'Login form should store authenticated role.');
    AssertEquals('u-1', LForm.LoggedInUserId, 'Login form should store authenticated user id.');
    AssertEquals(mrOk, LForm.ModalResult, 'Successful login should close form with OK.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormShowsErrorWhenLoginFails;
var
  LFakeAuth: TFakeAuthService;
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LFakeAuth := TFakeAuthService.Create;
  LFakeAuth.FailWith(EAuthenticationError.Create('Usuario o contrasena incorrectos.'));
  LAuth := LFakeAuth;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.EdtUsername.Text := 'admin';
    LForm.EdtPassword.Text := 'wrong';
    LForm.BtnLoginClick(nil);

    AssertEquals('Usuario o contrasena incorrectos.', LForm.LblMessage.Caption,
      'Login form should show auth errors.');
    AssertEquals(0, LForm.ModalResult, 'Failed login should keep dialog open.');
  finally
    LForm.Free;
  end;
end;

procedure RunLoginFormTests(var AFailures: Integer);
begin
  RunTest('LoginForm_sets_initial_focus_to_username', LoginFormSetsInitialFocusToUsername, AFailures);
  RunTest('LoginForm_masks_password_input', LoginFormMasksPasswordInput, AFailures);
  RunTest('LoginForm_has_expected_tab_order', LoginFormHasExpectedTabOrder, AFailures);
  RunTest('LoginForm_calls_auth_on_accept', LoginFormCallsAuthOnAccept, AFailures);
  RunTest('LoginForm_shows_error_when_login_fails', LoginFormShowsErrorWhenLoginFails, AFailures);
end;

end.
