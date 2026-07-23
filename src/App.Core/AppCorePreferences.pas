unit AppCorePreferences;

interface

uses
  SysUtils;

type
  EPreferencesValidationError = class(Exception);

  TUserPreferences = record
    LastUsername: string;
    ActiveLanguage: string;
    LastMainOption: string;
  end;

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

  TPreferencesService = class
  private
    FRepository: ILoginPreferencesRepository;
    procedure ValidateLanguage(const ALanguage: string);
    procedure ValidateMainOption(const AOption: string);
  public
    constructor Create(const ARepository: ILoginPreferencesRepository);
    function GetPreferences: TUserPreferences;
    procedure SavePreferences(const ALanguage, ALastMainOption: string);
  end;

implementation

constructor TPreferencesService.Create(const ARepository: ILoginPreferencesRepository);
begin
  inherited Create;
  FRepository := ARepository;
end;

function TPreferencesService.GetPreferences: TUserPreferences;
begin
  Result.LastUsername := FRepository.LastUsername;
  Result.ActiveLanguage := FRepository.ActiveLanguage;
  Result.LastMainOption := FRepository.LastMainOption;
end;

procedure TPreferencesService.SavePreferences(const ALanguage,
  ALastMainOption: string);
begin
  ValidateLanguage(ALanguage);
  ValidateMainOption(ALastMainOption);
  FRepository.SetActiveLanguage(LowerCase(ALanguage));
  FRepository.SetLastMainOption(ALastMainOption);
end;

procedure TPreferencesService.ValidateLanguage(const ALanguage: string);
var
  LLanguage: string;
begin
  LLanguage := LowerCase(ALanguage);
  if (LLanguage <> 'es') and (LLanguage <> 'en') then
    raise EPreferencesValidationError.Create('Idioma no valido.');
end;

procedure TPreferencesService.ValidateMainOption(const AOption: string);
begin
  if (AOption <> 'Dashboard') and (AOption <> 'Tasks') and (AOption <> 'Users') then
    raise EPreferencesValidationError.Create('Opcion principal no valida.');
end;

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
