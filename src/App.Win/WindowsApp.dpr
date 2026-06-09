program WindowsApp;

uses
  Controls,
  Forms,
  AboutForm in 'AboutForm.pas' {FrmAbout},
  LoginForm in 'LoginForm.pas' {FrmLogin},
  MainForm in 'MainForm.pas' {FrmMain},
  TaskForm in 'TaskForm.pas' {FrmTasks},
  UserForm in 'UserForm.pas' {FrmUsers},
  AppCoreAbout in '..\App.Core\AppCoreAbout.pas',
  AppCoreAuth in '..\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\App.Core\AppCoreClock.pas',
  AppCorePreferences in '..\App.Core\AppCorePreferences.pas',
  AppCoreTaskFileRepository in '..\App.Core\AppCoreTaskFileRepository.pas',
  AppCoreTaskItem in '..\App.Core\AppCoreTaskItem.pas',
  AppCoreTaskRepository in '..\App.Core\AppCoreTaskRepository.pas',
  AppCoreTaskService in '..\App.Core\AppCoreTaskService.pas',
  AppCoreUser in '..\App.Core\AppCoreUser.pas',
  AppCoreUserRepository in '..\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\App.Core\AppCoreUserService.pas';

begin
  Application.Initialize;
  Application.Title := 'Delphi TDD App';
  FrmLogin := TFrmLogin.Create(Application);
  try
    if FrmLogin.ShowModal = mrOk then
    begin
      Application.CreateForm(TFrmMain, FrmMain);
      FrmMain.UserRole := FrmLogin.LoggedInRole;
      FrmMain.ConfigureServices(FrmLogin.UserRepository, FrmLogin.SessionService,
        TSystemClock.Create, FrmLogin.PasswordHasher, FrmLogin.LoggedInUserId);
      FrmLogin.Free;
      FrmLogin := nil;
      Application.Run;
    end;
  finally
    FrmLogin.Free;
  end;
end.
