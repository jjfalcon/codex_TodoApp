program WindowsApp;

uses
  Controls,
  Forms,
  SysUtils,
  AboutForm in 'AboutForm.pas' {FrmAbout},
  CrudDetailForm in 'CrudDetailForm.pas' {FrmCrudDetail},
  CrudForm in 'CrudForm.pas' {FrmCrud},
  CrudPreviewForm in 'CrudPreviewForm.pas' {FrmCrudPreview},
  CrudSearchForm in 'CrudSearchForm.pas' {FrmCrudSearch},
  LoginForm in 'LoginForm.pas' {FrmLogin},
  MainForm in 'MainForm.pas' {FrmMain},
  PreferencesForm in 'PreferencesForm.pas' {FrmPreferences},
  TaskForm in 'TaskForm.pas' {FrmTasks},
  UserForm in 'UserForm.pas' {FrmUsers},
  AppCoreAbout in '..\App.Core\AppCoreAbout.pas',
  AppCoreBuildInfo in '..\App.Core\AppCoreBuildInfo.pas',
  AppCoreDiagnostics in '..\App.Core\AppCoreDiagnostics.pas',
  AppCoreAuth in '..\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\App.Core\AppCoreClock.pas',
  AppCoreConfiguration in '..\App.Core\AppCoreConfiguration.pas',
  AppCoreCrud in '..\App.Core\AppCoreCrud.pas',
  AppCoreLocalization in '..\App.Core\AppCoreLocalization.pas',
  AppCorePreferencesFileRepository in '..\App.Core\AppCorePreferencesFileRepository.pas',
  AppCoreJsonUtils in '..\App.Core\AppCoreJsonUtils.pas',
  AppCorePreferences in '..\App.Core\AppCorePreferences.pas',
  AppCoreRepositoryFactory in '..\App.Core\AppCoreRepositoryFactory.pas',
  AppCoreTaskFileRepository in '..\App.Core\AppCoreTaskFileRepository.pas',
  AppCoreTaskCrudProvider in '..\App.Core\AppCoreTaskCrudProvider.pas',
  AppCoreTaskItem in '..\App.Core\AppCoreTaskItem.pas',
  AppCoreTaskRepository in '..\App.Core\AppCoreTaskRepository.pas',
  AppCoreTaskService in '..\App.Core\AppCoreTaskService.pas',
  AppCoreUser in '..\App.Core\AppCoreUser.pas',
  AppCoreUserCrudProvider in '..\App.Core\AppCoreUserCrudProvider.pas',
  AppCoreUserFileRepository in '..\App.Core\AppCoreUserFileRepository.pas',
  AppCoreUserRepository in '..\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\App.Core\AppCoreUserService.pas';

type
  TApplicationExceptionHandler = class
  private
    FDiagnostics: IDiagnosticsLogger;
  public
    constructor Create(const ADiagnostics: IDiagnosticsLogger);
    procedure HandleException(Sender: TObject; E: Exception);
  end;

var
  LConfig: TAppConfiguration;
  LFactory: IRepositoryFactory;
  LLocalization: ILocalizationService;
  LDiagnostics: IDiagnosticsLogger;
  LExceptionHandler: TApplicationExceptionHandler;

constructor TApplicationExceptionHandler.Create(
  const ADiagnostics: IDiagnosticsLogger);
begin
  inherited Create;
  FDiagnostics := ADiagnostics;
end;

procedure TApplicationExceptionHandler.HandleException(Sender: TObject;
  E: Exception);
begin
  if FDiagnostics <> nil then
    FDiagnostics.Error('App.UnhandledException', E.ClassName + ': ' + E.Message);
end;

begin
  Application.Initialize;
  Application.Title := 'Delphi TDD App';
  LDiagnostics := TFileDiagnosticsLogger.Create(
    ExtractFilePath(Application.ExeName) + 'logs\application.log');
  LDiagnostics.Info('App.Start', 'Application started');
  LExceptionHandler := TApplicationExceptionHandler.Create(LDiagnostics);
  Application.OnException := LExceptionHandler.HandleException;

  LConfig := TAppConfiguration.Create(
    ExtractFilePath(Application.ExeName) + 'app.config');
  try
    if LConfig.Backend = 'json' then
      LFactory := TJsonRepositoryFactory.Create(LConfig.DataPath)
    else
      LFactory := TJsonRepositoryFactory.Create(LConfig.DataPath);
    LLocalization := TCsvLocalizationService.Create(
      ExtractFilePath(Application.ExeName) + LConfig.LanguageFile,
      LConfig.Language,
      'es');
  finally
    LConfig.Free;
  end;

  FrmLogin := TFrmLogin.Create(Application);
  try
    FrmLogin.Configure(LFactory);
    FrmLogin.ConfigureDiagnostics(LDiagnostics);
    FrmLogin.ApplyLocalization(LLocalization, False);

    if FrmLogin.ShowModal = mrOk then
    begin
      Application.CreateForm(TFrmMain, FrmMain);
      FrmMain.UserRole := FrmLogin.LoggedInRole;
      FrmMain.ConfigureServices(LFactory, FrmLogin.SessionService,
        TSystemClock.Create, FrmLogin.PasswordHasher, FrmLogin.LoggedInUserId,
        LLocalization, LDiagnostics);
      FrmLogin.Free;
      FrmLogin := nil;
      Application.Run;
    end;
  finally
    if LDiagnostics <> nil then
      LDiagnostics.Info('App.Stop', 'Application stopped');
    FrmLogin.Free;
    LExceptionHandler.Free;
  end;
end.
