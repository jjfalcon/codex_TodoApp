unit AppCoreRepositoryFactory;

interface

uses
  AppCorePreferences,
  AppCoreTaskRepository,
  AppCoreUserRepository;

type
  IRepositoryFactory = interface
    ['{B7E3F21A-4C5D-4E8F-9A1B-2C3D4E5F6A7B}']
    function CreateUserRepository: IUserRepository;
    function CreateTaskRepository: ITaskRepository;
    function CreateLoginPreferencesRepository: ILoginPreferencesRepository;
  end;

  TJsonRepositoryFactory = class(TInterfacedObject, IRepositoryFactory)
  private
    FDataPath: string;
  public
    constructor Create(const ADataPath: string);
    function CreateUserRepository: IUserRepository;
    function CreateTaskRepository: ITaskRepository;
    function CreateLoginPreferencesRepository: ILoginPreferencesRepository;
  end;

implementation

uses
  SysUtils,
  AppCorePreferencesFileRepository,
  AppCoreTaskFileRepository,
  AppCoreUserFileRepository;

constructor TJsonRepositoryFactory.Create(const ADataPath: string);
begin
  inherited Create;
  FDataPath := ADataPath;
  if FDataPath = '' then
    FDataPath := '.';
  if FDataPath[Length(FDataPath)] <> '\' then
    FDataPath := FDataPath + '\';
end;

function TJsonRepositoryFactory.CreateUserRepository: IUserRepository;
begin
  Result := TFileUserRepository.Create(FDataPath + 'users.json');
end;

function TJsonRepositoryFactory.CreateTaskRepository: ITaskRepository;
begin
  Result := TFileTaskRepository.Create(FDataPath + 'tasks.json');
end;

function TJsonRepositoryFactory.CreateLoginPreferencesRepository: ILoginPreferencesRepository;
begin
  Result := TFileLoginPreferencesRepository.Create(FDataPath + 'app.config');
end;

end.
