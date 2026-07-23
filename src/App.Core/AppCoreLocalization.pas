unit AppCoreLocalization;

interface

uses
  Classes,
  SysUtils;

type
  ILocalizationService = interface
    ['{09F80D24-6396-43AE-8BBA-9E7A5C2A9F2B}']
    function Language: string;
    function HasText(const AKey: string): Boolean;
    function Text(const AKey: string): string;
    procedure AddKeysForForm(const AFormName: string; AKeys: TStrings);
    procedure ChangeLanguage(const ALanguage: string);
  end;

  TCsvLocalizationService = class(TInterfacedObject, ILocalizationService)
  private
    FLanguage: string;
    FFileName: string;
    FDefaultLanguage: string;
    FTexts: TStringList;
    function FindColumn(const AHeaders: TStringList; const AName: string): Integer;
    function ValueAt(const AValues: TStringList; AIndex: Integer): string;
    procedure LoadFromFile(const AFileName, ADefaultLanguage: string);
  public
    constructor Create(const AFileName, ALanguage, ADefaultLanguage: string);
    destructor Destroy; override;
    function Language: string;
    function HasText(const AKey: string): Boolean;
    function Text(const AKey: string): string;
    procedure AddKeysForForm(const AFormName: string; AKeys: TStrings);
    procedure ChangeLanguage(const ALanguage: string);
  end;

procedure ParseCsvLine(const ALine: string; AValues: TStrings);

implementation

procedure ParseCsvLine(const ALine: string; AValues: TStrings);
var
  I: Integer;
  LValue: string;
  LInQuotes: Boolean;
begin
  AValues.Clear;
  LValue := '';
  LInQuotes := False;
  I := 1;
  while I <= Length(ALine) do
  begin
    if ALine[I] = '"' then
    begin
      if LInQuotes and (I < Length(ALine)) and (ALine[I + 1] = '"') then
      begin
        LValue := LValue + '"';
        Inc(I);
      end
      else
        LInQuotes := not LInQuotes;
    end
    else if (ALine[I] = ',') and not LInQuotes then
    begin
      AValues.Add(LValue);
      LValue := '';
    end
    else
      LValue := LValue + ALine[I];
    Inc(I);
  end;
  AValues.Add(LValue);
end;

constructor TCsvLocalizationService.Create(const AFileName, ALanguage,
  ADefaultLanguage: string);
begin
  inherited Create;
  FFileName := AFileName;
  FDefaultLanguage := LowerCase(ADefaultLanguage);
  FLanguage := LowerCase(ALanguage);
  if FLanguage = '' then
    FLanguage := FDefaultLanguage;
  FTexts := TStringList.Create;
  LoadFromFile(FFileName, FDefaultLanguage);
end;

procedure TCsvLocalizationService.ChangeLanguage(const ALanguage: string);
begin
  FLanguage := LowerCase(ALanguage);
  if FLanguage = '' then
    FLanguage := FDefaultLanguage;
  FTexts.Clear;
  LoadFromFile(FFileName, FDefaultLanguage);
end;

destructor TCsvLocalizationService.Destroy;
begin
  FTexts.Free;
  inherited Destroy;
end;

function TCsvLocalizationService.FindColumn(const AHeaders: TStringList;
  const AName: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to AHeaders.Count - 1 do
    if LowerCase(AHeaders[I]) = LowerCase(AName) then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TCsvLocalizationService.LoadFromFile(const AFileName,
  ADefaultLanguage: string);
var
  LLines: TStringList;
  LHeaders: TStringList;
  LValues: TStringList;
  LKeyColumn: Integer;
  LLanguageColumn: Integer;
  LDefaultColumn: Integer;
  I: Integer;
  LKey: string;
  LText: string;
begin
  if not FileExists(AFileName) then
    Exit;

  LLines := TStringList.Create;
  LHeaders := TStringList.Create;
  LValues := TStringList.Create;
  try
    LLines.LoadFromFile(AFileName);
    if LLines.Count = 0 then
      Exit;

    ParseCsvLine(LLines[0], LHeaders);
    LKeyColumn := FindColumn(LHeaders, 'key');
    if LKeyColumn < 0 then
      raise Exception.Create('Localization CSV must contain key column.');

    LLanguageColumn := FindColumn(LHeaders, FLanguage);
    LDefaultColumn := FindColumn(LHeaders, ADefaultLanguage);
    if (LLanguageColumn < 0) and (LDefaultColumn < 0) then
      raise Exception.Create('Localization CSV must contain language column "' + FLanguage + '".');

    for I := 1 to LLines.Count - 1 do
    begin
      ParseCsvLine(LLines[I], LValues);
      LKey := ValueAt(LValues, LKeyColumn);
      if LKey = '' then
        Continue;

      LText := ValueAt(LValues, LLanguageColumn);
      if (LText = '') and (LDefaultColumn >= 0) then
        LText := ValueAt(LValues, LDefaultColumn);

      FTexts.Values[LKey] := LText;
    end;
  finally
    LValues.Free;
    LHeaders.Free;
    LLines.Free;
  end;
end;

function TCsvLocalizationService.ValueAt(const AValues: TStringList;
  AIndex: Integer): string;
begin
  if (AIndex >= 0) and (AIndex < AValues.Count) then
    Result := AValues[AIndex]
  else
    Result := '';
end;

function TCsvLocalizationService.Language: string;
begin
  Result := FLanguage;
end;

function TCsvLocalizationService.HasText(const AKey: string): Boolean;
begin
  Result := FTexts.IndexOfName(AKey) >= 0;
end;

function TCsvLocalizationService.Text(const AKey: string): string;
begin
  Result := FTexts.Values[AKey];
end;

procedure TCsvLocalizationService.AddKeysForForm(const AFormName: string;
  AKeys: TStrings);
var
  I: Integer;
  LPrefix: string;
  LKey: string;
begin
  LPrefix := AFormName + '.';
  for I := 0 to FTexts.Count - 1 do
  begin
    LKey := FTexts.Names[I];
    if Copy(LKey, 1, Length(LPrefix)) = LPrefix then
      AKeys.Add(LKey);
  end;
end;

end.
