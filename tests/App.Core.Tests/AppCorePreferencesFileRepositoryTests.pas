unit AppCorePreferencesFileRepositoryTests;

interface

procedure RunPreferencesFileRepositoryTests(var AFailures: Integer);

implementation

uses
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

procedure RunPreferencesFileRepositoryTests(var AFailures: Integer);
begin
  RunTest('NewRepository_returns_empty', NewRepositoryReturnsEmpty, AFailures);
  RunTest('SetAndGet_in_memory', SetAndGetInMemory, AFailures);
  RunTest('Persists_across_sessions', PersistsAcrossSessions, AFailures);
  RunTest('Overwrites_previous_username', OverwritesPreviousUsername, AFailures);
end;

end.
