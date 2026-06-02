unit AppCorePreferences;

interface

type
  ILoginPreferencesRepository = interface
    ['{77BA670A-9CF3-4B57-94B2-6F78D9B7A0F9}']
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
  end;

  TInMemoryLoginPreferencesRepository = class(TInterfacedObject, ILoginPreferencesRepository)
  private
    FLastUsername: string;
  public
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
  end;

implementation

function TInMemoryLoginPreferencesRepository.LastUsername: string;
begin
  Result := FLastUsername;
end;

procedure TInMemoryLoginPreferencesRepository.SetLastUsername(const AUsername: string);
begin
  FLastUsername := AUsername;
end;

end.
