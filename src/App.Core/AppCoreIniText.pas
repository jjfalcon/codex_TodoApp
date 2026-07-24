unit AppCoreIniText;

interface

function IniTextReadValue(const AText, ASection, AKey: string): string;
function IniTextWriteValue(const AText, ASection, AKey, AValue: string): string;

implementation

uses
  Classes,
  SysUtils;

function IsSectionLine(const ALine: string): Boolean;
var
  LLine: string;
begin
  LLine := Trim(ALine);
  Result := (Length(LLine) >= 2) and (LLine[1] = '[') and
    (LLine[Length(LLine)] = ']');
end;

function SectionName(const ALine: string): string;
var
  LLine: string;
begin
  LLine := Trim(ALine);
  Result := Copy(LLine, 2, Length(LLine) - 2);
end;

function IniTextReadValue(const AText, ASection, AKey: string): string;
var
  LLines: TStringList;
  I, LSeparator: Integer;
  LSection: string;
  LLine: string;
begin
  Result := '';
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    LSection := '';
    for I := 0 to LLines.Count - 1 do
    begin
      LLine := Trim(LLines[I]);
      if LLine = '' then
        Continue;
      if IsSectionLine(LLine) then
      begin
        LSection := SectionName(LLine);
        Continue;
      end;
      LSeparator := Pos('=', LLine);
      if (LSection = ASection) and (LSeparator > 0) and
        (Copy(LLine, 1, LSeparator - 1) = AKey) then
      begin
        Result := Copy(LLine, LSeparator + 1, MaxInt);
        Exit;
      end;
    end;
  finally
    LLines.Free;
  end;
end;

function IniTextWriteValue(const AText, ASection, AKey, AValue: string): string;
var
  LLines: TStringList;
  I, LInsertIndex: Integer;
  LLine: string;
  LInSection, LFound: Boolean;
begin
  LLines := TStringList.Create;
  try
    LLines.Text := AText;
    LInSection := False;
    LFound := False;
    LInsertIndex := -1;
    for I := 0 to LLines.Count - 1 do
    begin
      LLine := Trim(LLines[I]);
      if IsSectionLine(LLine) then
      begin
        if LInSection then
        begin
          LInsertIndex := I;
          Break;
        end;
        LInSection := SectionName(LLine) = ASection;
        if LInSection then
          LInsertIndex := I + 1;
        Continue;
      end;
      if LInSection and (Pos(AKey + '=', LLine) = 1) then
      begin
        LLines[I] := AKey + '=' + AValue;
        LFound := True;
        Break;
      end;
    end;

    if not LFound then
    begin
      if not LInSection then
      begin
        if (LLines.Count > 0) and (Trim(LLines[LLines.Count - 1]) <> '') then
          LLines.Add('');
        LLines.Add('[' + ASection + ']');
        LInsertIndex := LLines.Count;
      end;
      if LInsertIndex >= 0 then
        LLines.Insert(LInsertIndex, AKey + '=' + AValue)
      else
        LLines.Add(AKey + '=' + AValue);
    end;

    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

end.
