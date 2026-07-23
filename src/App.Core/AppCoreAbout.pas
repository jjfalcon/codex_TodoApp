unit AppCoreAbout;

interface

uses
  SysUtils;

type
  TAboutInfo = record
    ApplicationName: string;
    Version: string;
    Description: string;
    Copyright: string;
    ExecutableVersion: string;
    CommitHash: string;
    OperatingSystem: string;
    Architecture: string;
    BuildDate: string;
    DatabasePath: string;
  end;

  IAboutService = interface
    ['{7E5C321A-8F6B-4D0F-9E1C-3A2B5C8D7E6F}']
    function GetAboutInfo: TAboutInfo;
  end;

  TAboutService = class(TInterfacedObject, IAboutService)
  private
    FInfo: TAboutInfo;
    procedure ProcessInfo;
  public
    constructor Create; overload;
    constructor Create(const AInfo: TAboutInfo); overload;
    function GetAboutInfo: TAboutInfo;
  end;

implementation

uses
  AppCoreBuildInfo;

const
  NotAvailable = 'No disponible';

constructor TAboutService.Create;
begin
  inherited Create;
  FInfo.ApplicationName := 'Delphi TDD App';
  FInfo.Version := AppBuildVersion;
  FInfo.Description := 'Aplicacion Windows desarrollada en Delphi siguiendo principios TDD.';
  FInfo.Copyright := 'Copyright 2026';
  FInfo.ExecutableVersion := AppBuildVersion;
  FInfo.CommitHash := AppBuildCommitHash;
  FInfo.OperatingSystem := 'Windows';
  FInfo.Architecture := NotAvailable;
  FInfo.BuildDate := AppBuildDate;
  FInfo.DatabasePath := NotAvailable;
  ProcessInfo;
end;

constructor TAboutService.Create(const AInfo: TAboutInfo);
begin
  inherited Create;
  FInfo := AInfo;
  ProcessInfo;
end;

procedure TAboutService.ProcessInfo;
const
  SensitiveMarkers: array[0..4] of string = (
    'password=', 'pwd=', 'token=', 'secret=', 'connectionstring='
  );
var
  I: Integer;
  LDbPath: string;
begin
  if FInfo.ApplicationName = '' then FInfo.ApplicationName := NotAvailable;
  if FInfo.Version = '' then FInfo.Version := NotAvailable;
  if FInfo.Description = '' then FInfo.Description := NotAvailable;
  if FInfo.Copyright = '' then FInfo.Copyright := NotAvailable;
  if FInfo.ExecutableVersion = '' then FInfo.ExecutableVersion := NotAvailable;
  if FInfo.CommitHash = '' then FInfo.CommitHash := NotAvailable;
  if FInfo.OperatingSystem = '' then FInfo.OperatingSystem := NotAvailable;
  if FInfo.Architecture = '' then FInfo.Architecture := NotAvailable;
  if FInfo.BuildDate = '' then FInfo.BuildDate := NotAvailable;

  LDbPath := LowerCase(FInfo.DatabasePath);
  for I := Low(SensitiveMarkers) to High(SensitiveMarkers) do
    if Pos(SensitiveMarkers[I], LDbPath) > 0 then
    begin
      FInfo.DatabasePath := NotAvailable;
      Exit;
    end;
  if FInfo.DatabasePath = '' then
    FInfo.DatabasePath := NotAvailable;
end;

function TAboutService.GetAboutInfo: TAboutInfo;
begin
  Result := FInfo;
end;

end.
