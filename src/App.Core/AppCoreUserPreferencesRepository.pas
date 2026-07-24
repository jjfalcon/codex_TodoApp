unit AppCoreUserPreferencesRepository;

interface

uses
  AppCoreCrud,
  AppCoreUser,
  AppCoreUserRepository;

type
  TUserGridLayoutRepository = class(TInterfacedObject, ICrudGridLayoutRepository)
  private
    FUsers: IUserRepository;
    FUserId: string;
    function CurrentUser: TUser;
  public
    constructor Create(const AUsers: IUserRepository; const AUserId: string);
    function ReadGridValue(const AGridKey, AName: string): string;
    procedure WriteGridValue(const AGridKey, AName, AValue: string);
  end;

implementation

uses
  AppCoreIniText;

constructor TUserGridLayoutRepository.Create(const AUsers: IUserRepository;
  const AUserId: string);
begin
  inherited Create;
  FUsers := AUsers;
  FUserId := AUserId;
end;

function TUserGridLayoutRepository.CurrentUser: TUser;
begin
  Result := nil;
  if FUsers <> nil then
    Result := FUsers.FindById(FUserId);
end;

function TUserGridLayoutRepository.ReadGridValue(const AGridKey,
  AName: string): string;
var
  LUser: TUser;
begin
  Result := '';
  LUser := CurrentUser;
  if LUser <> nil then
    Result := IniTextReadValue(LUser.PreferencesText, 'Grid.' + AGridKey, AName);
end;

procedure TUserGridLayoutRepository.WriteGridValue(const AGridKey, AName,
  AValue: string);
var
  LUser: TUser;
begin
  LUser := CurrentUser;
  if LUser = nil then
    Exit;
  LUser.PreferencesText := IniTextWriteValue(LUser.PreferencesText,
    'Grid.' + AGridKey, AName, AValue);
  FUsers.Save(LUser);
end;

end.
