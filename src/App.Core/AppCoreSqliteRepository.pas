unit AppCoreSqliteRepository;

interface

uses
  Classes,
  SysUtils,
  AppCoreTaskItem,
  AppCoreTaskRepository,
  AppCoreUser,
  AppCoreUserRepository;

type
  ESqliteRepositoryError = class(Exception);

  TSqliteTaskRepository = class(TInterfacedObject, ITaskRepository)
  private
    FDatabaseFileName: string;
    FItems: TList;
    procedure EnsureSchema;
    procedure FreeItems;
    function IndexOfId(const AId: string): Integer;
    procedure LoadFromDatabase;
    procedure UpsertTask(ATask: TTaskItem);
  public
    constructor Create(const ADatabaseFileName: string);
    destructor Destroy; override;
    procedure Add(ATask: TTaskItem);
    procedure Delete(const AId: string);
    function FindById(const AId: string): TTaskItem;
    function ListAll: TTaskItemArray;
    procedure Save(ATask: TTaskItem);
  end;

  TSqliteUserRepository = class(TInterfacedObject, IUserRepository)
  private
    FDatabaseFileName: string;
    FItems: TList;
    procedure EnsureSchema;
    procedure FreeItems;
    function IndexOfId(const AId: string): Integer;
    function IndexOfUsername(const AUsername: string): Integer;
    function IndexOfEmail(const AEmail: string): Integer;
    procedure LoadFromDatabase;
    function RoleToText(ARole: TUserRole): string;
    function TextToRole(const AValue: string): TUserRole;
    procedure UpsertUser(AUser: TUser);
  public
    constructor Create(const ADatabaseFileName: string);
    destructor Destroy; override;
    function All: TList;
    function FindById(const AId: string): TUser;
    function FindByUsername(const AUsername: string): TUser;
    function FindByEmail(const AEmail: string): TUser;
    procedure Save(AUser: TUser);
  end;

implementation

type
  sqlite3 = Pointer;
  sqlite3_stmt = Pointer;

const
  SQLITE_OK = 0;
  SQLITE_ROW = 100;
  SQLITE_DONE = 101;
  SQLITE_TRANSIENT = Pointer(-1);

function sqlite3_open(filename: PChar; var db: sqlite3): Integer; cdecl;
  external 'sqlite3.dll';
function sqlite3_close(db: sqlite3): Integer; cdecl;
  external 'sqlite3.dll';
function sqlite3_exec(db: sqlite3; sql: PChar; callback: Pointer;
  arg: Pointer; var errmsg: PChar): Integer; cdecl; external 'sqlite3.dll';
function sqlite3_errmsg(db: sqlite3): PChar; cdecl; external 'sqlite3.dll';
function sqlite3_prepare_v2(db: sqlite3; sql: PChar; nByte: Integer;
  var stmt: sqlite3_stmt; tail: Pointer): Integer; cdecl; external 'sqlite3.dll';
function sqlite3_step(stmt: sqlite3_stmt): Integer; cdecl; external 'sqlite3.dll';
function sqlite3_finalize(stmt: sqlite3_stmt): Integer; cdecl; external 'sqlite3.dll';
function sqlite3_bind_text(stmt: sqlite3_stmt; idx: Integer; value: PChar;
  n: Integer; xDestroy: Pointer): Integer; cdecl; external 'sqlite3.dll';
function sqlite3_bind_double(stmt: sqlite3_stmt; idx: Integer; value: Double): Integer; cdecl;
  external 'sqlite3.dll';
function sqlite3_bind_int(stmt: sqlite3_stmt; idx: Integer; value: Integer): Integer; cdecl;
  external 'sqlite3.dll';
function sqlite3_column_text(stmt: sqlite3_stmt; col: Integer): PChar; cdecl;
  external 'sqlite3.dll';
function sqlite3_column_double(stmt: sqlite3_stmt; col: Integer): Double; cdecl;
  external 'sqlite3.dll';
function sqlite3_column_int(stmt: sqlite3_stmt; col: Integer): Integer; cdecl;
  external 'sqlite3.dll';

procedure EnsureDatabaseDirectory(const ADatabaseFileName: string);
var
  LDir: string;
begin
  LDir := ExtractFilePath(ADatabaseFileName);
  if (LDir <> '') and (not DirectoryExists(LDir)) then
    ForceDirectories(LDir);
