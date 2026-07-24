unit AppCoreUpdate;

interface

uses
  SysUtils;

type
  EUpdateError = class(Exception);
  EUpdateHashError = class(EUpdateError);

  TUpdateInfo = record
    Version: string;
    Commit: string;
    PackageUrl: string;
    Sha256: string;
    CreatedAt: string;
  end;

  TUpdateCheckResult = record
    Available: Boolean;
    Verified: Boolean;
    Latest: TUpdateInfo;
    PackageFileName: string;
  end;

  IUpdateManifestClient = interface
    ['{853845DE-F7CB-4664-A5EB-B098179C9B45}']
    function FetchLatest: TUpdateInfo;
  end;

  IUpdateDownloader = interface
    ['{DC9AB9F1-2E74-44E7-9052-43848E5A30E9}']
    function Download(const AUrl, ATargetDirectory: string): string;
  end;

  IHashCalculator = interface
    ['{69623BC2-4FE9-4BB7-A98C-8ED3845D2D3B}']
    function Sha256File(const AFileName: string): string;
  end;

  TUpdateService = class
  private
    FManifestClient: IUpdateManifestClient;
    FDownloader: IUpdateDownloader;
    FHashCalculator: IHashCalculator;
    FCurrentVersion: string;
    FDownloadDirectory: string;
    function IsNewerVersion(const ALatestVersion: string): Boolean;
    procedure ValidateManifest(const AInfo: TUpdateInfo);
  public
    constructor Create(const AManifestClient: IUpdateManifestClient;
      const ADownloader: IUpdateDownloader; const AHashCalculator: IHashCalculator;
      const ACurrentVersion, ADownloadDirectory: string);
    function CheckAndDownload: TUpdateCheckResult;
  end;

implementation

function VersionPart(const AVersion: string; AIndex: Integer): Integer;
var
  LText: string;
  LCurrent: Integer;
  LPart: string;
  I: Integer;
begin
  Result := 0;
  LText := AVersion + '.';
  LCurrent := 0;
  LPart := '';

  for I := 1 to Length(LText) do
  begin
    if LText[I] = '.' then
    begin
      if LCurrent = AIndex then
      begin
        Result := StrToIntDef(LPart, 0);
        Exit;
      end;
      Inc(LCurrent);
      LPart := '';
    end
    else
      LPart := LPart + LText[I];
  end;
end;

function SameTextValue(const ALeft, ARight: string): Boolean;
begin
  Result := AnsiCompareText(Trim(ALeft), Trim(ARight)) = 0;
end;

constructor TUpdateService.Create(const AManifestClient: IUpdateManifestClient;
  const ADownloader: IUpdateDownloader; const AHashCalculator: IHashCalculator;
  const ACurrentVersion, ADownloadDirectory: string);
begin
  inherited Create;
  FManifestClient := AManifestClient;
  FDownloader := ADownloader;
  FHashCalculator := AHashCalculator;
  FCurrentVersion := Trim(ACurrentVersion);
  FDownloadDirectory := ADownloadDirectory;
end;

function TUpdateService.IsNewerVersion(const ALatestVersion: string): Boolean;
var
  I: Integer;
  LLatestPart: Integer;
  LCurrentPart: Integer;
begin
  Result := False;
  for I := 0 to 3 do
  begin
    LLatestPart := VersionPart(ALatestVersion, I);
    LCurrentPart := VersionPart(FCurrentVersion, I);
    if LLatestPart > LCurrentPart then
    begin
      Result := True;
      Exit;
    end;
    if LLatestPart < LCurrentPart then
      Exit;
  end;
end;

procedure TUpdateService.ValidateManifest(const AInfo: TUpdateInfo);
begin
  if Trim(AInfo.Version) = '' then
    raise EUpdateError.Create('Update manifest does not include version.');
  if Trim(AInfo.PackageUrl) = '' then
    raise EUpdateError.Create('Update manifest does not include package URL.');
  if Trim(AInfo.Sha256) = '' then
    raise EUpdateError.Create('Update manifest does not include SHA-256.');
end;

function TUpdateService.CheckAndDownload: TUpdateCheckResult;
var
  LActualHash: string;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Latest := FManifestClient.FetchLatest;
  ValidateManifest(Result.Latest);

  if not IsNewerVersion(Result.Latest.Version) then
    Exit;

  Result.Available := True;
  Result.PackageFileName := FDownloader.Download(Result.Latest.PackageUrl, FDownloadDirectory);
  LActualHash := FHashCalculator.Sha256File(Result.PackageFileName);
  if not SameTextValue(Result.Latest.Sha256, LActualHash) then
    raise EUpdateHashError.Create('Downloaded package hash does not match latest manifest.');

  Result.Verified := True;
end;

end.
