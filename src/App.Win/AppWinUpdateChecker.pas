unit AppWinUpdateChecker;

interface

uses
  SysUtils,
  AboutForm,
  AppCoreUpdate;

type
  TAboutUpdateChecker = class(TInterfacedObject, IAboutUpdateChecker)
  private
    FConfigFileName: string;
  public
    constructor Create(const AConfigFileName: string);
    function CheckForUpdate: TAboutUpdateCheckResult;
  end;

  TManifestHttpClient = class(TInterfacedObject, IUpdateManifestClient)
  private
    FManifestUrl: string;
    function ResolvePackageUrl(const APackage: string): string;
  public
    constructor Create(const AManifestUrl: string);
    function FetchLatest: TUpdateInfo;
  end;

  TWindowsUpdateDownloader = class(TInterfacedObject, IUpdateDownloader)
  public
    function Download(const AUrl, ATargetDirectory: string): string;
  end;

  TWindowsSha256Calculator = class(TInterfacedObject, IHashCalculator)
  public
    function Sha256File(const AFileName: string): string;
  end;

implementation

uses
  Classes,
  IniFiles,
  Windows,
  AppCoreBuildInfo,
  AppCoreConfiguration,
  AppCoreJsonUtils;

type
  ALG_ID = DWORD;
  HCRYPTKEY = ULONG_PTR;
  HCRYPTHASH = ULONG_PTR;
  HCRYPTPROV = ULONG_PTR;

const
  CALG_SHA_256 = $0000800C;
  CRYPT_VERIFYCONTEXT = $F0000000;
  HP_HASHVAL = $0002;
  PROV_RSA_AES = 24;

function URLDownloadToFile(Caller: IUnknown; URL: PChar; FileName: PChar;
  Reserved: DWORD; StatusCB: Pointer): HResult; stdcall;
  external 'urlmon.dll' name 'URLDownloadToFileA';

function CryptAcquireContext(var phProv: HCRYPTPROV; pszContainer: PChar;
  pszProvider: PChar; dwProvType: DWORD; dwFlags: DWORD): BOOL; stdcall;
  external 'advapi32.dll' name 'CryptAcquireContextA';
function CryptCreateHash(hProv: HCRYPTPROV; Algid: ALG_ID; hKey: HCRYPTKEY;
  dwFlags: DWORD; var phHash: HCRYPTHASH): BOOL; stdcall;
  external 'advapi32.dll';
function CryptHashData(hHash: HCRYPTHASH; pbData: Pointer; dwDataLen: DWORD;
  dwFlags: DWORD): BOOL; stdcall; external 'advapi32.dll';
function CryptGetHashParam(hHash: HCRYPTHASH; dwParam: DWORD; pbData: Pointer;
  var pdwDataLen: DWORD; dwFlags: DWORD): BOOL; stdcall;
  external 'advapi32.dll';
function CryptDestroyHash(hHash: HCRYPTHASH): BOOL; stdcall;
  external 'advapi32.dll';
function CryptReleaseContext(hProv: HCRYPTPROV; dwFlags: DWORD): BOOL; stdcall;
  external 'advapi32.dll';

procedure DownloadFile(const AUrl, AFileName: string);
begin
  if URLDownloadToFile(nil, PChar(AUrl), PChar(AFileName), 0, nil) <> 0 then
    raise EUpdateError.Create('No se pudo descargar: ' + AUrl);
end;

function IsHttpUrl(const AValue: string): Boolean;
begin
  Result := (Copy(LowerCase(AValue), 1, 7) = 'http://') or
    (Copy(LowerCase(AValue), 1, 8) = 'https://');
end;

