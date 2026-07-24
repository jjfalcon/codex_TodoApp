unit AppCorePreferences;

interface

uses
  SysUtils,
  Classes,
  AppCoreIniText,
  AppCoreUser,
  AppCoreUserRepository;

type
  EPreferencesValidationError = class(Exception);

  TPreferencesView = record
    LastUsername: string;
    ActiveLanguage: string;
    LastMainOption: string;
  end;

  IAppPreferencesRepository = interface
    ['{77BA670A-9CF3-4B57-94B2-6F78D9B7A0F9}']
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
  end;

  ILoginPreferencesRepository = IAppPreferencesRepository;

  TInMemoryLoginPreferencesRepository = class(TInterfacedObject,
    IAppPreferencesRepository)
  private
    FLastUsername: string;
  public
    constructor Create;
    function LastUsername: string;
    procedure SetLastUsername(const AUsername: string);
  end;

  TPreferencesService = class
  private
    FAppPreferences: IAppPreferencesRepository;
    FUsers: IUserRepository;
    FUserId: string;
    function CurrentUser: TUser;
    procedure ValidateLanguage(const ALanguage: string);
    procedure ValidateMainOption(const AOption: string);
  public
    constructor Create(const AAppPreferences: IAppPreferencesRepository;
      const AUsers: IUserRepository; const AUserId: string);
    function GetPreferences: TPreferencesView;
    procedure SavePreferences(const ALanguage, ALastMainOption: string);
  end;

implementation

constructor TPreferencesService.Create(
  const AAppPreferences: IAppPreferencesRepository; const AUsers: IUserRepository;
  const AUserId: string);
begin
  inherited Create;
  FAppPreferences := AAppPreferences;
  FUsers := AUsers;
  FUserId := AUserId;
end;

function TPreferencesService.CurrentUser: TUser;
begin
  Result := nil;
  if FUsers <> nil then
    Result := FUsers.FindById(FUserId);
end;

function TPreferencesService.GetPreferences: TPreferencesView;
var
  LUser: TUser;
begin
  Result.LastUsername := '';
  Result.ActiveLanguage := '';
  Result.LastMainOption := '';

  if FAppPreferences <> nil then
    Result.LastUsername := FAppPreferences.LastUsername;

  LUser := CurrentUser;
  if LUser <> nil then
  begin
    Result.ActiveLanguage := IniTextReadValue(LUser.PreferencesText, 'User',
      'ActiveLanguage');
    Result.LastMainOption := IniTextReadValue(LUser.PreferencesText, 'User',
      'LastMainOption');
  end;
end;

procedure TPreferencesService.SavePreferences(const ALanguage,
  ALastMainOption: string);
var
  LUser: TUser;
begin
  ValidateLanguage(ALanguage);
  ValidateMainOption(ALastMainOption);

  LUser := CurrentUser;
  if LUser = nil then
    raise EPreferencesValidationError.Create('Usuario no encontrado.');

  LUser.PreferencesText := IniTextWriteValue(LUser.PreferencesText, 'User',
    'ActiveLanguage', LowerCase(ALanguage));
  LUser.PreferencesText := IniTextWriteValue(LUser.PreferencesText, 'User',
    'LastMainOption', ALastMainOption);
  FUsers.Save(LUser);
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
  if (AOption <> 'Dashboard') and (AOption <> 'TSK') and (AOption <> 'USR') then
    raise EPreferencesValidationError.Create('Opcion principal no valida.');
end;

constructor TInMemoryLoginPreferencesRepository.Create;
begin
  inherited Create;
end;

function TInMemoryLoginPreferencesRepository.LastUsername: string;
begin
  Result := FLastUsername;
end;

procedure TInMemoryLoginPreferencesRepository.SetLastUsername(
  const AUsername: string);
begin
  FLastUsername := AUsername;
end;

end.
