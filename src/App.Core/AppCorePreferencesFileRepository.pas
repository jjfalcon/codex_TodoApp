unit AppCorePreferencesFileRepository;

interface

uses
  SysUtils,
  Classes,
  AppCorePreferences;

type
  TFileLoginPreferencesRepository = class(TInterfacedObject, ILoginPreferencesRepository)
  private
    FFileName: string;
    FLastUsername: string;
    procedure LoadFromFile;
    procedure SaveToFile;
  public
    constructor Create(const AFileName: string);
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
  end;

implementation

constructor TFileLoginPreferencesRepository.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FLastUsername := '';
  LoadFromFile;
end;

function TFileLoginPreferencesRepository.LastUsername: string;
begin
  Result := FLastUsername;
end;

procedure TFileLoginPreferencesRepository.LoadFromFile;
var
  LFile: TStringList;
  I: Integer;
  LKey, LValue: string;
  LInSection: Boolean;
begin
  if not FileExists(FFileName) then
    Exit;

  LFile := TStringList.Create;
  try
    LFile.LoadFromFile(FFileName);
    LInSection := False;
    for I := 0 to LFile.Count - 1 do
    begin
      if Trim(LFile[I]) = '[Login]' then
      begin
        LInSection := True;
        Continue;
      end;
      if LInSection then
      begin
        LKey := Trim(LFile[I]);
        if Pos('LastUsername=', LKey) = 1 then
        begin
          LValue := Copy(LKey, 14, MaxInt);
          FLastUsername := LValue;
          Exit;
        end;
      end;
    end;
  finally
    LFile.Free;
  end;
end;

procedure TFileLoginPreferencesRepository.SaveToFile;
var
  LFile: TStringList;
  LFound: Boolean;
  I: Integer;
  LKey: string;
begin
  LFile := TStringList.Create;
  try
    if FileExists(FFileName) then
      LFile.LoadFromFile(FFileName);

    LFound := False;
    for I := 0 to LFile.Count - 1 do
    begin
      LKey := Trim(LFile[I]);
      if Pos('LastUsername=', LKey) = 1 then
      begin
        LFile[I] := 'LastUsername=' + FLastUsername;
        LFound := True;
        Break;
      end;
    end;

    if not LFound then
    begin
      LFile.Add('[Login]');
      LFile.Add('LastUsername=' + FLastUsername);
    end;

    LFile.SaveToFile(FFileName);
  finally
    LFile.Free;
  end;
end;

procedure TFileLoginPreferencesRepository.SetLastUsername(const AUsername: string);
begin
  FLastUsername := AUsername;
  SaveToFile;
end;

end.
