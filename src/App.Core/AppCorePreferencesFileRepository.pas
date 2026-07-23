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
    FActiveLanguage: string;
    FLastMainOption: string;
    procedure LoadFromFile;
    procedure SaveToFile;
    procedure SaveValue(const ASection, AKey, AValue: string);
  public
    constructor Create(const AFileName: string);
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
    function ActiveLanguage: string;
    procedure SetActiveLanguage(const ALanguage: string);
    function LastMainOption: string;
    procedure SetLastMainOption(const AOption: string);
  end;

implementation

constructor TFileLoginPreferencesRepository.Create(const AFileName: string);
begin
  inherited Create;
  FFileName := AFileName;
  FLastUsername := '';
  FActiveLanguage := '';
  FLastMainOption := '';
  LoadFromFile;
end;

function TFileLoginPreferencesRepository.ActiveLanguage: string;
begin
  Result := FActiveLanguage;
end;

function TFileLoginPreferencesRepository.LastUsername: string;
begin
  Result := FLastUsername;
end;

function TFileLoginPreferencesRepository.LastMainOption: string;
begin
  Result := FLastMainOption;
end;

procedure TFileLoginPreferencesRepository.LoadFromFile;
var
  LFile: TStringList;
  I: Integer;
  LLine, LKey, LValue, LSection: string;
  LSeparator: Integer;
begin
  if not FileExists(FFileName) then
    Exit;

  LFile := TStringList.Create;
  try
    LFile.LoadFromFile(FFileName);
    LSection := '';
    for I := 0 to LFile.Count - 1 do
    begin
      LLine := Trim(LFile[I]);
      if LLine = '' then
        Continue;
      if (LLine[1] = '[') and (LLine[Length(LLine)] = ']') then
      begin
        LSection := Copy(LLine, 2, Length(LLine) - 2);
        Continue;
      end;
      LSeparator := Pos('=', LLine);
      if LSeparator > 0 then
      begin
        LKey := Copy(LLine, 1, LSeparator - 1);
        LValue := Copy(LLine, LSeparator + 1, MaxInt);
        if (LSection = 'Login') and (LKey = 'LastUsername') then
          FLastUsername := LValue;
        if (LSection = 'Localization') and (LKey = 'Language') then
          FActiveLanguage := LValue;
        if (LSection = 'Main') and (LKey = 'LastOption') then
          FLastMainOption := LValue;
      end;
    end;
  finally
    LFile.Free;
  end;
end;

procedure TFileLoginPreferencesRepository.SaveToFile;
begin
  SaveValue('Login', 'LastUsername', FLastUsername);
end;

procedure TFileLoginPreferencesRepository.SaveValue(const ASection, AKey, AValue: string);
var
  LFile: TStringList;
  LFound, LInSection: Boolean;
  I, LInsertIndex: Integer;
  LLine: string;
begin
  LFile := TStringList.Create;
  try
    if FileExists(FFileName) then
      LFile.LoadFromFile(FFileName);

    LFound := False;
    LInSection := False;
    LInsertIndex := -1;
    for I := 0 to LFile.Count - 1 do
    begin
      LLine := Trim(LFile[I]);
      if LLine = '[' + ASection + ']' then
      begin
        LInSection := True;
        LInsertIndex := I + 1;
        Continue;
      end;
      if LInSection and (Length(LLine) > 0) and (LLine[1] = '[') then
      begin
        LInsertIndex := I;
        Break;
      end;
      if LInSection and (Pos(AKey + '=', LLine) = 1) then
      begin
        LFile[I] := AKey + '=' + AValue;
        LFound := True;
        Break;
      end;
    end;

    if not LFound then
    begin
      if not LInSection then
        LFile.Add('[' + ASection + ']');
      if LInsertIndex >= 0 then
        LFile.Insert(LInsertIndex, AKey + '=' + AValue)
      else
        LFile.Add(AKey + '=' + AValue);
    end;

    LFile.SaveToFile(FFileName);
  finally
    LFile.Free;
  end;
end;

procedure TFileLoginPreferencesRepository.SetActiveLanguage(const ALanguage: string);
begin
  FActiveLanguage := ALanguage;
  SaveValue('Localization', 'Language', FActiveLanguage);
end;

procedure TFileLoginPreferencesRepository.SetLastUsername(const AUsername: string);
begin
  FLastUsername := AUsername;
  SaveToFile;
end;

procedure TFileLoginPreferencesRepository.SetLastMainOption(const AOption: string);
begin
  FLastMainOption := AOption;
  SaveValue('Main', 'LastOption', FLastMainOption);
end;

end.
