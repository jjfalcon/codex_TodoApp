unit AboutForm;

interface

uses
  Classes,
  SysUtils,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
  AppCoreLocalization,
  AppCoreAbout;

type
  TFrmAbout = class(TForm)
    LblTitle: TLabel;
    LblAppName: TLabel;
    LblVersion: TLabel;
    LblDescription: TLabel;
    LblCopyright: TLabel;
    LblTechHeader: TLabel;
    LblExecVersion: TLabel;
    LblCommit: TLabel;
    LblOS: TLabel;
    LblArch: TLabel;
    LblBuildDate: TLabel;
    LblDbPath: TLabel;
    BtnAccept: TButton;
    procedure BtnAcceptClick(Sender: TObject);
  private
    FService: IAboutService;
    FLocalization: ILocalizationService;
    function LocalizedText(const AKey, ADefaultValue: string;
      AStrict: Boolean): string;
    procedure LoadAboutInfo;
  public
    procedure ApplyLocalization(const ALocalization: ILocalizationService; AStrict: Boolean = True);
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.dfm}

uses
  AppWinLocalization;

procedure TFrmAbout.ApplyLocalization(const ALocalization: ILocalizationService;
  AStrict: Boolean);
begin
  FLocalization := ALocalization;
  AppWinLocalization.ApplyLocalization(Self, FLocalization, AStrict);
  LoadAboutInfo;
end;

constructor TFrmAbout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FService := TAboutService.Create;
  LoadAboutInfo;
end;

function TFrmAbout.LocalizedText(const AKey, ADefaultValue: string;
  AStrict: Boolean): string;
begin
  if (FLocalization <> nil) and FLocalization.HasText(AKey) then
    Result := FLocalization.Text(AKey)
  else if AStrict then
    raise Exception.Create('Missing localization key ' + AKey + '.')
  else
    Result := ADefaultValue;
end;

procedure TFrmAbout.LoadAboutInfo;
var
  LInfo: TAboutInfo;
begin
  LInfo := FService.GetAboutInfo;

  LblVersion.Caption := LocalizedText('About.VersionPrefix', 'Version: ', False) +
    LInfo.Version;

  LblExecVersion.Caption := LocalizedText('About.ExecutableVersionPrefix',
    'Version del ejecutable: ', False) + LInfo.ExecutableVersion;
  LblCommit.Caption := LocalizedText('About.CommitPrefix',
    'Commit GitHub: ', False) + LInfo.CommitHash;
  LblOS.Caption := LocalizedText('About.OperatingSystemPrefix',
    'Sistema operativo: ', False) + LInfo.OperatingSystem;
  LblArch.Caption := LocalizedText('About.ArchitecturePrefix',
    'Arquitectura: ', False) + LInfo.Architecture;
  LblBuildDate.Caption := LocalizedText('About.BuildDatePrefix',
    'Fecha de compilacion: ', False) + LInfo.BuildDate;
  LblDbPath.Caption := LocalizedText('About.DatabasePrefix',
    'Base de datos: ', False) + LInfo.DatabasePath;
end;

procedure TFrmAbout.BtnAcceptClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
