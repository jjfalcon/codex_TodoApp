program AppCoreTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  AppCoreTaskServiceTests in 'AppCoreTaskServiceTests.pas',
  AppCoreClock in '..\..\src\App.Core\AppCoreClock.pas',
  AppCoreTaskItem in '..\..\src\App.Core\AppCoreTaskItem.pas',
  AppCoreTaskRepository in '..\..\src\App.Core\AppCoreTaskRepository.pas',
  AppCoreTaskService in '..\..\src\App.Core\AppCoreTaskService.pas';

var
  Failures: Integer;
begin
  Failures := 0;

  try
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
