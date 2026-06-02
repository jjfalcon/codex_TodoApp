program WindowsApp;

uses
  Forms,
  MainForm in 'MainForm.pas' {FrmMain},
  AppCoreClock in '..\App.Core\AppCoreClock.pas',
  AppCoreTaskItem in '..\App.Core\AppCoreTaskItem.pas',
  AppCoreTaskRepository in '..\App.Core\AppCoreTaskRepository.pas',
  AppCoreTaskService in '..\App.Core\AppCoreTaskService.pas';

begin
  Application.Initialize;
  Application.Title := 'Delphi TDD App';
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
