unit AppCorePreferencesFileRepositoryTests;

interface

procedure RunPreferencesFileRepositoryTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppCorePreferences,
  AppCorePreferencesFileRepository;

procedure AssertEquals(const AExpected, AActual: string; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
end;

procedure RunTest(const AName: string; AProc: TProcedure; var AFailures: Integer);
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

const
  LTestPrefsFile = 'test_preferences.dat';

procedure NewRepositoryReturnsEmpty;
var
  LRepo: TFileLoginPreferencesRepository;
begin
  DeleteFile(LTestPrefsFile);
  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    AssertEquals('', LRepo.LastUsername, 'New repo should return empty string.');
    AssertEquals('', LRepo.ActiveLanguage, 'New repo should return empty language.');
    AssertEquals('', LRepo.LastMainOption, 'New repo should return empty main option.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure PersistsActiveLanguage;
var
  LRepo: TFileLoginPreferencesRepository;
begin
  DeleteFile(LTestPrefsFile);
  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetActiveLanguage('en');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    AssertEquals('en', LRepo.ActiveLanguage, 'Language should persist after reload.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure PersistsLastMainOption;
var
  LRepo: TFileLoginPreferencesRepository;
begin
  DeleteFile(LTestPrefsFile);
  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetLastMainOption('Tareas');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    AssertEquals('Tareas', LRepo.LastMainOption, 'Last main option should persist after reload.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure SetAndGetInMemory;
var
  LRepo: TFileLoginPreferencesRepository;
begin
  DeleteFile(LTestPrefsFile);
  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetLastUsername('admin');
    AssertEquals('admin', LRepo.LastUsername, 'Should return set username.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure PersistsAcrossSessions;
var
  LRepo: TFileLoginPreferencesRepository;
begin
  DeleteFile(LTestPrefsFile);
  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetLastUsername('jjfalcon');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    AssertEquals('jjfalcon', LRepo.LastUsername, 'Username should persist after reload.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure OverwritesPreviousUsername;
var
  LRepo: TFileLoginPreferencesRepository;
begin
  DeleteFile(LTestPrefsFile);
  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetLastUsername('admin');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetLastUsername('user');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    AssertEquals('user', LRepo.LastUsername, 'Should return last written username.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure SavesPreferencesWithoutDroppingExistingValues;
var
  LRepo: TFileLoginPreferencesRepository;
begin
  DeleteFile(LTestPrefsFile);
  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetLastUsername('admin');
    LRepo.SetActiveLanguage('en');
    LRepo.SetLastMainOption('Usuarios');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetActiveLanguage('es');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    AssertEquals('admin', LRepo.LastUsername, 'Updating language should keep username.');
    AssertEquals('es', LRepo.ActiveLanguage, 'Language should update.');
    AssertEquals('Usuarios', LRepo.LastMainOption, 'Updating language should keep last main option.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure AddsMissingKeyInsideExistingSection;
var
  LRepo: TFileLoginPreferencesRepository;
  LFile: TStringList;
begin
  DeleteFile(LTestPrefsFile);
  LFile := TStringList.Create;
  try
    LFile.Add('[Localization]');
    LFile.Add('File=languages.csv');
    LFile.Add('[Login]');
    LFile.Add('LastUsername=admin');
    LFile.SaveToFile(LTestPrefsFile);
  finally
    LFile.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    LRepo.SetActiveLanguage('en');
  finally
    LRepo.Free;
  end;

  LRepo := TFileLoginPreferencesRepository.Create(LTestPrefsFile);
  try
    AssertEquals('en', LRepo.ActiveLanguage, 'Missing language key should be saved inside Localization section.');
    AssertEquals('admin', LRepo.LastUsername, 'Existing login preference should remain readable.');
  finally
    LRepo.Free;
  end;
  DeleteFile(LTestPrefsFile);
end;

procedure RunPreferencesFileRepositoryTests(var AFailures: Integer);
begin
  RunTest('NewRepository_returns_empty', NewRepositoryReturnsEmpty, AFailures);
  RunTest('SetAndGet_in_memory', SetAndGetInMemory, AFailures);
  RunTest('Persists_across_sessions', PersistsAcrossSessions, AFailures);
  RunTest('Persists_active_language', PersistsActiveLanguage, AFailures);
  RunTest('Persists_last_main_option', PersistsLastMainOption, AFailures);
  RunTest('Overwrites_previous_username', OverwritesPreviousUsername, AFailures);
  RunTest('Saves_preferences_without_dropping_existing_values', SavesPreferencesWithoutDroppingExistingValues, AFailures);
  RunTest('Adds_missing_key_inside_existing_section', AddsMissingKeyInsideExistingSection, AFailures);
end;

end.
