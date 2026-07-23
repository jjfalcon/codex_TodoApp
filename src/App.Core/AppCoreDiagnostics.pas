unit AppCoreDiagnostics;

interface

uses
  SysUtils;

type
  IDiagnosticsLogger = interface
    ['{0D41D22B-43B0-4E3B-A6F1-1E1F3F8C0B91}']
    procedure Info(const AEvent, AMessage: string);
    procedure Warning(const AEvent, AMessage: string);
    procedure Error(const AEvent, AMessage: string);
    procedure Timing(const AEvent, AMessage: string; ADurationMs: Integer);
  end;

  TFileDiagnosticsLogger = class(TInterfacedObject, IDiagnosticsLogger)
  private
    FFileName: string;
    function Sanitize(const AValue: string): string;
    function Timestamp: string;
    procedure WriteLine(const ALevel, AEvent, AMessage: string;
      ADurationMs: Integer; AHasDuration: Boolean);
  public
    constructor Create(const AFileName: string);
    procedure Info(const AEvent, AMessage: string);
    procedure Warning(const AEvent, AMessage: string);
    procedure Error(const AEvent, AMessage: string);
    procedure Timing(const AEvent, AMessage: string; ADurationMs: Integer);
  end;

  TDiagnosticTimer = class
  private
    FStartedAt: LongWord;
  public
    procedure Start;
    function ElapsedMs: Integer;
  end;

implementation

uses
  Windows;

function PosFromInsensitive(const ASearch, AText: string; AOffset: Integer): Integer;
var
  LPos: Integer;
begin
  LPos := Pos(LowerCase(ASearch), LowerCase(Copy(AText, AOffset, MaxInt)));
  if LPos = 0 then
    Result := 0
  else
    Result := AOffset + LPos - 1;
end;

function RedactKeyValueInsensitive(const AText, AKey: string): string;
var
  LPos: Integer;
  LEndPos: Integer;
  LOffset: Integer;
begin
  Result := AText;
  LOffset := 1;
  LPos := PosFromInsensitive(AKey, Result, LOffset);
  while LPos > 0 do
  begin
    LEndPos := LPos + Length(AKey);
    while (LEndPos <= Length(Result)) and not (Result[LEndPos] in [' ', ';', ',']) do
      Inc(LEndPos);
    Delete(Result, LPos, LEndPos - LPos);
    Insert(AKey + '[redacted]', Result, LPos);
    LOffset := LPos + Length(AKey) + Length('[redacted]');
    LPos := PosFromInsensitive(AKey, Result, LOffset);
  end;
end;

constructor TFileDiagnosticsLogger.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
end;

procedure TFileDiagnosticsLogger.Error(const AEvent, AMessage: string);
begin
  WriteLine('ERROR', AEvent, AMessage, 0, False);
end;

procedure TFileDiagnosticsLogger.Info(const AEvent, AMessage: string);
begin
  WriteLine('INFO', AEvent, AMessage, 0, False);
end;

function TFileDiagnosticsLogger.Sanitize(const AValue: string): string;
begin
  Result := AValue;
  Result := RedactKeyValueInsensitive(Result, 'password=');
  Result := RedactKeyValueInsensitive(Result, 'pwd=');
  Result := RedactKeyValueInsensitive(Result, 'token=');
  Result := RedactKeyValueInsensitive(Result, 'secret=');
  Result := RedactKeyValueInsensitive(Result, 'connectionstring=');
end;

procedure TFileDiagnosticsLogger.Timing(const AEvent, AMessage: string;
  ADurationMs: Integer);
begin
  WriteLine('TIMING', AEvent, AMessage, ADurationMs, True);
end;

function TFileDiagnosticsLogger.Timestamp: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now);
end;

procedure TFileDiagnosticsLogger.Warning(const AEvent, AMessage: string);
begin
  WriteLine('WARNING', AEvent, AMessage, 0, False);
end;

procedure TFileDiagnosticsLogger.WriteLine(const ALevel, AEvent,
  AMessage: string; ADurationMs: Integer; AHasDuration: Boolean);
var
  LFile: TextFile;
  LDir: string;
  LLine: string;
begin
  LDir := ExtractFilePath(FFileName);
  if (LDir <> '') and (not DirectoryExists(LDir)) then
    ForceDirectories(LDir);

  LLine := Timestamp + ' ' + ALevel + ' ' + Sanitize(AEvent);
  if AHasDuration then
    LLine := LLine + ' durationMs=' + IntToStr(ADurationMs);
  if AMessage <> '' then
    LLine := LLine + ' ' + Sanitize(AMessage);

  AssignFile(LFile, FFileName);
  if FileExists(FFileName) then
    Append(LFile)
  else
    Rewrite(LFile);
  try
    Writeln(LFile, LLine);
  finally
    CloseFile(LFile);
  end;
end;

function TDiagnosticTimer.ElapsedMs: Integer;
begin
  Result := Integer(GetTickCount - FStartedAt);
end;

procedure TDiagnosticTimer.Start;
begin
  FStartedAt := GetTickCount;
end;

end.
