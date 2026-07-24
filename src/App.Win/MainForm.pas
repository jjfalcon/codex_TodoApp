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
  AppCoreCrud,
  AppCoreDiagnostics,
  AppCoreLocalization,
  AppCorePreferences,
  AppCoreRepositoryFactory,
  AppCoreTaskService,
  AppCoreUser,
  AppCoreUserRepository,
  AppCoreUserService;

type
  TNavigationOption = (noDashboard, noTsk, noUsr, noPreferences);

  TFrmMain = class(TForm)
    PnlSidebar: TPanel;
    BtnDashboard: TButton;
    BtnTsk: TButton;
    BtnUsr: TButton;
    BtnPreferences: TButton;
    BtnAbout: TButton;
    PnlContent: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnDashboardClick(Sender: TObject);
    procedure BtnTskClick(Sender: TObject);
    procedure BtnUsrClick(Sender: TObject);
    procedure BtnPreferencesClick(Sender: TObject);
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
    FPreferences: ILoginPreferencesRepository;
    FUsers: IUserRepository;
    FCrudUserService: TUserService;

    procedure ApplyLocalization;
    procedure ClearContent;
    procedure EmbedForm(AForm: TForm);
    function CreatePlaceholderForm(const ATitle, AMessage: string): TForm;
    function NavigationOptionToPreference(AOption: TNavigationOption): string;
    function PreferenceToNavigationOption(const AValue: string): TNavigationOption;
    function PreferencesService: TPreferencesService;
    procedure PreferencesLanguageSaved(Sender: TObject; const ALanguage: string);
    procedure SaveLastMainOption(AOption: TNavigationOption);
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
  AppWinUpdateChecker,
  CrudForm,
  PreferencesForm,
  AppCoreUserCrudProvider,
  AppCoreUserPreferencesRepository,
  AppCoreTaskCrudProvider,
  AppWinLocalization;

procedure TFrmMain.ApplyLocalization;
begin
  AppWinLocalization.ApplyLocalization(Self, FLocalization, False);
end;

procedure TFrmMain.BtnDashboardClick(Sender: TObject);
begin
  LoadOption(noDashboard);
end;

procedure TFrmMain.BtnTskClick(Sender: TObject);
begin
  LoadOption(noTsk);
end;

procedure TFrmMain.BtnUsrClick(Sender: TObject);
begin
  LoadOption(noUsr);
end;

procedure TFrmMain.BtnPreferencesClick(Sender: TObject);
begin
  LoadOption(noPreferences);
end;

procedure TFrmMain.BtnAboutClick(Sender: TObject);
var
  LForm: TFrmAbout;
begin
  LForm := TFrmAbout.Create(Self);
  try
    LForm.ApplyLocalization(FLocalization, False);
    LForm.ConfigureUpdateChecker(TAboutUpdateChecker.Create(
      ExtractFilePath(Application.ExeName) + 'app.config'));
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TFrmMain.ClearContent;
begin
  FreeAndNil(FCurrentForm);
  FreeAndNil(FCrudUserService);
end;

procedure TFrmMain.ConfigureServices(const AFactory: IRepositoryFactory;
  const ASession: ISessionService; const AClock: IClock;
  const AHasher: IPasswordHasher; const ACurrentUserId: string;
  const ALocalization: ILocalizationService;
  const ADiagnostics: IDiagnosticsLogger);
var
  LService: TPreferencesService;
  LPreferences: TPreferencesView;
