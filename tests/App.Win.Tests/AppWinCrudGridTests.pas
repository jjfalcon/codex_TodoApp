unit AppWinCrudGridTests;

interface

procedure RunAppWinCrudGridTests(var AFailures: Integer);

implementation

uses
  SysUtils,
  AppWinCrudGrid;

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

procedure CrudColumnTitleBuildsPlainTitle;
begin
  AssertEquals('Email', CrudColumnTitle('Email', False, False, True),
    'Plain title should keep base caption.');
end;

procedure CrudColumnTitleAddsFilterIndicator;
begin
  AssertEquals('* Email', CrudColumnTitle('Email', True, False, True),
    'Filtered title should include filter indicator.');
end;

procedure CrudColumnTitleAddsAscendingSortIndicator;
begin
  AssertEquals('^ Email', CrudColumnTitle('Email', False, True, True),
    'Ascending title should include ascending sort indicator.');
end;

procedure CrudColumnTitleAddsDescendingSortIndicator;
begin
  AssertEquals('v * Email', CrudColumnTitle('Email', True, True, False),
    'Descending sorted and filtered title should include both indicators.');
end;

procedure CrudCellMatchesSearchMatchesCaseInsensitively;
begin
  if not CrudCellMatchesSearch(' First value ', 'first') then
    raise Exception.Create('Search should match case-insensitively.');
end;

procedure CrudCellMatchesSearchIgnoresBlankSearch;
begin
  if CrudCellMatchesSearch('First value', '   ') then
    raise Exception.Create('Blank search should not match cells.');
end;

procedure RunAppWinCrudGridTests(var AFailures: Integer);
begin
  RunTest('AppWinCrudGrid_plain_title', CrudColumnTitleBuildsPlainTitle, AFailures);
  RunTest('AppWinCrudGrid_filter_indicator', CrudColumnTitleAddsFilterIndicator, AFailures);
  RunTest('AppWinCrudGrid_ascending_sort_indicator', CrudColumnTitleAddsAscendingSortIndicator, AFailures);
  RunTest('AppWinCrudGrid_descending_sort_and_filter_indicators', CrudColumnTitleAddsDescendingSortIndicator, AFailures);
  RunTest('AppWinCrudGrid_search_matches_case_insensitively', CrudCellMatchesSearchMatchesCaseInsensitively, AFailures);
  RunTest('AppWinCrudGrid_search_ignores_blank_search', CrudCellMatchesSearchIgnoresBlankSearch, AFailures);
end;

end.
