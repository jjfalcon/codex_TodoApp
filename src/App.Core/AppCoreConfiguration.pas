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
  public
    constructor Create(const AFileName: string);
    property Backend: string read FBackend;
    property DataPath: string read FDataPath;
    property ConnectionString: string read FConnectionString;
  end;

implementation

constructor TAppConfiguration.Create(const AFileName: string);
var
  LIni: TIniFile;
begin
  inherited Create;
  FBackend := 'json';
  FDataPath := '.';
  FConnectionString := '';

  if not FileExists(AFileName) then
    Exit;

  LIni := TIniFile.Create(AFileName);
  try
    FBackend := LowerCase(LIni.ReadString('Persistence', 'Backend', 'json'));
    FDataPath := LIni.ReadString('Persistence', 'DataPath', '.');
    FConnectionString := LIni.ReadString('Persistence', 'ConnectionString', '');
  finally
    LIni.Free;
  end;
end;

end.
