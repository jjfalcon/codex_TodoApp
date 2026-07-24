unit AppCoreUpdateTests;

interface

procedure RunUpdateTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCoreUpdate;

type
  TFakeManifestClient = class(TInterfacedObject, IUpdateManifestClient)
  public
    Manifest: TUpdateInfo;
    RaisesError: Boolean;
    function FetchLatest: TUpdateInfo;
  end;

  TFakeDownloader = class(TInterfacedObject, IUpdateDownloader)
  public
    DownloadedUrl: string;
    DownloadedFileName: string;
    function Download(const AUrl, ATargetDirectory: string): string;
  end;

  TFakeHashCalculator = class(TInterfacedObject, IHashCalculator)
  public
    Hash: string;
    function Sha256File(const AFileName: string): string;
  end;

  TFakeApplier = class(TInterfacedObject, IUpdateApplier)
  public
    AppliedPackageFileName: string;
    procedure ApplyPackage(const APackageFileName: string);
  end;

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

procedure AssertFalse(AValue: Boolean; const AMessage: string);
begin
  if AValue then
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

function TFakeManifestClient.FetchLatest: TUpdateInfo;
begin
  if RaisesError then
    raise EUpdateError.Create('Manifest invalid');
  Result := Manifest;
end;

function TFakeDownloader.Download(const AUrl, ATargetDirectory: string): string;
begin
  DownloadedUrl := AUrl;
  DownloadedFileName := IncludeTrailingPathDelimiter(ATargetDirectory) + 'package.zip';
  Result := DownloadedFileName;
end;

function TFakeHashCalculator.Sha256File(const AFileName: string): string;
begin
  Result := Hash;
end;

procedure TFakeApplier.ApplyPackage(const APackageFileName: string);
begin
  AppliedPackageFileName := APackageFileName;
end;

procedure SameVersionDoesNotOfferUpdate;
var
  LClient: TFakeManifestClient;
  LDownloader: TFakeDownloader;
  LHash: TFakeHashCalculator;
  LService: TUpdateService;
  LResult: TUpdateCheckResult;
begin
  LClient := TFakeManifestClient.Create;
  LDownloader := TFakeDownloader.Create;
  LHash := TFakeHashCalculator.Create;
  LClient.Manifest.Version := '1.0.0.53';
  LClient.Manifest.PackageUrl := 'https://example.test/TodoApp.zip';
  LClient.Manifest.Sha256 := 'abc';

  LService := TUpdateService.Create(LClient, LDownloader, LHash, '1.0.0.53', 'updates');
  try
    LResult := LService.CheckAndDownload;
    AssertFalse(LResult.Available, 'Same version should not be offered.');
    AssertEquals('', LDownloader.DownloadedUrl, 'Downloader should not be called.');
  finally
    LService.Free;
  end;
end;

procedure LowerVersionDoesNotOfferUpdate;
var
  LClient: TFakeManifestClient;
  LDownloader: TFakeDownloader;
  LHash: TFakeHashCalculator;
  LService: TUpdateService;
  LResult: TUpdateCheckResult;
begin
  LClient := TFakeManifestClient.Create;
  LDownloader := TFakeDownloader.Create;
  LHash := TFakeHashCalculator.Create;
  LClient.Manifest.Version := '1.0.0.52';
  LClient.Manifest.PackageUrl := 'https://example.test/TodoApp.zip';
  LClient.Manifest.Sha256 := 'abc';

  LService := TUpdateService.Create(LClient, LDownloader, LHash, '1.0.0.53', 'updates');
  try
    LResult := LService.CheckAndDownload;
    AssertFalse(LResult.Available, 'Older version should not be offered.');
  finally
    LService.Free;
  end;
end;

procedure HigherVersionDownloadsAndValidatesHash;
var
  LClient: TFakeManifestClient;
  LDownloader: TFakeDownloader;
  LHash: TFakeHashCalculator;
  LService: TUpdateService;
  LResult: TUpdateCheckResult;
begin
  LClient := TFakeManifestClient.Create;
  LDownloader := TFakeDownloader.Create;
  LHash := TFakeHashCalculator.Create;
  LClient.Manifest.Version := '1.0.0.54';
  LClient.Manifest.PackageUrl := 'https://example.test/TodoApp.zip';
  LClient.Manifest.Sha256 := 'ABC';
  LHash.Hash := 'abc';

  LService := TUpdateService.Create(LClient, LDownloader, LHash, '1.0.0.53', 'updates');
  try
    LResult := LService.CheckAndDownload;
    AssertTrue(LResult.Available, 'Higher version should be available.');
    AssertTrue(LResult.Verified, 'Matching hash should verify the package.');
    AssertEquals('https://example.test/TodoApp.zip', LDownloader.DownloadedUrl, 'Downloader should receive package URL.');
    AssertEquals('updates\package.zip', LResult.PackageFileName, 'Result should expose downloaded package path.');
  finally
    LService.Free;
  end;
end;

