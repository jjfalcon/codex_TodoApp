unit AppCoreJsonUtils;

interface

uses
  Classes,
  SysUtils;

function FindFrom(const AText, APattern: string; AStart: Integer): Integer;
function EscapeJson(const AValue: string): string;
function UnescapeJson(const AValue: string): string;
function ExtractJsonString(const AObject, AName: string): string;
function ExtractJsonDate(const AObject, AName: string): TDateTime;
function ExtractJsonBool(const AObject, AName: string): Boolean;
function ExtractJsonInteger(const AObject, AName: string): Integer;
function ExtractJsonObjects(const AJson: string): TStringList;
function DateTimeToJson(const AValue: TDateTime): string;
function NullOrDateTimeToJson(const AValue: TDateTime): string;
function BoolToJson(const AValue: Boolean): string;

implementation

function FindFrom(const AText, APattern: string; AStart: Integer): Integer;
var
  I, J: Integer;
  LMatches: Boolean;
begin
  Result := 0;
  if (APattern = '') or (AStart < 1) then
    Exit;

  for I := AStart to Length(AText) - Length(APattern) + 1 do
  begin
    LMatches := True;
    for J := 1 to Length(APattern) do
      if AText[I + J - 1] <> APattern[J] then
      begin
        LMatches := False;
        Break;
      end;

    if LMatches then
    begin
      Result := I;
      Exit;
    end;
  end;
end;

function EscapeJson(const AValue: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to Length(AValue) do
    case AValue[I] of
      '\': Result := Result + '\\';
      '"': Result := Result + '\"';
      #13: Result := Result + '\r';
      #10: Result := Result + '\n';
    else
      Result := Result + AValue[I];
    end;
end;

function UnescapeJson(const AValue: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(AValue) do
  begin
    if (AValue[I] = '\') and (I < Length(AValue)) then
    begin
      Inc(I);
      case AValue[I] of
        '\': Result := Result + '\';
        '"': Result := Result + '"';
        'r': Result := Result + #13;
        'n': Result := Result + #10;
      else
        Result := Result + AValue[I];
      end;
    end
    else
      Result := Result + AValue[I];

    Inc(I);
  end;
end;

function ExtractJsonString(const AObject, AName: string): string;
var
  LKey: string;
  LPos, I: Integer;
  LEscaped: Boolean;
begin
  Result := '';
  LKey := '"' + AName + '"';
  LPos := FindFrom(AObject, LKey, 1);
  if LPos = 0 then
    Exit;

  LPos := FindFrom(AObject, ':', LPos + Length(LKey));
  if LPos = 0 then
    Exit;

  Inc(LPos);
  while (LPos <= Length(AObject)) and (AObject[LPos] <= ' ') do
    Inc(LPos);

  if (LPos > Length(AObject)) or (AObject[LPos] <> '"') then
    Exit;

  Inc(LPos);
  LEscaped := False;
  for I := LPos to Length(AObject) do
  begin
    if LEscaped then
    begin
      Result := Result + '\' + AObject[I];
      LEscaped := False;
    end
    else if AObject[I] = '\' then
      LEscaped := True
    else if AObject[I] = '"' then
    begin
      Result := UnescapeJson(Result);
      Exit;
    end
    else
      Result := Result + AObject[I];
  end;
end;

function ExtractJsonDate(const AObject, AName: string): TDateTime;
var
  LValue: string;
begin
  LValue := ExtractJsonString(AObject, AName);
  if LValue = '' then
    Result := 0
  else
    Result := EncodeDate(StrToInt(Copy(LValue, 1, 4)),
      StrToInt(Copy(LValue, 6, 2)), StrToInt(Copy(LValue, 9, 2))) +
      EncodeTime(StrToInt(Copy(LValue, 12, 2)), StrToInt(Copy(LValue, 15, 2)),
      StrToInt(Copy(LValue, 18, 2)), 0);
end;

function ExtractJsonBool(const AObject, AName: string): Boolean;
var
  LKey: string;
  LPos: Integer;
  LCh: Char;
begin
  Result := False;
  LKey := '"' + AName + '"';
  LPos := FindFrom(AObject, LKey, 1);
  if LPos = 0 then
    Exit;

  LPos := FindFrom(AObject, ':', LPos + Length(LKey));
  if LPos = 0 then
    Exit;

  Inc(LPos);
  while (LPos <= Length(AObject)) and (AObject[LPos] <= ' ') do
    Inc(LPos);

  if LPos > Length(AObject) then
    Exit;

  LCh := AObject[LPos];
  Result := (LCh = 't') or (LCh = 'T');
end;

function ExtractJsonInteger(const AObject, AName: string): Integer;
var
  LKey: string;
  LPos, I: Integer;
  LSign: Integer;
  LDigit: string;
begin
  Result := 0;
  LKey := '"' + AName + '"';
  LPos := FindFrom(AObject, LKey, 1);
  if LPos = 0 then
    Exit;

  LPos := FindFrom(AObject, ':', LPos + Length(LKey));
  if LPos = 0 then
    Exit;

  Inc(LPos);
  while (LPos <= Length(AObject)) and (AObject[LPos] <= ' ') do
    Inc(LPos);

  LSign := 1;
  if AObject[LPos] = '-' then
  begin
    LSign := -1;
    Inc(LPos);
  end;

  LDigit := '';
  for I := LPos to Length(AObject) do
  begin
    if (AObject[I] >= '0') and (AObject[I] <= '9') then
      LDigit := LDigit + AObject[I]
    else
      Break;
  end;

  if LDigit <> '' then
    Result := LSign * StrToInt(LDigit);
end;

function ExtractJsonObjects(const AJson: string): TStringList;
var
  I: Integer;
  LStart, LDepth: Integer;
  LInString, LEscaped: Boolean;
begin
  Result := TStringList.Create;
  LStart := 0;
  LDepth := 0;
  LInString := False;
  LEscaped := False;

  for I := 1 to Length(AJson) do
  begin
    if LInString then
    begin
      if LEscaped then
        LEscaped := False
      else if AJson[I] = '\' then
        LEscaped := True
      else if AJson[I] = '"' then
        LInString := False;
    end
    else
    begin
      if AJson[I] = '"' then
        LInString := True
      else if AJson[I] = '{' then
      begin
        if LDepth = 0 then
          LStart := I;
        Inc(LDepth);
      end
      else if AJson[I] = '}' then
      begin
        Dec(LDepth);
        if (LDepth = 0) and (LStart > 0) then
          Result.Add(Copy(AJson, LStart, I - LStart + 1));
      end;
    end;
  end;
end;

function DateTimeToJson(const AValue: TDateTime): string;
begin
  Result := '"' + FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', AValue) + '"';
end;

function NullOrDateTimeToJson(const AValue: TDateTime): string;
begin
  if AValue = 0 then
    Result := 'null'
  else
    Result := DateTimeToJson(AValue);
end;

function BoolToJson(const AValue: Boolean): string;
begin
  if AValue then
    Result := 'true'
  else
    Result := 'false';
end;

end.