function LastSlashPos(const AValue: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := Length(AValue) downto 1 do
    if (AValue[I] = '/') or (AValue[I] = '\') then
    begin
      Result := I;
      Exit;
    end;
end;

function FileNameFromPath(const AValue: string): string;
var
  LPos: Integer;
begin
  LPos := LastSlashPos(AValue);
  if LPos = 0 then
    Result := AValue
  else
    Result := Copy(AValue, LPos + 1, MaxInt);
end;

function TempFileName(const APrefix, AExtension: string): string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    APrefix + IntToStr(GetTickCount) + AExtension;
end;

function ConfigHasUpdatesSection(const AFileName: string): Boolean;
var
  LIni: TIniFile;
  LSections: TStringList;
begin
  Result := False;
  if not FileExists(AFileName) then
    Exit;

  LIni := TIniFile.Create(AFileName);
  LSections := TStringList.Create;
  try
    LIni.ReadSections(LSections);
    Result := LSections.IndexOf('Updates') >= 0;
  finally
    LSections.Free;
    LIni.Free;
  end;
end;

function DefaultConfigFileNameFor(const AConfigFileName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(AConfigFileName)) +
    'app.default.config';
end;

function EffectiveUpdateConfigFileName(const AConfigFileName: string): string;
var
  LDefaultConfigFileName: string;
begin
  Result := AConfigFileName;
  if ConfigHasUpdatesSection(Result) then
    Exit;

  LDefaultConfigFileName := DefaultConfigFileNameFor(AConfigFileName);
  if FileExists(LDefaultConfigFileName) then
    Result := LDefaultConfigFileName;
end;

constructor TAboutUpdateChecker.Create(const AConfigFileName: string);
begin
  inherited Create;
  FConfigFileName := AConfigFileName;
end;

function TAboutUpdateChecker.CheckForUpdate: TAboutUpdateCheckResult;
var
  LConfig: TAppConfiguration;
  LService: TUpdateService;
  LCheck: TUpdateCheckResult;
begin
  LConfig := TAppConfiguration.Create(EffectiveUpdateConfigFileName(FConfigFileName));
  try
    if (not LConfig.UpdatesEnabled) or (Trim(LConfig.UpdateManifestUrl) = '') then
    begin
      Result.MessageText := 'Actualizador no configurado.';
      Exit;
    end;

    LService := TUpdateService.Create(
      TManifestHttpClient.Create(LConfig.UpdateManifestUrl),
      TWindowsUpdateDownloader.Create,
      TWindowsSha256Calculator.Create,
      AppBuildVersion,
      LConfig.UpdateDownloadDir);
    try
      LCheck := LService.CheckAndDownload;
      if LCheck.Available and LCheck.Verified then
        Result.MessageText := 'Actualizacion ' + LCheck.Latest.Version + ' descargada y verificada.'
      else
        Result.MessageText := 'No hay actualizaciones. Version actual: ' + AppBuildVersion + '.';
    finally
      LService.Free;
    end;
  finally
    LConfig.Free;
  end;
end;

constructor TManifestHttpClient.Create(const AManifestUrl: string);
begin
  inherited Create;
  FManifestUrl := AManifestUrl;
end;

function TManifestHttpClient.ResolvePackageUrl(const APackage: string): string;
var
  LPos: Integer;
begin
  if IsHttpUrl(APackage) then
  begin
    Result := APackage;
    Exit;
  end;

  LPos := LastSlashPos(FManifestUrl);
  if LPos = 0 then
    Result := APackage
  else
    Result := Copy(FManifestUrl, 1, LPos) + APackage;
end;

function TManifestHttpClient.FetchLatest: TUpdateInfo;
var
  LFileName: string;
  LJson: TStringList;
begin
  LFileName := TempFileName('todoapp-latest-', '.json');
  LJson := TStringList.Create;
  try
    if IsHttpUrl(FManifestUrl) then
      DownloadFile(FManifestUrl, LFileName)
    else
      CopyFile(PChar(FManifestUrl), PChar(LFileName), False);

    LJson.LoadFromFile(LFileName);
    Result.Version := ExtractJsonString(LJson.Text, 'version');
    Result.Commit := ExtractJsonString(LJson.Text, 'commit');
    Result.PackageUrl := ResolvePackageUrl(ExtractJsonString(LJson.Text, 'package'));
    Result.Sha256 := ExtractJsonString(LJson.Text, 'sha256');
    Result.CreatedAt := ExtractJsonString(LJson.Text, 'publishedAt');
  finally
    SysUtils.DeleteFile(LFileName);
    LJson.Free;
  end;
end;

function TWindowsUpdateDownloader.Download(const AUrl,
  ATargetDirectory: string): string;
begin
  if not DirectoryExists(ATargetDirectory) then
    ForceDirectories(ATargetDirectory);

  Result := IncludeTrailingPathDelimiter(ATargetDirectory) + FileNameFromPath(AUrl);
  if IsHttpUrl(AUrl) then
    DownloadFile(AUrl, Result)
  else if not CopyFile(PChar(AUrl), PChar(Result), False) then
    raise EUpdateError.Create('No se pudo copiar: ' + AUrl);
end;

function TWindowsSha256Calculator.Sha256File(const AFileName: string): string;
var
  LProvider: HCRYPTPROV;
  LHash: HCRYPTHASH;
  LStream: TFileStream;
  LBuffer: array[0..8191] of Byte;
  LRead: Integer;
  LDigest: array[0..31] of Byte;
  LDigestLen: DWORD;
  I: Integer;
begin
  Result := '';
  LProvider := 0;
  LHash := 0;

  if not CryptAcquireContext(LProvider, nil, nil, PROV_RSA_AES, CRYPT_VERIFYCONTEXT) then
    raise EUpdateError.Create('No se pudo iniciar SHA-256.');
  try
    if not CryptCreateHash(LProvider, CALG_SHA_256, 0, 0, LHash) then
      raise EUpdateError.Create('No se pudo crear SHA-256.');
    try
      LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
      try
        repeat
          LRead := LStream.Read(LBuffer, SizeOf(LBuffer));
          if (LRead > 0) and not CryptHashData(LHash, @LBuffer[0], LRead, 0) then
            raise EUpdateError.Create('No se pudo calcular SHA-256.');
        until LRead = 0;
      finally
        LStream.Free;
      end;

      LDigestLen := SizeOf(LDigest);
      if not CryptGetHashParam(LHash, HP_HASHVAL, @LDigest[0], LDigestLen, 0) then
        raise EUpdateError.Create('No se pudo leer SHA-256.');

      for I := 0 to LDigestLen - 1 do
        Result := Result + LowerCase(IntToHex(LDigest[I], 2));
    finally
      CryptDestroyHash(LHash);
    end;
  finally
    CryptReleaseContext(LProvider, 0);
  end;
end;

end.
