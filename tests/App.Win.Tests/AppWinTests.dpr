program AppWinTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Forms,
  AboutFormTests in 'AboutFormTests.pas',
  AppWinCsvTests in 'AppWinCsvTests.pas',
  AppWinCrudGridTests in 'AppWinCrudGridTests.pas',
  AppWinUpdateCheckerTests in 'AppWinUpdateCheckerTests.pas',
  CrudFormTests in 'CrudFormTests.pas',
  LocalizationAuditTests in 'LocalizationAuditTests.pas',
  LoginFormTests in 'LoginFormTests.pas',
  PreferencesFormTests in 'PreferencesFormTests.pas',
  AppWinLocalization in '..\..\src\App.Win\AppWinLocalization.pas',
  AppWinCsv in '..\..\src\App.Win\AppWinCsv.pas',
  AppWinCrudGrid in '..\..\src\App.Win\AppWinCrudGrid.pas',
  AppWinUpdateChecker in '..\..\src\App.Win\AppWinUpdateChecker.pas',
  CrudDetailForm in '..\..\src\App.Win\CrudDetailForm.pas',
  CrudForm in '..\..\src\App.Win\CrudForm.pas',
  CrudPreviewForm in '..\..\src\App.Win\CrudPreviewForm.pas',
  LoginForm in '..\..\src\App.Win\LoginForm.pas',
  AppCoreCrud in '..\..\src\App.Core\AppCoreCrud.pas',
  PreferencesForm in '..\..\src\App.Win\PreferencesForm.pas',
  AppCoreAuth in '..\..\src\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\..\src\App.Core\AppCoreClock.pas',
  AppCoreDiagnostics in '..\..\src\App.Core\AppCoreDiagnostics.pas',
  AppCoreLocalization in '..\..\src\App.Core\AppCoreLocalization.pas',
  AppCorePreferences in '..\..\src\App.Core\AppCorePreferences.pas',
  AppCoreRepositoryFactory in '..\..\src\App.Core\AppCoreRepositoryFactory.pas',
  AppCoreUpdate in '..\..\src\App.Core\AppCoreUpdate.pas',
  AppCoreUser in '..\..\src\App.Core\AppCoreUser.pas',
  AppCoreUserRepository in '..\..\src\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\..\src\App.Core\AppCoreUserService.pas';

var
  Failures: Integer;
begin
  Failures := 0;

  try
    Application.Initialize;
    RunAboutFormTests(Failures);
    RunAppWinCsvTests(Failures);
    RunAppWinCrudGridTests(Failures);
    RunAppWinUpdateCheckerTests(Failures);
    RunCrudFormTests(Failures);
    RunLoginFormTests(Failures);
    RunPreferencesFormTests(Failures);
    RunLocalizationAuditTests(Failures);

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
