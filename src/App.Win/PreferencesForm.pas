unit PreferencesForm;

interface

uses
  Classes,
  Controls,
  Forms,
  StdCtrls,
  SysUtils,
  AppCoreLocalization,
  AppCorePreferences;

type
  TLanguageSavedEvent = procedure(Sender: TObject; const ALanguage: string) of object;

  TFrmPreferences = class(TForm)
    LblTitle: TLabel;
    LblLastUsername: TLabel;
    EdtLastUsername: TEdit;
    LblLanguage: TLabel;
    CmbLanguage: TComboBox;
    LblLastMainOption: TLabel;
    CmbLastMainOption: TComboBox;
    BtnSave: TButton;
    LblMessage: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
  private
    FService: TPreferencesService;
    FOnLanguageSaved: TLanguageSavedEvent;
    procedure SelectComboValue(ACombo: TComboBox; const AValue, ADefault: string);
  public
    procedure ApplyLocalization(const ALocalization: ILocalizationService; AStrict: Boolean = True);
    procedure Configure(AService: TPreferencesService);
    property OnLanguageSaved: TLanguageSavedEvent read FOnLanguageSaved write FOnLanguageSaved;
  end;

implementation

{$R *.dfm}

uses
  AppWinLocalization;

procedure TFrmPreferences.ApplyLocalization(const ALocalization: ILocalizationService;
  AStrict: Boolean);
begin
  AppWinLocalization.ApplyLocalization(Self, ALocalization, AStrict);
end;

procedure TFrmPreferences.BtnSaveClick(Sender: TObject);
begin
  try
    LblMessage.Caption := '';
    FService.SavePreferences(CmbLanguage.Text, CmbLastMainOption.Text);
    LblMessage.Caption := 'Preferencias guardadas correctamente.';
    if Assigned(FOnLanguageSaved) then
      FOnLanguageSaved(Self, CmbLanguage.Text);
  except
    on E: EPreferencesValidationError do
      LblMessage.Caption := E.Message;
  end;
end;

procedure TFrmPreferences.Configure(AService: TPreferencesService);
var
  LPreferences: TUserPreferences;
begin
  FreeAndNil(FService);
  FService := AService;
  LPreferences := FService.GetPreferences;
  EdtLastUsername.Text := LPreferences.LastUsername;
  SelectComboValue(CmbLanguage, LPreferences.ActiveLanguage, 'es');
  SelectComboValue(CmbLastMainOption, LPreferences.LastMainOption, 'Dashboard');
end;

procedure TFrmPreferences.FormCreate(Sender: TObject);
begin
  EdtLastUsername.ReadOnly := True;
  CmbLanguage.Items.Add('es');
  CmbLanguage.Items.Add('en');
  CmbLastMainOption.Items.Add('Dashboard');
  CmbLastMainOption.Items.Add('TSK');
  CmbLastMainOption.Items.Add('USR');
  SelectComboValue(CmbLanguage, '', 'es');
  SelectComboValue(CmbLastMainOption, '', 'Dashboard');
  LblMessage.Caption := '';
end;

procedure TFrmPreferences.FormDestroy(Sender: TObject);
begin
  FService.Free;
end;

procedure TFrmPreferences.SelectComboValue(ACombo: TComboBox; const AValue,
  ADefault: string);
begin
  if ACombo.Items.IndexOf(AValue) >= 0 then
    ACombo.ItemIndex := ACombo.Items.IndexOf(AValue)
  else
    ACombo.ItemIndex := ACombo.Items.IndexOf(ADefault);
end;

end.