begin
  FFactory := AFactory;
  FSession := ASession;
  FClock := AClock;
  FHasher := AHasher;
  FCurrentUserId := ACurrentUserId;
  FLocalization := ALocalization;
  FDiagnostics := ADiagnostics;
  FPreferences := FFactory.CreateLoginPreferencesRepository;
  FUsers := FFactory.CreateUserRepository;
  LService := PreferencesService;
  try
    LPreferences := LService.GetPreferences;
    if (FLocalization <> nil) and (LPreferences.ActiveLanguage <> '') then
      FLocalization.ChangeLanguage(LPreferences.ActiveLanguage);
  finally
    LService.Free;
  end;
  ApplyLocalization;
  ClearContent;
  LoadOption(PreferenceToNavigationOption(LPreferences.LastMainOption));
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
  if (AOption = noUsr) and (FUserRole <> urAdmin) then
    Exit;

  if (FCurrentForm <> nil) and (FActiveOption = AOption) then
    Exit;

  case AOption of
    noDashboard:
      if (FLocalization <> nil) and (LowerCase(FLocalization.Language) = 'en') then
        EmbedForm(CreatePlaceholderForm('Dashboard', 'Main application panel.'))
      else
        EmbedForm(CreatePlaceholderForm('Dashboard', 'Panel principal de la aplicacion.'));
    noTsk:
      begin
        EmbedForm(TFrmCrud.Create(Self));
        TFrmCrud(FCurrentForm).ApplyLocalization(FLocalization, False);
        TFrmCrud(FCurrentForm).Configure(TTaskCrudProvider.Create(
          TTaskService.Create(FFactory.CreateTaskRepository, FClock)), emDetail,
          TUserGridLayoutRepository.Create(FUsers, FCurrentUserId), 'TSK');
      end;
    noUsr:
      begin
        EmbedForm(TFrmCrud.Create(Self));
        TFrmCrud(FCurrentForm).ApplyLocalization(FLocalization, False);
        FCrudUserService := TUserService.Create(FUsers, FClock, FHasher);
        TFrmCrud(FCurrentForm).Configure(TUserCrudProvider.Create(FCrudUserService,
          FCurrentUserId), emDetail,
          TUserGridLayoutRepository.Create(FUsers, FCurrentUserId), 'USR');
      end;
    noPreferences:
      begin
        EmbedForm(TFrmPreferences.Create(Self));
        TFrmPreferences(FCurrentForm).ApplyLocalization(FLocalization, False);
        TFrmPreferences(FCurrentForm).Configure(PreferencesService);
        TFrmPreferences(FCurrentForm).OnLanguageSaved := PreferencesLanguageSaved;
      end;
  end;

  FActiveOption := AOption;
  SetActiveButton(AOption);
  if AOption <> noPreferences then
    SaveLastMainOption(AOption);
end;

function TFrmMain.NavigationOptionToPreference(AOption: TNavigationOption): string;
begin
  case AOption of
    noTsk:
      Result := 'TSK';
    noUsr:
      Result := 'USR';
  else
    Result := 'Dashboard';
  end;
end;

function TFrmMain.PreferenceToNavigationOption(const AValue: string): TNavigationOption;
begin
  if AValue = 'TSK' then
    Result := noTsk
  else if (AValue = 'USR') and (FUserRole = urAdmin) then
    Result := noUsr
  else
    Result := noDashboard;
end;

function TFrmMain.PreferencesService: TPreferencesService;
begin
  Result := TPreferencesService.Create(FPreferences, FUsers, FCurrentUserId);
end;

procedure TFrmMain.PreferencesLanguageSaved(Sender: TObject;
  const ALanguage: string);
begin
  if FLocalization <> nil then
  begin
    FLocalization.ChangeLanguage(ALanguage);
    ApplyLocalization;
    if FCurrentForm is TFrmPreferences then
      TFrmPreferences(FCurrentForm).ApplyLocalization(FLocalization, False);
    if FCurrentForm is TFrmCrud then
      TFrmCrud(FCurrentForm).ApplyLocalization(FLocalization, False);
  end;
end;

procedure TFrmMain.SaveLastMainOption(AOption: TNavigationOption);
var
  LService: TPreferencesService;
  LPreferences: TPreferencesView;
  LLanguage: string;
begin
  if (FPreferences = nil) or (FUsers = nil) then
    Exit;

  LService := PreferencesService;
  try
    LPreferences := LService.GetPreferences;
    LLanguage := LPreferences.ActiveLanguage;
    if LLanguage = '' then
      LLanguage := 'es';
    LService.SavePreferences(LLanguage, NavigationOptionToPreference(AOption));
  finally
    LService.Free;
  end;
end;

procedure TFrmMain.SetActiveButton(AOption: TNavigationOption);
begin
  BtnDashboard.Font.Style := [];
  BtnTsk.Font.Style := [];
  BtnUsr.Font.Style := [];
  BtnPreferences.Font.Style := [];

  BtnDashboard.Enabled := True;
  BtnTsk.Enabled := True;
  BtnUsr.Enabled := FUserRole = urAdmin;
  BtnPreferences.Enabled := True;

  case AOption of
    noDashboard:
      BtnDashboard.Font.Style := [fsBold];
    noTsk:
      BtnTsk.Font.Style := [fsBold];
    noUsr:
      BtnUsr.Font.Style := [fsBold];
    noPreferences:
      BtnPreferences.Font.Style := [fsBold];
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
  BtnUsr.Visible := FUserRole = urAdmin;
  BtnUsr.Enabled := FUserRole = urAdmin;
end;

end.
