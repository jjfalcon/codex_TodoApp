program AppCoreTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  IniFiles,
  AppCoreAboutServiceTests in 'AppCoreAboutServiceTests.pas',
  AppCoreAuthServiceTests in 'AppCoreAuthServiceTests.pas',
  AppCoreConfigurationTests in 'AppCoreConfigurationTests.pas',
  AppCoreLocalizationTests in 'AppCoreLocalizationTests.pas',
  AppCorePreferencesFileRepositoryTests in 'AppCorePreferencesFileRepositoryTests.pas',
  AppCoreRepositoryFactoryTests in 'AppCoreRepositoryFactoryTests.pas',
  AppCoreTaskServiceTests in 'AppCoreTaskServiceTests.pas',
  AppCoreUserServiceTests in 'AppCoreUserServiceTests.pas',
  AppCoreAbout in '..\..\src\App.Core\AppCoreAbout.pas',
  AppCoreBuildInfo in '..\..\src\App.Core\AppCoreBuildInfo.pas',
  AppCoreAuth in '..\..\src\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\..\src\App.Core\AppCoreClock.pas',
  AppCoreConfiguration in '..\..\src\App.Core\AppCoreConfiguration.pas',
  AppCoreJsonUtils in '..\..\src\App.Core\AppCoreJsonUtils.pas',
  AppCoreLocalization in '..\..\src\App.Core\AppCoreLocalization.pas',
  AppCorePreferences in '..\..\src\App.Core\AppCorePreferences.pas',
  AppCorePreferencesFileRepository in '..\..\src\App.Core\AppCorePreferencesFileRepository.pas',
  AppCoreRepositoryFactory in '..\..\src\App.Core\AppCoreRepositoryFactory.pas',
  AppCoreTaskFileRepository in '..\..\src\App.Core\AppCoreTaskFileRepository.pas',
  AppCoreTaskItem in '..\..\src\App.Core\AppCoreTaskItem.pas',
  AppCoreTaskRepository in '..\..\src\App.Core\AppCoreTaskRepository.pas',
  AppCoreTaskService in '..\..\src\App.Core\AppCoreTaskService.pas',
  AppCoreUser in '..\..\src\App.Core\AppCoreUser.pas',
  AppCoreUserFileRepository in '..\..\src\App.Core\AppCoreUserFileRepository.pas',
  AppCoreUserRepository in '..\..\src\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\..\src\App.Core\AppCoreUserService.pas';

var
  Failures: Integer;
begin
  Failures := 0;

  try
    RunAboutServiceTests(Failures);
    RunAuthServiceTests(Failures);
    RunUserServiceTests(Failures);
    RunTaskServiceTests(Failures);
    RunConfigurationTests(Failures);
    RunLocalizationTests(Failures);
    RunRepositoryFactoryTests(Failures);
    RunPreferencesFileRepositoryTests(Failures);

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
