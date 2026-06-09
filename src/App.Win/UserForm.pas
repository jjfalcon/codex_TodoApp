unit UserForm;

interface

uses
  Classes,
  Controls,
  Dialogs,
  Forms,
  StdCtrls,
  SysUtils,
  AppCoreAuth,
  AppCoreClock,
  AppCoreUser,
  AppCoreUserRepository,
  AppCoreUserService;

type
  TFrmUsers = class(TForm)
    LstUsers: TListBox;
    LblUsername: TLabel;
    EdtUsername: TEdit;
    LblDisplayName: TLabel;
    EdtDisplayName: TEdit;
    LblEmail: TLabel;
    EdtEmail: TEdit;
    LblPassword: TLabel;
    EdtPassword: TEdit;
    CmbRole: TComboBox;
    ChkActive: TCheckBox;
    ChkLocked: TCheckBox;
    ChkShowDeleted: TCheckBox;
    EdtSearch: TEdit;
    BtnSearch: TButton;
    BtnNew: TButton;
    BtnSave: TButton;
    BtnPassword: TButton;
    BtnUnlock: TButton;
    BtnDelete: TButton;
    LblMessage: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure LstUsersClick(Sender: TObject);
    procedure BtnSearchClick(Sender: TObject);
    procedure BtnNewClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnPasswordClick(Sender: TObject);
    procedure BtnUnlockClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure ChkShowDeletedClick(Sender: TObject);
  private
    FCurrentUserId: string;
    FSelectedUserId: string;
    FService: TUserService;
    FUsers: IUserRepository;
    FClock: IClock;
    FHasher: IPasswordHasher;
    FList: TList;

    function CurrentRole: TUserRole;
    function SelectedUser: TUser;
    procedure ClearSelection;
    procedure LoadSelectedUser;
    procedure RefreshUsers;
    procedure SelectUserById(const AUserId: string);
    procedure ShowError(E: Exception);
  public
    procedure Configure(const AUsers: IUserRepository; const AClock: IClock;
      const AHasher: IPasswordHasher; const ACurrentUserId: string);
  end;

implementation

{$R *.dfm}

procedure TFrmUsers.BtnDeleteClick(Sender: TObject);
begin
  try
    if FSelectedUserId = '' then
      Exit;
    if MessageDlg('Esta seguro de que desea eliminar este usuario?', mtConfirmation,
      [mbYes, mbNo], 0) <> mrYes then
      Exit;
    FService.DeleteUser(FCurrentUserId, FSelectedUserId, True);
    LblMessage.Caption := 'Usuario eliminado correctamente.';
    ClearSelection;
    RefreshUsers;
  except
    on E: Exception do
      ShowError(E);
  end;
end;

procedure TFrmUsers.BtnNewClick(Sender: TObject);
var
  LUser: TUser;
begin
  try
    LUser := FService.CreateUser(FCurrentUserId, EdtUsername.Text, EdtDisplayName.Text,
      EdtEmail.Text, EdtPassword.Text, CurrentRole);
    LblMessage.Caption := 'Usuario creado correctamente.';
    EdtSearch.Text := '';
    ChkShowDeleted.Checked := False;
    ClearSelection;
    RefreshUsers;
    SelectUserById(LUser.Id);
  except
    on E: Exception do
      ShowError(E);
  end;
end;

procedure TFrmUsers.BtnPasswordClick(Sender: TObject);
begin
  try
    if FSelectedUserId = '' then
      Exit;
    FService.ChangePassword(FCurrentUserId, FSelectedUserId, EdtPassword.Text);
    LblMessage.Caption := 'Contrasena actualizada correctamente.';
    EdtPassword.Text := '';
  except
    on E: Exception do
      ShowError(E);
  end;
end;

procedure TFrmUsers.BtnSaveClick(Sender: TObject);
begin
  try
    if FSelectedUserId = '' then
      Exit;
    FService.UpdateUser(FCurrentUserId, FSelectedUserId, EdtUsername.Text,
      EdtDisplayName.Text, EdtEmail.Text, ChkActive.Checked, CurrentRole,
      ChkLocked.Checked);
    LblMessage.Caption := 'Usuario actualizado correctamente.';
    RefreshUsers;
  except
    on E: Exception do
      ShowError(E);
  end;
