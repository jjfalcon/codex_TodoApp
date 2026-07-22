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
  public
    constructor Create(const AFileName: string);
    property Backend: string read FBackend;
    property DataPath: string read FDataPath;
    property ConnectionString: string read FConnectionString;
    property Language: string read FLanguage;
    property LanguageFile: string read FLanguageFile;
  end;

implementation

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
  finally
    LIni.Free;
  end;
end;

end.
