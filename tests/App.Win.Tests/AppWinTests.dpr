program AppWinTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Forms,
  LoginFormTests in 'LoginFormTests.pas',
  AppWinLocalization in '..\..\src\App.Win\AppWinLocalization.pas',
  LoginForm in '..\..\src\App.Win\LoginForm.pas',
  AppCoreAuth in '..\..\src\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\..\src\App.Core\AppCoreClock.pas',
  AppCoreLocalization in '..\..\src\App.Core\AppCoreLocalization.pas',
  AppCorePreferences in '..\..\src\App.Core\AppCorePreferences.pas',
  AppCoreRepositoryFactory in '..\..\src\App.Core\AppCoreRepositoryFactory.pas',
  AppCoreUser in '..\..\src\App.Core\AppCoreUser.pas',
  AppCoreUserRepository in '..\..\src\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\..\src\App.Core\AppCoreUserService.pas';

var
  Failures: Integer;
begin
  Failures := 0;

  try
    Application.Initialize;
    RunLoginFormTests(Failures);

    if Failures = 0 then
      Writeln('All tests passed.')
    else
      Writeln(IntToStr(Failures) + ' test(s) failed.');
    Readln;
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
