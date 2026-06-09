unit AppCoreUserRepository;

interface

uses
  Classes,
  SysUtils,
  AppCoreUser;

type
  IUserRepository = interface
    ['{FD807F90-0B4C-43B6-8ED7-179FD4E94031}']
    function All: TList;
    function FindById(const AId: string): TUser;
    function FindByUsername(const AUsername: string): TUser;
    function FindByEmail(const AEmail: string): TUser;
    procedure Save(AUser: TUser);
  end;

  TInMemoryUserRepository = class(TInterfacedObject, IUserRepository)
  private
    FItems: TList;
    function IndexOfId(const AId: string): Integer;
    function IndexOfUsername(const AUsername: string): Integer;
    function IndexOfEmail(const AEmail: string): Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Add(AUser: TUser);
    function All: TList;
    function FindById(const AId: string): TUser;
    function FindByUsername(const AUsername: string): TUser;
    function FindByEmail(const AEmail: string): TUser;
    procedure Save(AUser: TUser);
  end;

implementation

constructor TInMemoryUserRepository.Create;
begin
  inherited Create;
  FItems := TList.Create;
end;

destructor TInMemoryUserRepository.Destroy;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TObject(FItems[I]).Free;

  FItems.Free;
  inherited Destroy;
end;

procedure TInMemoryUserRepository.Add(AUser: TUser);
begin
  FItems.Add(AUser);
end;

function TInMemoryUserRepository.All: TList;
begin
  Result := FItems;
end;

function TInMemoryUserRepository.FindByEmail(const AEmail: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfEmail(AEmail);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

function TInMemoryUserRepository.FindById(const AId: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

function TInMemoryUserRepository.FindByUsername(const AUsername: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfUsername(AUsername);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

function TInMemoryUserRepository.IndexOfEmail(const AEmail: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if UpperCase(TUser(FItems[I]).Email) = UpperCase(AEmail) then
    begin
      Result := I;
      Exit;
    end;
end;

function TInMemoryUserRepository.IndexOfId(const AId: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if TUser(FItems[I]).Id = AId then
    begin
      Result := I;
      Exit;
    end;
end;

function TInMemoryUserRepository.IndexOfUsername(const AUsername: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if UpperCase(TUser(FItems[I]).Username) = UpperCase(AUsername) then
    begin
      Result := I;
      Exit;
    end;
end;

procedure TInMemoryUserRepository.Save(AUser: TUser);
begin
  if IndexOfId(AUser.Id) < 0 then
    Add(AUser);
  { Existing in-memory users are stored by reference, so no copy is required. }
end;

end.
