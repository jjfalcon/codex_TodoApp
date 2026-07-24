unit AppCoreIniTextTests;

interface

procedure RunIniTextTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppCoreIniText;

type
  TTestProc = procedure;

procedure AssertEquals(const AExpected, AActual, AMessage: string);
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure AssertContains(const AText, AFragment, AMessage: string);
begin
  if Pos(AFragment, AText) = 0 then
    raise Exception.Create(AMessage + ' Expected text to contain "' + AFragment + '".');
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

procedure ReadsExistingValue;
begin
  AssertEquals('TSK', IniTextReadValue('[User]'#13#10'LastMainOption=TSK',
    'User', 'LastMainOption'), 'Should read key from section.');
end;

procedure WritesValueWithoutDroppingOtherSections;
var
  LText: string;
begin
  LText := IniTextWriteValue('[User]'#13#10'ActiveLanguage=es'#13#10#13#10+
    '[Grid.TSK]'#13#10'Sort.Field=title'#13#10, 'User', 'LastMainOption', 'USR');
  AssertContains(LText, '[Grid.TSK]', 'Should keep other section.');
  AssertContains(LText, 'Sort.Field=title', 'Should keep other key.');
  AssertEquals('USR', IniTextReadValue(LText, 'User', 'LastMainOption'),
    'Should write new value.');
end;

procedure RunIniTextTests(var AFailures: Integer);
begin
  RunTest('IniText_reads_existing_value', ReadsExistingValue, AFailures);
  RunTest('IniText_writes_value_without_dropping_other_sections', WritesValueWithoutDroppingOtherSections, AFailures);
end;

end.