procedure HashMismatchRejectsPackage;
var
  LClient: TFakeManifestClient;
  LDownloader: TFakeDownloader;
  LHash: TFakeHashCalculator;
  LService: TUpdateService;
begin
  LClient := TFakeManifestClient.Create;
  LDownloader := TFakeDownloader.Create;
  LHash := TFakeHashCalculator.Create;
  LClient.Manifest.Version := '1.0.0.54';
  LClient.Manifest.PackageUrl := 'https://example.test/TodoApp.zip';
  LClient.Manifest.Sha256 := 'expected';
  LHash.Hash := 'actual';

  LService := TUpdateService.Create(LClient, LDownloader, LHash, '1.0.0.53', 'updates');
  try
    try
      LService.CheckAndDownload;
      raise Exception.Create('Expected hash mismatch.');
    except
      on E: EUpdateHashError do
        AssertEquals('Downloaded package hash does not match latest manifest.', E.Message, 'Should reject hash mismatch.');
    end;
  finally
    LService.Free;
  end;
end;

procedure InvalidManifestFailsClearly;
var
  LClient: TFakeManifestClient;
  LDownloader: TFakeDownloader;
  LHash: TFakeHashCalculator;
  LService: TUpdateService;
begin
  LClient := TFakeManifestClient.Create;
  LDownloader := TFakeDownloader.Create;
  LHash := TFakeHashCalculator.Create;
  LClient.RaisesError := True;

  LService := TUpdateService.Create(LClient, LDownloader, LHash, '1.0.0.53', 'updates');
  try
    try
      LService.CheckAndDownload;
      raise Exception.Create('Expected manifest error.');
    except
      on E: EUpdateError do
        AssertEquals('Manifest invalid', E.Message, 'Manifest errors should surface clearly.');
    end;
  finally
    LService.Free;
  end;
end;

procedure HigherVersionAppliesOnlyAfterHashVerification;
var
  LClient: TFakeManifestClient;
  LDownloader: TFakeDownloader;
  LHash: TFakeHashCalculator;
  LApplier: TFakeApplier;
  LService: TUpdateService;
  LResult: TUpdateCheckResult;
begin
  LClient := TFakeManifestClient.Create;
  LDownloader := TFakeDownloader.Create;
  LHash := TFakeHashCalculator.Create;
  LApplier := TFakeApplier.Create;
  LClient.Manifest.Version := '1.0.0.54';
  LClient.Manifest.PackageUrl := 'https://example.test/TodoApp.zip';
  LClient.Manifest.Sha256 := 'abc';
  LHash.Hash := 'abc';

  LService := TUpdateService.CreateWithApplier(LClient, LDownloader, LHash,
    LApplier, '1.0.0.53', 'updates');
  try
    LResult := LService.CheckDownloadAndApply;
    AssertTrue(LResult.Applied, 'Verified package should be marked as applied.');
    AssertEquals('updates\package.zip', LApplier.AppliedPackageFileName,
      'Applier should receive the verified package.');
  finally
    LService.Free;
  end;
end;

procedure SameVersionDoesNotApply;
var
  LClient: TFakeManifestClient;
  LDownloader: TFakeDownloader;
  LHash: TFakeHashCalculator;
  LApplier: TFakeApplier;
  LService: TUpdateService;
  LResult: TUpdateCheckResult;
begin
  LClient := TFakeManifestClient.Create;
  LDownloader := TFakeDownloader.Create;
  LHash := TFakeHashCalculator.Create;
  LApplier := TFakeApplier.Create;
  LClient.Manifest.Version := '1.0.0.53';
  LClient.Manifest.PackageUrl := 'https://example.test/TodoApp.zip';
  LClient.Manifest.Sha256 := 'abc';

  LService := TUpdateService.CreateWithApplier(LClient, LDownloader, LHash,
    LApplier, '1.0.0.53', 'updates');
  try
    LResult := LService.CheckDownloadAndApply;
    AssertFalse(LResult.Applied, 'Same version should not apply anything.');
    AssertEquals('', LApplier.AppliedPackageFileName,
      'Applier should not be called when there is no update.');
  finally
    LService.Free;
  end;
end;

procedure RunUpdateTests(var AFailures: Integer);
begin
  RunTest('Update_same_version_does_not_offer_update', SameVersionDoesNotOfferUpdate, AFailures);
  RunTest('Update_lower_version_does_not_offer_update', LowerVersionDoesNotOfferUpdate, AFailures);
  RunTest('Update_higher_version_downloads_and_validates_hash', HigherVersionDownloadsAndValidatesHash, AFailures);
  RunTest('Update_hash_mismatch_rejects_package', HashMismatchRejectsPackage, AFailures);
  RunTest('Update_invalid_manifest_fails_clearly', InvalidManifestFailsClearly, AFailures);
  RunTest('Update_higher_version_applies_only_after_hash_verification', HigherVersionAppliesOnlyAfterHashVerification, AFailures);
  RunTest('Update_same_version_does_not_apply', SameVersionDoesNotApply, AFailures);
end;

end.
