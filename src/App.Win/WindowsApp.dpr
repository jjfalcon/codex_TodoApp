program WindowsApp;

uses
  Controls,
  Forms,
  SysUtils,
  AboutForm in 'AboutForm.pas' {FrmAbout},
  LoginForm in 'LoginForm.pas' {FrmLogin},
  MainForm in 'MainForm.pas' {FrmMain},
  TaskForm in 'TaskForm.pas' {FrmTasks},
  UserForm in 'UserForm.pas' {FrmUsers},
  AppCoreAbout in '..\App.Core\AppCoreAbout.pas',
  AppCoreAuth in '..\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\App.Core\AppCoreClock.pas',
  AppCoreConfiguration in '..\App.Core\AppCoreConfiguration.pas',
  AppCoreLocalization in '..\App.Core\AppCoreLocalization.pas',
  AppCorePreferencesFileRepository in '..\App.Core\AppCorePreferencesFileRepository.pas',
  AppCoreJsonUtils in '..\App.Core\AppCoreJsonUtils.pas',
  AppCorePreferences in '..\App.Core\AppCorePreferences.pas',
  AppCoreRepositoryFactory in '..\App.Core\AppCoreRepositoryFactory.pas',
  AppCoreTaskFileRepository in '..\App.Core\AppCoreTaskFileRepository.pas',
  AppCoreTaskItem in '..\App.Core\AppCoreTaskItem.pas',
  AppCoreTaskRepository in '..\App.Core\AppCoreTaskRepository.pas',
  AppCoreTaskService in '..\App.Core\AppCoreTaskService.pas',
  AppCoreUser in '..\App.Core\AppCoreUser.pas',
  AppCoreUserFileRepository in '..\App.Core\AppCoreUserFileRepository.pas',
  AppCoreUserRepository in '..\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\App.Core\AppCoreUserService.pas';

var
  LConfig: TAppConfiguration;
  LFactory: IRepositoryFactory;
  LLocalization: ILocalizationService;
begin
  Application.Initialize;
  Application.Title := 'Delphi TDD App';

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
    FrmLogin.ApplyLocalization(LLocalization, False);

    if FrmLogin.ShowModal = mrOk then
    begin
      Application.CreateForm(TFrmMain, FrmMain);
      FrmMain.UserRole := FrmLogin.LoggedInRole;
      FrmMain.ConfigureServices(LFactory, FrmLogin.SessionService,
        TSystemClock.Create, FrmLogin.PasswordHasher, FrmLogin.LoggedInUserId,
        LLocalization);
      FrmLogin.Free;
      FrmLogin := nil;
      Application.Run;
    end;
  finally
    FrmLogin.Free;
  end;
end.
