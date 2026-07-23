unit AppCorePreferences;

interface

type
  ILoginPreferencesRepository = interface
    ['{77BA670A-9CF3-4B57-94B2-6F78D9B7A0F9}']
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
    function ActiveLanguage: string;
    procedure SetActiveLanguage(const ALanguage: string);
    function LastMainOption: string;
    procedure SetLastMainOption(const AOption: string);
  end;

  TInMemoryLoginPreferencesRepository = class(TInterfacedObject, ILoginPreferencesRepository)
  private
    FLastUsername: string;
    FActiveLanguage: string;
    FLastMainOption: string;
  public
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
    function ActiveLanguage: string;
    procedure SetActiveLanguage(const ALanguage: string);
    function LastMainOption: string;
    procedure SetLastMainOption(const AOption: string);
  end;

implementation

function TInMemoryLoginPreferencesRepository.ActiveLanguage: string;
begin
  Result := FActiveLanguage;
end;

function TInMemoryLoginPreferencesRepository.LastUsername: string;
begin
  Result := FLastUsername;
end;

function TInMemoryLoginPreferencesRepository.LastMainOption: string;
begin
  Result := FLastMainOption;
end;

procedure TInMemoryLoginPreferencesRepository.SetActiveLanguage(const ALanguage: string);
begin
  FActiveLanguage := ALanguage;
end;

procedure TInMemoryLoginPreferencesRepository.SetLastUsername(const AUsername: string);
begin
  FLastUsername := AUsername;
end;

procedure TInMemoryLoginPreferencesRepository.SetLastMainOption(const AOption: string);
begin
  FLastMainOption := AOption;
end;

end.
