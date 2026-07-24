unit AppWinCrudGrid;

interface

function CrudColumnTitle(const ABaseCaption: string; AFiltered, ASorted,
  AAscending: Boolean): string;
function CrudCellMatchesSearch(const AValue, ASearchText: string): Boolean;

implementation

uses
  SysUtils;

function CrudColumnTitle(const ABaseCaption: string; AFiltered, ASorted,
  AAscending: Boolean): string;
begin
  Result := ABaseCaption;
  if AFiltered then
    Result := '* ' + Result;
  if ASorted then
    if AAscending then
      Result := '^ ' + Result
    else
      Result := 'v ' + Result;
end;

function CrudCellMatchesSearch(const AValue, ASearchText: string): Boolean;
begin
  Result := (Trim(ASearchText) <> '') and
    (Pos(UpperCase(Trim(ASearchText)), UpperCase(AValue)) > 0);
end;

end.
