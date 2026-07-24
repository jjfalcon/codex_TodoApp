unit AppWinCsvTests;

interface

procedure RunAppWinCsvTests(var AFailures: Integer);

implementation

uses
  Classes,
  SysUtils,
  AppWinCsv;

type
  TTestProc = procedure;

procedure AssertEquals(const AExpected, AActual, AMessage: string);
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure RunTest(const AName: string; AProc: TTestProc; var AFailures: Integer);
begin
  try
    AProc;
    Writeln('[OK] ', AName);
  except
    on E: Exception do
    begin
      Inc(AFailures);
      Writeln('[FAIL] ', AName, ': ', E.Message);
    end;
  end;
end;

procedure CsvTextUsesSemicolonAndEscapesValues;
var
  LHeaders: TStringList;
  LRows: TList;
  LRow: TStringList;
  I: Integer;
begin
  LHeaders := TStringList.Create;
  LRows := TList.Create;
  try
    LHeaders.Add('Name');
    LHeaders.Add('Notes');

    LRow := TStringList.Create;
    LRow.Add('First');
    LRow.Add('A;B');
    LRows.Add(LRow);

    LRow := TStringList.Create;
    LRow.Add('Second');
    LRow.Add('Line "one"'#13#10'Line two');
    LRows.Add(LRow);

    AssertEquals('Name;Notes' + sLineBreak +
      'First;"A;B"' + sLineBreak +
      'Second;"Line ""one""' + sLineBreak +
      'Line two"' + sLineBreak,
      CsvTextFromRows(LHeaders, LRows), 'CSV should use semicolon and escape special values.');
  finally
    for I := 0 to LRows.Count - 1 do
      TObject(LRows[I]).Free;
    LRows.Free;
    LHeaders.Free;
  end;
end;

procedure RunAppWinCsvTests(var AFailures: Integer);
begin
  RunTest('AppWinCsv_text_uses_semicolon_and_escapes_values',
    CsvTextUsesSemicolonAndEscapesValues, AFailures);
end;

end.
