unit AboutForm;

interface

uses
  Classes,
  Controls,
  Forms,
  StdCtrls,
  ExtCtrls,
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
    LblOS: TLabel;
    LblArch: TLabel;
    LblBuildDate: TLabel;
    LblDbPath: TLabel;
    BtnAccept: TButton;
    procedure BtnAcceptClick(Sender: TObject);
  private
    FService: IAboutService;
    procedure LoadAboutInfo;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.dfm}

constructor TFrmAbout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FService := TAboutService.Create;
  LoadAboutInfo;
end;

procedure TFrmAbout.LoadAboutInfo;
var
  LInfo: TAboutInfo;
begin
  LInfo := FService.GetAboutInfo;

  LblAppName.Caption := LInfo.ApplicationName;
  LblVersion.Caption := 'Version: ' + LInfo.Version;
  LblDescription.Caption := LInfo.Description;
  LblCopyright.Caption := LInfo.Copyright;

  LblExecVersion.Caption := 'Version del ejecutable: ' + LInfo.ExecutableVersion;
  LblOS.Caption := 'Sistema operativo: ' + LInfo.OperatingSystem;
  LblArch.Caption := 'Arquitectura: ' + LInfo.Architecture;
  LblBuildDate.Caption := 'Fecha de compilacion: ' + LInfo.BuildDate;
  LblDbPath.Caption := 'Base de datos: ' + LInfo.DatabasePath;
end;

procedure TFrmAbout.BtnAcceptClick(Sender: TObject);
begin
  ModalResult := mrOk;
end;

end.
