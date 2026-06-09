program AppCoreTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  AppCoreAuthServiceTests in 'AppCoreAuthServiceTests.pas',
  AppCoreTaskServiceTests in 'AppCoreTaskServiceTests.pas',
  AppCoreUserServiceTests in 'AppCoreUserServiceTests.pas',
  AppCoreAuth in '..\..\src\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\..\src\App.Core\AppCoreClock.pas',
  AppCorePreferences in '..\..\src\App.Core\AppCorePreferences.pas',
  AppCoreTaskFileRepository in '..\..\src\App.Core\AppCoreTaskFileRepository.pas',
  AppCoreTaskItem in '..\..\src\App.Core\AppCoreTaskItem.pas',
  AppCoreTaskRepository in '..\..\src\App.Core\AppCoreTaskRepository.pas',
  AppCoreTaskService in '..\..\src\App.Core\AppCoreTaskService.pas',
  AppCoreUser in '..\..\src\App.Core\AppCoreUser.pas',
  AppCoreUserRepository in '..\..\src\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\..\src\App.Core\AppCoreUserService.pas';

var
  Failures: Integer;
begin
  Failures := 0;

  try
    RunAuthServiceTests(Failures);
    RunUserServiceTests(Failures);
    RunTaskServiceTests(Failures);

    if Failures = 0 then
      Writeln('All tests passed.')
    else
      Writeln(IntToStr(Failures) + ' test(s) failed.');
    if Failures <> 0 then
      Halt(1);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
