unit MainForm;

interface

uses
  SysUtils,
  Classes,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  Graphics,
  AppCoreAuth,
  AppCoreClock,
  AppCoreDiagnostics,
  AppCoreLocalization,
  AppCoreRepositoryFactory,
  AppCoreUser,
  AppCoreUserRepository;

type
  TNavigationOption = (noDashboard, noTasks, noUsers);

  TFrmMain = class(TForm)
    PnlSidebar: TPanel;
    BtnDashboard: TButton;
    BtnTasks: TButton;
    BtnUsers: TButton;
    BtnAbout: TButton;
    PnlContent: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnDashboardClick(Sender: TObject);
    procedure BtnTasksClick(Sender: TObject);
    procedure BtnUsersClick(Sender: TObject);
    procedure BtnAboutClick(Sender: TObject);
  private
    FActiveOption: TNavigationOption;
    FCurrentForm: TForm;
    FUserRole: TUserRole;
    FCurrentUserId: string;
    FFactory: IRepositoryFactory;
    FSession: ISessionService;
    FClock: IClock;
    FHasher: IPasswordHasher;
    FLocalization: ILocalizationService;
    FDiagnostics: IDiagnosticsLogger;

    procedure ApplyLocalization;
    procedure ClearContent;
    procedure EmbedForm(AForm: TForm);
    function CreatePlaceholderForm(const ATitle, AMessage: string): TForm;
    procedure LoadOption(AOption: TNavigationOption);
    procedure SetActiveButton(AOption: TNavigationOption);
    procedure SetUserRole(AValue: TUserRole);
    procedure UpdatePermissions;
  public
    procedure ConfigureServices(const AFactory: IRepositoryFactory;
      const ASession: ISessionService; const AClock: IClock;
      const AHasher: IPasswordHasher; const ACurrentUserId: string;
      const ALocalization: ILocalizationService;
      const ADiagnostics: IDiagnosticsLogger);
    property UserRole: TUserRole read FUserRole write SetUserRole;
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

uses
  AboutForm,
  TaskForm,
  UserForm,
  AppWinLocalization;

procedure TFrmMain.ApplyLocalization;
begin
  AppWinLocalization.ApplyLocalization(Self, FLocalization, False);
end;

procedure TFrmMain.BtnDashboardClick(Sender: TObject);
begin
  LoadOption(noDashboard);
end;

procedure TFrmMain.BtnTasksClick(Sender: TObject);
begin
  LoadOption(noTasks);
end;

procedure TFrmMain.BtnUsersClick(Sender: TObject);
begin
  LoadOption(noUsers);
end;

procedure TFrmMain.BtnAboutClick(Sender: TObject);
var
  LForm: TFrmAbout;
begin
  LForm := TFrmAbout.Create(Self);
  try
    LForm.ApplyLocalization(FLocalization, False);
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TFrmMain.ClearContent;
begin
  FreeAndNil(FCurrentForm);
end;

procedure TFrmMain.ConfigureServices(const AFactory: IRepositoryFactory;
  const ASession: ISessionService; const AClock: IClock;
  const AHasher: IPasswordHasher; const ACurrentUserId: string;
  const ALocalization: ILocalizationService;
  const ADiagnostics: IDiagnosticsLogger);
begin
  FFactory := AFactory;
  FSession := ASession;
  FClock := AClock;
  FHasher := AHasher;
  FCurrentUserId := ACurrentUserId;
  FLocalization := ALocalization;
  FDiagnostics := ADiagnostics;
  ApplyLocalization;
  ClearContent;
  LoadOption(noDashboard);
end;

function TFrmMain.CreatePlaceholderForm(const ATitle, AMessage: string): TForm;
var
  LTitle: TLabel;
  LMessage: TLabel;
begin
  Result := TForm.Create(Self);
  Result.BorderStyle := bsNone;
  Result.Caption := ATitle;
  Result.Color := clWindow;

  LTitle := TLabel.Create(Result);
  LTitle.Parent := Result;
  LTitle.Left := 24;
  LTitle.Top := 24;
  LTitle.Font.Style := [fsBold];
  LTitle.Caption := ATitle;

  LMessage := TLabel.Create(Result);
  LMessage.Parent := Result;
  LMessage.Left := 24;
  LMessage.Top := 52;
  LMessage.Caption := AMessage;
end;

procedure TFrmMain.EmbedForm(AForm: TForm);
begin
  ClearContent;
  FCurrentForm := AForm;
  FCurrentForm.BorderStyle := bsNone;
  FCurrentForm.Parent := PnlContent;
  FCurrentForm.Align := alClient;
  FCurrentForm.Visible := True;
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  FCurrentForm := nil;
  FActiveOption := noDashboard;
  FUserRole := urNormal;
  UpdatePermissions;
  LoadOption(noDashboard);
end;

procedure TFrmMain.FormDestroy(Sender: TObject);
begin
  ClearContent;
end;

procedure TFrmMain.LoadOption(AOption: TNavigationOption);
begin
  if (AOption = noUsers) and (FUserRole <> urAdmin) then
    Exit;

  if (FCurrentForm <> nil) and (FActiveOption = AOption) then
    Exit;

  case AOption of
    noDashboard:
      if (FLocalization <> nil) and (LowerCase(FLocalization.Language) = 'en') then
        EmbedForm(CreatePlaceholderForm('Dashboard', 'Main application panel.'))
      else
        EmbedForm(CreatePlaceholderForm('Dashboard', 'Panel principal de la aplicacion.'));
    noTasks:
      begin
        if FDiagnostics <> nil then
          FDiagnostics.Info('Navigation.Tasks', 'Opening tasks screen');
        EmbedForm(TFrmTasks.Create(Self));
        TFrmTasks(FCurrentForm).ApplyLocalization(FLocalization, False);
        TFrmTasks(FCurrentForm).ConfigureDiagnostics(FDiagnostics);
        TFrmTasks(FCurrentForm).Configure(FFactory);
      end;
    noUsers:
      begin
        EmbedForm(TFrmUsers.Create(Self));
        TFrmUsers(FCurrentForm).ApplyLocalization(FLocalization, False);
        TFrmUsers(FCurrentForm).Configure(FFactory.CreateUserRepository, FClock, FHasher, FCurrentUserId);
      end;
  end;

  FActiveOption := AOption;
  SetActiveButton(AOption);
end;

procedure TFrmMain.SetActiveButton(AOption: TNavigationOption);
begin
  BtnDashboard.Font.Style := [];
  BtnTasks.Font.Style := [];
  BtnUsers.Font.Style := [];

  BtnDashboard.Enabled := True;
  BtnTasks.Enabled := True;
  BtnUsers.Enabled := FUserRole = urAdmin;

  case AOption of
    noDashboard:
      BtnDashboard.Font.Style := [fsBold];
    noTasks:
      BtnTasks.Font.Style := [fsBold];
    noUsers:
      BtnUsers.Font.Style := [fsBold];
  end;
end;

procedure TFrmMain.SetUserRole(AValue: TUserRole);
begin
  FUserRole := AValue;
  UpdatePermissions;
  SetActiveButton(FActiveOption);
end;

procedure TFrmMain.UpdatePermissions;
begin
  BtnUsers.Visible := FUserRole = urAdmin;
  BtnUsers.Enabled := FUserRole = urAdmin;
end;

end.
