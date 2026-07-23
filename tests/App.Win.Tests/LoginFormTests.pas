unit LoginFormTests;

interface

procedure RunLoginFormTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  Windows,
  Controls,
  Forms,
  LoginForm,
  AppCoreAuth,
  AppCoreLocalization,
  AppCoreUser;

type
  TTestProc = procedure;

  TFakeAuthService = class(TInterfacedObject, IAuthService)
  private
    FLoginCalls: Integer;
    FLastUsername: string;
    FLastPassword: string;
    FError: Exception;
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

  TFakeLocalizationService = class(TInterfacedObject, ILocalizationService)
  private
    FTexts: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    function Language: string;
    function HasText(const AKey: string): Boolean;
    function Text(const AKey: string): string;
    procedure AddKeysForForm(const AFormName: string; AKeys: TStrings);
    procedure ChangeLanguage(const ALanguage: string);
    procedure AddText(const AKey, AValue: string);
  end;

constructor TFakeAuthService.Create;
begin
  inherited Create;
  FUser := TUser.Create('u-1', 'admin', 'Administrador', 'hash', 'salt', True, urAdmin);
end;

destructor TFakeAuthService.Destroy;
begin
  FError.Free;
  FUser.Free;
  inherited Destroy;
end;

procedure TFakeAuthService.FailWith(AError: Exception);
begin
  FError.Free;
  FError := AError;
end;

function TFakeAuthService.Login(const AUsername, APassword: string): TUser;
begin
  Inc(FLoginCalls);
  FLastUsername := AUsername;
  FLastPassword := APassword;

  if FError <> nil then
  begin
    if FError is ELoginValidationError then
      raise ELoginValidationError.Create(FError.Message);
    if FError is EInactiveUserError then
      raise EInactiveUserError.Create(FError.Message);
    if FError is EUserLockedError then
      raise EUserLockedError.Create(FError.Message);
    raise EAuthenticationError.Create(FError.Message);
  end;

  Result := FUser;
end;

procedure TFakeAuthService.Logout;
begin
end;

constructor TFakeLocalizationService.Create;
begin
  inherited Create;
  FTexts := TStringList.Create;
end;

destructor TFakeLocalizationService.Destroy;
begin
  FTexts.Free;
  inherited Destroy;
end;

procedure TFakeLocalizationService.AddText(const AKey, AValue: string);
begin
  FTexts.Values[AKey] := AValue;
end;

procedure TFakeLocalizationService.ChangeLanguage(const ALanguage: string);
begin
end;

function TFakeLocalizationService.Language: string;
begin
  Result := 'en';
end;

function TFakeLocalizationService.HasText(const AKey: string): Boolean;
begin
  Result := FTexts.IndexOfName(AKey) >= 0;
end;

function TFakeLocalizationService.Text(const AKey: string): string;
begin
  Result := FTexts.Values[AKey];
end;

procedure TFakeLocalizationService.AddKeysForForm(const AFormName: string;
  AKeys: TStrings);
var
  I: Integer;
  LPrefix: string;
  LKey: string;
begin
  LPrefix := AFormName + '.';
  for I := 0 to FTexts.Count - 1 do
  begin
    LKey := FTexts.Names[I];
    if Copy(LKey, 1, Length(LPrefix)) = LPrefix then
      AKeys.Add(LKey);
  end;
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

procedure AssertStartsWith(const APrefix, AActual: string; const AMessage: string);
begin
  if Copy(AActual, 1, Length(APrefix)) <> APrefix then
    raise Exception.Create(AMessage + ' Expected prefix "' + APrefix + '", got "' + AActual + '".');
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