end;

procedure CheckSqlite(ACode: Integer; ADb: sqlite3; const AOperation: string);
begin
  if ACode <> SQLITE_OK then
    raise ESqliteRepositoryError.Create(AOperation + ': ' + sqlite3_errmsg(ADb));
end;

procedure OpenDatabase(const ADatabaseFileName: string; var ADb: sqlite3);
begin
  EnsureDatabaseDirectory(ADatabaseFileName);
  if sqlite3_open(PChar(ADatabaseFileName), ADb) <> SQLITE_OK then
    raise ESqliteRepositoryError.Create('No se pudo abrir SQLite.');
end;

procedure ExecSql(const ADatabaseFileName, ASql: string);
var
  LDb: sqlite3;
  LError: PChar;
  LCode: Integer;
begin
  LDb := nil;
  LError := nil;
  OpenDatabase(ADatabaseFileName, LDb);
  try
    LCode := sqlite3_exec(LDb, PChar(ASql), nil, nil, LError);
    if LCode <> SQLITE_OK then
      raise ESqliteRepositoryError.Create(sqlite3_errmsg(LDb));
  finally
    sqlite3_close(LDb);
  end;
end;

function ColumnText(AStmt: sqlite3_stmt; AColumn: Integer): string;
var
  LText: PChar;
begin
  LText := sqlite3_column_text(AStmt, AColumn);
  if LText = nil then
    Result := ''
  else
    Result := string(LText);
end;

procedure BindText(AStmt: sqlite3_stmt; AIndex: Integer; const AValue: string);
begin
  sqlite3_bind_text(AStmt, AIndex, PChar(AValue), Length(AValue), SQLITE_TRANSIENT);
end;

function BoolToInt(AValue: Boolean): Integer;
begin
  if AValue then
    Result := 1
  else
    Result := 0;
end;

constructor TSqliteTaskRepository.Create(const ADatabaseFileName: string);
begin
  inherited Create;
  FDatabaseFileName := ADatabaseFileName;
  FItems := TList.Create;
  EnsureSchema;
  LoadFromDatabase;
end;

destructor TSqliteTaskRepository.Destroy;
begin
  FreeItems;
  FItems.Free;
  inherited Destroy;
end;

procedure TSqliteTaskRepository.EnsureSchema;
begin
  ExecSql(FDatabaseFileName,
    'create table if not exists tasks (' +
    'id text primary key, title text not null, created_at real not null, ' +
    'completed_at real not null, status text not null)');
end;

procedure TSqliteTaskRepository.Add(ATask: TTaskItem);
begin
  FItems.Add(ATask);
  UpsertTask(ATask);
end;

procedure TSqliteTaskRepository.Delete(const AId: string);
var
  LDb: sqlite3;
  LStmt: sqlite3_stmt;
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex >= 0 then
  begin
    TObject(FItems[LIndex]).Free;
    FItems.Delete(LIndex);
  end;

  LDb := nil;
  OpenDatabase(FDatabaseFileName, LDb);
  try
    CheckSqlite(sqlite3_prepare_v2(LDb, 'delete from tasks where id = ?', -1,
      LStmt, nil), LDb, 'Preparar delete tasks');
    try
      BindText(LStmt, 1, AId);
      if sqlite3_step(LStmt) <> SQLITE_DONE then
        raise ESqliteRepositoryError.Create('No se pudo borrar tarea.');
    finally
      sqlite3_finalize(LStmt);
    end;
  finally
    sqlite3_close(LDb);
  end;
end;

function TSqliteTaskRepository.FindById(const AId: string): TTaskItem;
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex < 0 then
    Result := nil
  else
    Result := TTaskItem(FItems[LIndex]);
end;

procedure TSqliteTaskRepository.FreeItems;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TObject(FItems[I]).Free;
  FItems.Clear;
end;

