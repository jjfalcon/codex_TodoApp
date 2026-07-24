unit AppWinCsv;

interface

uses
  Classes,
  SysUtils;

function CsvEscape(const AValue: string): string;
function CsvTextFromRows(AHeaders: TStrings; ARows: TList): string;

implementation

function CsvEscape(const AValue: string): string;
begin
  Result := StringReplace(AValue, '"', '""', [rfReplaceAll]);
  if (Pos(';', Result) > 0) or (Pos('"', AValue) > 0) or
    (Pos(#13, Result) > 0) or (Pos(#10, Result) > 0) then
    Result := '"' + Result + '"';
end;

function CsvTextFromRows(AHeaders: TStrings; ARows: TList): string;
var
  LLines: TStringList;
  LRow: TStrings;
  LLine: string;
  I: Integer;
  J: Integer;
begin
  LLines := TStringList.Create;
  try
    LLine := '';
    for I := 0 to AHeaders.Count - 1 do
    begin
      if I > 0 then
        LLine := LLine + ';';
      LLine := LLine + CsvEscape(AHeaders[I]);
    end;
    LLines.Add(LLine);

    for I := 0 to ARows.Count - 1 do
    begin
      LRow := TStrings(ARows[I]);
      LLine := '';
      for J := 0 to AHeaders.Count - 1 do
      begin
        if J > 0 then
          LLine := LLine + ';';
        if J < LRow.Count then
          LLine := LLine + CsvEscape(LRow[J]);
      end;
      LLines.Add(LLine);
    end;
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

end.