procedure LoginFormLoadsSpanishTextsByDefault;
var
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LAuth := TFakeAuthService.Create;
  LForm := CreateLoginForm(LAuth);
  try
    AssertEquals('Login', LForm.Caption, 'Login form should load default title.');
    AssertEquals('Usuario', LForm.LblUsername.Caption, 'Login form should load default username label.');
    AssertEquals('Contrase' + Chr(241) + 'a', LForm.LblPassword.Caption, 'Login form should load default password label.');
    AssertEquals('Entrar', LForm.BtnLogin.Caption, 'Login form should load default login button.');
    AssertEquals('Cancelar', LForm.BtnCancel.Caption, 'Login form should load default cancel button.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormLoadsEnglishTextsWhenSelected;
var
  LAuth: IAuthService;
  LLocalization: TFakeLocalizationService;
  LForm: TFrmLogin;
begin
  LAuth := TFakeAuthService.Create;
  LLocalization := TFakeLocalizationService.Create;
  LLocalization.AddText('FrmLogin.Caption', 'Login');
  LLocalization.AddText('FrmLogin.LblUsername.Caption', 'Username');
  LLocalization.AddText('FrmLogin.LblPassword.Caption', 'Password');
  LLocalization.AddText('FrmLogin.BtnLogin.Caption', 'Sign in');
  LLocalization.AddText('FrmLogin.BtnCancel.Caption', 'Cancel');
  LForm := CreateLoginForm(LAuth);
  try
    LForm.ApplyLocalization(LLocalization);

    AssertEquals('Login', LForm.Caption, 'Login form should load English title.');
    AssertEquals('Username', LForm.LblUsername.Caption, 'Login form should load English username label.');
    AssertEquals('Password', LForm.LblPassword.Caption, 'Login form should load English password label.');
    AssertEquals('Sign in', LForm.BtnLogin.Caption, 'Login form should load English login button.');
    AssertEquals('Cancel', LForm.BtnCancel.Caption, 'Login form should load English cancel button.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormApplyLanguageLoadsEnglishTexts;
var
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LAuth := TFakeAuthService.Create;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.ApplyLanguage('en');

    AssertEquals('Login', LForm.Caption, 'Login form should load English title.');
    AssertEquals('Username', LForm.LblUsername.Caption, 'Login form should load English username label.');
    AssertEquals('Password', LForm.LblPassword.Caption, 'Login form should load English password label.');
    AssertEquals('Sign in', LForm.BtnLogin.Caption, 'Login form should load English login button.');
    AssertEquals('Cancel', LForm.BtnCancel.Caption, 'Login form should load English cancel button.');
  finally
    LForm.Free;
  end;
end;
procedure LoginFormTabMovesThroughFieldsInOrder;
var
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LAuth := TFakeAuthService.Create;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.Show;
    Application.ProcessMessages;
    LForm.ActiveControl := LForm.EdtUsername;

    LForm.Perform(CM_DIALOGKEY, VK_TAB, 0);
    AssertTrue(LForm.ActiveControl = LForm.EdtPassword, 'TAB from username should focus password.');

    LForm.Perform(CM_DIALOGKEY, VK_TAB, 0);
    AssertTrue(LForm.ActiveControl = LForm.BtnLogin, 'TAB from password should focus login button.');

    LForm.Perform(CM_DIALOGKEY, VK_TAB, 0);
    AssertTrue(LForm.ActiveControl = LForm.BtnCancel, 'TAB from login button should focus cancel button.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormEnterTriggersDefaultLoginButton;
var
  LFakeAuth: TFakeAuthService;
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LFakeAuth := TFakeAuthService.Create;
  LAuth := LFakeAuth;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.Show;
    Application.ProcessMessages;

    LForm.EdtUsername.Text := 'admin';
    LForm.EdtPassword.Text := 'admin123';
    LForm.ActiveControl := LForm.EdtPassword;

    LForm.Perform(CM_DIALOGKEY, VK_RETURN, 0);

    AssertEquals(1, LFakeAuth.LoginCalls, 'ENTER should trigger the default login button.');
    AssertEquals(mrOk, LForm.ModalResult, 'ENTER login should close form with OK.');
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
  LFakeAuth.FailWith(EAuthenticationError.Create('Usuario o contrase�a incorrectos.'));
  LAuth := LFakeAuth;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.EdtUsername.Text := 'admin';
    LForm.EdtPassword.Text := 'wrong';
    LForm.BtnLoginClick(nil);

    AssertEquals('Usuario o contrase�a incorrectos.', LForm.LblMessage.Caption,
      'Login form should show auth errors.');
    AssertEquals(0, LForm.ModalResult, 'Failed login should keep dialog open.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormShowsValidationErrorWhenLoginInputIsInvalid;
var
  LFakeAuth: TFakeAuthService;
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LFakeAuth := TFakeAuthService.Create;
  LFakeAuth.FailWith(ELoginValidationError.Create('El usuario es obligatorio.'));
  LAuth := LFakeAuth;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.BtnLoginClick(nil);

    AssertEquals('El usuario es obligatorio.', LForm.LblMessage.Caption,
      'Login form should show validation errors.');
    AssertEquals(0, LForm.ModalResult, 'Validation error should keep dialog open.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormShowsInactiveUserErrorWhenUserIsInactive;
var
  LFakeAuth: TFakeAuthService;
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LFakeAuth := TFakeAuthService.Create;
  LFakeAuth.FailWith(EInactiveUserError.Create('El usuario esta inactivo.'));
  LAuth := LFakeAuth;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.BtnLoginClick(nil);

    AssertEquals('El usuario esta inactivo.', LForm.LblMessage.Caption,
      'Login form should show inactive user errors.');
    AssertEquals(0, LForm.ModalResult, 'Inactive user error should keep dialog open.');
  finally
    LForm.Free;
  end;
end;

procedure LoginFormShowsLockedUserErrorWhenUserIsLocked;
var
  LFakeAuth: TFakeAuthService;
  LAuth: IAuthService;
  LForm: TFrmLogin;
begin
  LFakeAuth := TFakeAuthService.Create;
  LFakeAuth.FailWith(EUserLockedError.Create('El usuario esta bloqueado.'));
  LAuth := LFakeAuth;
  LForm := CreateLoginForm(LAuth);
  try
    LForm.BtnLoginClick(nil);

    AssertEquals('El usuario esta bloqueado.', LForm.LblMessage.Caption,
      'Login form should show locked user errors.');
    AssertEquals(0, LForm.ModalResult, 'Locked user error should keep dialog open.');
  finally
    LForm.Free;
  end;
end;
procedure RunLoginFormTests(var AFailures: Integer);
begin
  RunTest('LoginForm_sets_initial_focus_to_username', LoginFormSetsInitialFocusToUsername, AFailures);
  RunTest('LoginForm_masks_password_input', LoginFormMasksPasswordInput, AFailures);
  RunTest('LoginForm_has_expected_tab_order', LoginFormHasExpectedTabOrder, AFailures);
  RunTest('LoginForm_loads_spanish_texts_by_default', LoginFormLoadsSpanishTextsByDefault, AFailures);
  RunTest('LoginForm_loads_english_texts_when_selected', LoginFormLoadsEnglishTextsWhenSelected, AFailures);
  RunTest('LoginForm_apply_language_loads_english_texts', LoginFormApplyLanguageLoadsEnglishTexts, AFailures);
  RunTest('LoginForm_tab_moves_through_fields_in_order', LoginFormTabMovesThroughFieldsInOrder, AFailures);
  RunTest('LoginForm_enter_triggers_default_login_button', LoginFormEnterTriggersDefaultLoginButton, AFailures);
  RunTest('LoginForm_calls_auth_on_accept', LoginFormCallsAuthOnAccept, AFailures);
  RunTest('LoginForm_shows_error_when_login_fails', LoginFormShowsErrorWhenLoginFails, AFailures);
  RunTest('LoginForm_shows_validation_error_when_login_input_is_invalid', LoginFormShowsValidationErrorWhenLoginInputIsInvalid, AFailures);
  RunTest('LoginForm_shows_inactive_user_error_when_user_is_inactive', LoginFormShowsInactiveUserErrorWhenUserIsInactive, AFailures);
  RunTest('LoginForm_shows_locked_user_error_when_user_is_locked', LoginFormShowsLockedUserErrorWhenUserIsLocked, AFailures);
end;

end.