function TSqliteTaskRepository.IndexOfId(const AId: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to FItems.Count - 1 do
    if TTaskItem(FItems[I]).Id = AId then
    begin
      Result := I;
      Exit;
    end;
end;

function TSqliteTaskRepository.ListAll: TTaskItemArray;
var
  I: Integer;
begin
  SetLength(Result, FItems.Count);
  for I := 0 to FItems.Count - 1 do
    Result[I] := TTaskItem(FItems[I]);
end;

procedure TSqliteTaskRepository.LoadFromDatabase;
var
  LDb: sqlite3;
  LStmt: sqlite3_stmt;
  LTask: TTaskItem;
begin
  LDb := nil;
  OpenDatabase(FDatabaseFileName, LDb);
  try
    CheckSqlite(sqlite3_prepare_v2(LDb,
      'select id, title, created_at, completed_at, status from tasks order by rowid',
      -1, LStmt, nil), LDb, 'Preparar select tasks');
    try
      while sqlite3_step(LStmt) = SQLITE_ROW do
      begin
        LTask := TTaskItem.Create(ColumnText(LStmt, 0), ColumnText(LStmt, 1),
          sqlite3_column_double(LStmt, 2));
        LTask.CompletedAt := sqlite3_column_double(LStmt, 3);
        if ColumnText(LStmt, 4) = 'completed' then
          LTask.Status := tsCompleted
        else
          LTask.Status := tsPending;
        FItems.Add(LTask);
      end;
    finally
      sqlite3_finalize(LStmt);
    end;
  finally
    sqlite3_close(LDb);
  end;
end;

procedure TSqliteTaskRepository.Save(ATask: TTaskItem);
begin
  UpsertTask(ATask);
end;

procedure TSqliteTaskRepository.UpsertTask(ATask: TTaskItem);
var
  LDb: sqlite3;
  LStmt: sqlite3_stmt;
  LStatus: string;
begin
  if ATask.Status = tsCompleted then
    LStatus := 'completed'
  else
    LStatus := 'pending';

  LDb := nil;
  OpenDatabase(FDatabaseFileName, LDb);
  try
    CheckSqlite(sqlite3_prepare_v2(LDb,
      'insert or replace into tasks (id, title, created_at, completed_at, status) values (?, ?, ?, ?, ?)',
      -1, LStmt, nil), LDb, 'Preparar upsert tasks');
    try
      BindText(LStmt, 1, ATask.Id);
      BindText(LStmt, 2, ATask.Title);
      sqlite3_bind_double(LStmt, 3, ATask.CreatedAt);
      sqlite3_bind_double(LStmt, 4, ATask.CompletedAt);
      BindText(LStmt, 5, LStatus);
      if sqlite3_step(LStmt) <> SQLITE_DONE then
        raise ESqliteRepositoryError.Create('No se pudo guardar tarea.');
    finally
      sqlite3_finalize(LStmt);
    end;
  finally
    sqlite3_close(LDb);
  end;
end;

constructor TSqliteUserRepository.Create(const ADatabaseFileName: string);
begin
  inherited Create;
  FDatabaseFileName := ADatabaseFileName;
  FItems := TList.Create;
  EnsureSchema;
  LoadFromDatabase;
end;

destructor TSqliteUserRepository.Destroy;
begin
  FreeItems;
  FItems.Free;
  inherited Destroy;
end;

function TSqliteUserRepository.All: TList;
begin
  Result := FItems;
end;

procedure TSqliteUserRepository.EnsureSchema;
begin
  ExecSql(FDatabaseFileName,
    'create table if not exists users (' +
    'id text primary key, username text not null, display_name text not null, ' +
    'email text not null, password_hash text not null, salt text not null, ' +
    'active integer not null, deleted integer not null, role text not null, ' +
    'failed_attempts integer not null, locked integer not null, ' +
    'created_at real not null, last_login_at real not null, preferences_text text not null)');
end;

function TSqliteUserRepository.FindByEmail(const AEmail: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfEmail(AEmail);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

function TSqliteUserRepository.FindById(const AId: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AId);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

function TSqliteUserRepository.FindByUsername(const AUsername: string): TUser;
var
  LIndex: Integer;
begin
  LIndex := IndexOfUsername(AUsername);
  if LIndex < 0 then
    Result := nil
  else
    Result := TUser(FItems[LIndex]);
end;

procedure TSqliteUserRepository.FreeItems;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    TObject(FItems[I]).Free;
  FItems.Clear;
end;

function TSqliteUserRepository.IndexOfEmail(const AEmail: string): Integer;
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

function TSqliteUserRepository.IndexOfId(const AId: string): Integer;
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

function TSqliteUserRepository.IndexOfUsername(const AUsername: string): Integer;
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

procedure TSqliteUserRepository.LoadFromDatabase;
var
  LDb: sqlite3;
  LStmt: sqlite3_stmt;
  LUser: TUser;
begin
  LDb := nil;
  OpenDatabase(FDatabaseFileName, LDb);
  try
    CheckSqlite(sqlite3_prepare_v2(LDb,
      'select id, username, display_name, email, password_hash, salt, active, deleted, role, failed_attempts, locked, created_at, last_login_at, preferences_text from users order by rowid',
      -1, LStmt, nil), LDb, 'Preparar select users');
    try
      while sqlite3_step(LStmt) = SQLITE_ROW do
      begin
        LUser := TUser.Create(ColumnText(LStmt, 0), ColumnText(LStmt, 1),
          ColumnText(LStmt, 2), ColumnText(LStmt, 4), ColumnText(LStmt, 5),
          sqlite3_column_int(LStmt, 6) <> 0, TextToRole(ColumnText(LStmt, 8)),
          ColumnText(LStmt, 3), sqlite3_column_double(LStmt, 11));
        LUser.Deleted := sqlite3_column_int(LStmt, 7) <> 0;
        LUser.FailedAttempts := sqlite3_column_int(LStmt, 9);
        LUser.Locked := sqlite3_column_int(LStmt, 10) <> 0;
        LUser.LastLoginAt := sqlite3_column_double(LStmt, 12);
        LUser.PreferencesText := ColumnText(LStmt, 13);
        FItems.Add(LUser);
      end;
    finally
      sqlite3_finalize(LStmt);
    end;
  finally
    sqlite3_close(LDb);
  end;
end;

function TSqliteUserRepository.RoleToText(ARole: TUserRole): string;
begin
  if ARole = urAdmin then
    Result := 'admin'
  else
    Result := 'normal';
end;

procedure TSqliteUserRepository.Save(AUser: TUser);
var
  LIndex: Integer;
begin
  LIndex := IndexOfId(AUser.Id);
  if LIndex < 0 then
    FItems.Add(AUser)
  else if TUser(FItems[LIndex]) <> AUser then
  begin
    TObject(FItems[LIndex]).Free;
    FItems[LIndex] := AUser;
  end;
  UpsertUser(AUser);
end;

function TSqliteUserRepository.TextToRole(const AValue: string): TUserRole;
begin
  if AValue = 'admin' then
    Result := urAdmin
  else
    Result := urNormal;
end;

procedure TSqliteUserRepository.UpsertUser(AUser: TUser);
var
  LDb: sqlite3;
  LStmt: sqlite3_stmt;
begin
  LDb := nil;
  OpenDatabase(FDatabaseFileName, LDb);
  try
    CheckSqlite(sqlite3_prepare_v2(LDb,
      'insert or replace into users (id, username, display_name, email, password_hash, salt, active, deleted, role, failed_attempts, locked, created_at, last_login_at, preferences_text) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      -1, LStmt, nil), LDb, 'Preparar upsert users');
    try
      BindText(LStmt, 1, AUser.Id);
      BindText(LStmt, 2, AUser.Username);
      BindText(LStmt, 3, AUser.DisplayName);
      BindText(LStmt, 4, AUser.Email);
      BindText(LStmt, 5, AUser.PasswordHash);
      BindText(LStmt, 6, AUser.Salt);
      sqlite3_bind_int(LStmt, 7, BoolToInt(AUser.Active));
      sqlite3_bind_int(LStmt, 8, BoolToInt(AUser.Deleted));
      BindText(LStmt, 9, RoleToText(AUser.Role));
      sqlite3_bind_int(LStmt, 10, AUser.FailedAttempts);
      sqlite3_bind_int(LStmt, 11, BoolToInt(AUser.Locked));
      sqlite3_bind_double(LStmt, 12, AUser.CreatedAt);
      sqlite3_bind_double(LStmt, 13, AUser.LastLoginAt);
      BindText(LStmt, 14, AUser.PreferencesText);
      if sqlite3_step(LStmt) <> SQLITE_DONE then
        raise ESqliteRepositoryError.Create('No se pudo guardar usuario.');
    finally
      sqlite3_finalize(LStmt);
    end;
  finally
    sqlite3_close(LDb);
  end;
end;

end.
