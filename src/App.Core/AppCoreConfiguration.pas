unit AppCoreConfiguration;

interface

uses
  SysUtils,
  IniFiles;

type
  TAppConfiguration = class
  private
    FBackend: string;
    FDataPath: string;
    FConnectionString: string;
    FLanguage: string;
    FLanguageFile: string;
    FUpdatesEnabled: Boolean;
    FUpdateManifestUrl: string;
    FUpdateDownloadDir: string;
  public
    constructor Create(const AFileName: string);
    property Backend: string read FBackend;
    property DataPath: string read FDataPath;
    property ConnectionString: string read FConnectionString;
    property Language: string read FLanguage;
    property LanguageFile: string read FLanguageFile;
    property UpdatesEnabled: Boolean read FUpdatesEnabled;
    property UpdateManifestUrl: string read FUpdateManifestUrl;
    property UpdateDownloadDir: string read FUpdateDownloadDir;
  end;

implementation

function ReadBooleanText(const AValue: string; ADefault: Boolean): Boolean;
var
  LValue: string;
begin
  LValue := LowerCase(Trim(AValue));
  if LValue = '' then
  begin
    Result := ADefault;
    Exit;
  end;

  Result := (LValue = 'true') or (LValue = '1') or (LValue = 'yes') or (LValue = 'si') or (LValue = 'sí');
end;

constructor TAppConfiguration.Create(const AFileName: string);
var
  LIni: TIniFile;
  LFileName: string;
begin
  inherited Create;
  FBackend := 'json';
  FDataPath := '.';
  FConnectionString := '';
  FLanguage := 'es';
  FLanguageFile := 'languages.csv';
  FUpdatesEnabled := False;
  FUpdateManifestUrl := '';
  FUpdateDownloadDir := 'updates';

  LFileName := ExpandFileName(AFileName);
  if not FileExists(LFileName) then
    Exit;

  LIni := TIniFile.Create(LFileName);
  try
    FBackend := LowerCase(LIni.ReadString('Persistence', 'Backend', 'json'));
    FDataPath := LIni.ReadString('Persistence', 'DataPath', '.');
    FConnectionString := LIni.ReadString('Persistence', 'ConnectionString', '');
    FLanguage := LowerCase(LIni.ReadString('Localization', 'Language', 'es'));
    FLanguageFile := LIni.ReadString('Localization', 'File', 'languages.csv');
    FUpdatesEnabled := ReadBooleanText(LIni.ReadString('Updates', 'Enabled', ''), False);
    FUpdateManifestUrl := LIni.ReadString('Updates', 'ManifestUrl', '');
    FUpdateDownloadDir := LIni.ReadString('Updates', 'DownloadDir', 'updates');
  finally
    LIni.Free;
  end;
end;

end.