end;

procedure TFrmUsers.BtnSearchClick(Sender: TObject);
begin
  RefreshUsers;
end;

procedure TFrmUsers.BtnUnlockClick(Sender: TObject);
begin
  try
    if FSelectedUserId = '' then
      Exit;
    FService.UnlockUser(FCurrentUserId, FSelectedUserId);
    LblMessage.Caption := 'Usuario actualizado correctamente.';
    RefreshUsers;
    LoadSelectedUser;
  except
    on E: Exception do
      ShowError(E);
  end;
end;

procedure TFrmUsers.ChkShowDeletedClick(Sender: TObject);
begin
  RefreshUsers;
end;

procedure TFrmUsers.ClearSelection;
begin
  FSelectedUserId := '';
  LstUsers.ItemIndex := -1;
  EdtUsername.Text := '';
  EdtDisplayName.Text := '';
  EdtEmail.Text := '';
  EdtPassword.Text := '';
  ChkActive.Checked := True;
  ChkLocked.Checked := False;
  CmbRole.ItemIndex := 1;
end;

procedure TFrmUsers.Configure(const AUsers: IUserRepository; const AClock: IClock;
  const AHasher: IPasswordHasher; const ACurrentUserId: string);
begin
  FUsers := AUsers;
  FClock := AClock;
  FHasher := AHasher;
  FCurrentUserId := ACurrentUserId;
  FService := TUserService.Create(FUsers, FClock, FHasher);
  RefreshUsers;
end;

function TFrmUsers.CurrentRole: TUserRole;
begin
  if CmbRole.ItemIndex = 0 then
    Result := urAdmin
  else
    Result := urNormal;
end;

procedure TFrmUsers.FormCreate(Sender: TObject);
begin
  FList := nil;
  FService := nil;
  FSelectedUserId := '';
  CmbRole.Items.Add('Administrador');
  CmbRole.Items.Add('Usuario normal');
  ClearSelection;
end;

procedure TFrmUsers.LstUsersClick(Sender: TObject);
begin
  LoadSelectedUser;
end;

procedure TFrmUsers.LoadSelectedUser;
var
  LUser: TUser;
begin
  LUser := SelectedUser;
  if LUser = nil then
    Exit;

  FSelectedUserId := LUser.Id;
  EdtUsername.Text := LUser.Username;
  EdtDisplayName.Text := LUser.DisplayName;
  EdtEmail.Text := LUser.Email;
  EdtPassword.Text := '';
  ChkActive.Checked := LUser.Active;
  ChkLocked.Checked := LUser.Locked;
  if LUser.Role = urAdmin then
    CmbRole.ItemIndex := 0
  else
    CmbRole.ItemIndex := 1;
end;

procedure TFrmUsers.RefreshUsers;
var
  I: Integer;
  LFilters: TUserFilters;
  LUser: TUser;
begin
  if FService = nil then
    Exit;

  FreeAndNil(FList);
  LFilters := [];
  if ChkShowDeleted.Checked then
    Include(LFilters, ufDeleted);

  FList := FService.ListUsers(EdtSearch.Text, LFilters);
  LstUsers.Items.Clear;
  for I := 0 to FList.Count - 1 do
  begin
    LUser := TUser(FList[I]);
    LstUsers.Items.Add(LUser.Username + ' - ' + LUser.DisplayName);
  end;
end;

function TFrmUsers.SelectedUser: TUser;
begin
  Result := nil;
  if (FList = nil) or (LstUsers.ItemIndex < 0) then
    Exit;
  Result := TUser(FList[LstUsers.ItemIndex]);
end;

procedure TFrmUsers.SelectUserById(const AUserId: string);
var
  I: Integer;
begin
  if FList = nil then
    Exit;

  for I := 0 to FList.Count - 1 do
    if TUser(FList[I]).Id = AUserId then
    begin
      LstUsers.ItemIndex := I;
      LoadSelectedUser;
      Exit;
    end;
end;

procedure TFrmUsers.ShowError(E: Exception);
begin
  LblMessage.Caption := E.Message;
end;

end.
