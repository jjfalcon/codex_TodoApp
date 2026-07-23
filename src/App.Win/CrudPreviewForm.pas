unit CrudPreviewForm;

interface

uses
  Classes,
  Controls,
  Dialogs,
  Forms,
  StdCtrls,
  SysUtils,
  QuickRpt,
  QRCtrls,
  TypInfo,
  AppCoreLocalization;

type
  TCrudPreviewData = class
  private
    FColumns: TStringList;
    FColumnWidths: TList;
    FRows: TList;
    FTitle: string;
    function RowAt(AIndex: Integer): TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddColumn(const ACaption: string);
    procedure AddColumnEx(const ACaption: string; AWidth: Integer);
    procedure AddRow(AValues: TStrings);
    function ColumnCount: Integer;
    function ColumnCaption(AIndex: Integer): string;
    function ColumnWidth(AIndex: Integer): Integer;
    function RowCount: Integer;
    function Cell(ARow, AColumn: Integer): string;
    property Title: string read FTitle write FTitle;
  end;

  TFrmCrudPreview = class(TForm)
    LblOrientation: TLabel;
    CmbOrientation: TComboBox;
    ChkShowTitle: TCheckBox;
    ChkShowDate: TCheckBox;
    ChkShowPageNumber: TCheckBox;
    BtnPreview: TButton;
    BtnPrinterSetup: TButton;
    BtnPrint: TButton;
    BtnClose: TButton;
    PrinterSetupDialog: TPrinterSetupDialog;
    procedure BtnCloseClick(Sender: TObject);
    procedure BtnPreviewClick(Sender: TObject);
    procedure BtnPrintClick(Sender: TObject);
    procedure BtnPrinterSetupClick(Sender: TObject);
  private
    FData: TCrudPreviewData;
    FPrintRow: Integer;
    FDetailLabels: TList;
    procedure BuildReport(AReport: TQuickRep);
    procedure ClearDetailLabels;
    function ColumnLeft(AIndex, ATotalWidth: Integer): Integer;
    function ColumnPrintWidth(AIndex, ATotalWidth: Integer): Integer;
    procedure DetailBeforePrint(Sender: TQRCustomBand; var PrintBand: Boolean);
    function TotalColumnWidth: Integer;
    procedure ReportNeedData(Sender: TObject; var MoreData: Boolean);
    procedure SetBandType(ABand: TQRBand; ABandType: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyLocalization(const ALocalization: ILocalizationService;
      AStrict: Boolean);
    procedure Configure(AData: TCrudPreviewData);
    procedure PreviewData;
    procedure PrintData;
  end;

implementation

{$R *.dfm}

uses
  Graphics,
  Printers,
  AppWinLocalization;

constructor TCrudPreviewData.Create;
begin
  inherited Create;
  FColumns := TStringList.Create;
  FColumnWidths := TList.Create;
  FRows := TList.Create;
end;

destructor TCrudPreviewData.Destroy;
var
  I: Integer;
begin
  for I := 0 to FRows.Count - 1 do
    TObject(FRows[I]).Free;
  FRows.Free;
  FColumnWidths.Free;
  FColumns.Free;
  inherited Destroy;
end;

procedure TCrudPreviewData.AddColumn(const ACaption: string);
begin
  AddColumnEx(ACaption, 80);
end;

procedure TCrudPreviewData.AddColumnEx(const ACaption: string; AWidth: Integer);
begin
  FColumns.Add(ACaption);
  if AWidth <= 0 then
    AWidth := 80;
  FColumnWidths.Add(TObject(AWidth));
end;

procedure TCrudPreviewData.AddRow(AValues: TStrings);
var
  LValues: TStringList;
begin
  LValues := TStringList.Create;
  LValues.Assign(AValues);
  FRows.Add(LValues);
end;

function TCrudPreviewData.Cell(ARow, AColumn: Integer): string;
var
  LRow: TStringList;
begin
  Result := '';
  LRow := RowAt(ARow);
  if (AColumn >= 0) and (AColumn < LRow.Count) then
    Result := LRow[AColumn];
end;

function TCrudPreviewData.ColumnCaption(AIndex: Integer): string;
begin
  Result := FColumns[AIndex];
end;

function TCrudPreviewData.ColumnCount: Integer;
begin
  Result := FColumns.Count;
end;

function TCrudPreviewData.ColumnWidth(AIndex: Integer): Integer;
begin
  Result := Integer(FColumnWidths[AIndex]);
end;

function TCrudPreviewData.RowAt(AIndex: Integer): TStringList;
begin
  Result := TStringList(FRows[AIndex]);
end;

function TCrudPreviewData.RowCount: Integer;
begin
  Result := FRows.Count;
end;

constructor TFrmCrudPreview.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDetailLabels := TList.Create;
  if CmbOrientation.Items.Count = 0 then
  begin
    CmbOrientation.Items.Add('Vertical');
    CmbOrientation.Items.Add('Horizontal');
  end;
  CmbOrientation.ItemIndex := 1;
  ChkShowTitle.Checked := True;
  ChkShowDate.Checked := True;
  ChkShowPageNumber.Checked := True;
end;

destructor TFrmCrudPreview.Destroy;
begin
  ClearDetailLabels;
  FDetailLabels.Free;
  FData.Free;
  inherited Destroy;
end;

procedure TFrmCrudPreview.ApplyLocalization(
  const ALocalization: ILocalizationService; AStrict: Boolean);
begin
  AppWinLocalization.ApplyLocalization(Self, ALocalization, AStrict);
end;

procedure TFrmCrudPreview.BuildReport(AReport: TQuickRep);
var
  I: Integer;
  LTitleBand: TQRBand;
  LHeaderBand: TQRBand;
  LDetailBand: TQRBand;
  LFooterBand: TQRBand;
  LLabel: TQRLabel;
  LSysData: TQRSysData;
  LTotalWidth: Integer;
begin
  ClearDetailLabels;
  AReport.Parent := Self;
  AReport.Visible := False;
  if CmbOrientation.ItemIndex = 1 then
    AReport.Page.Orientation := poLandscape
  else
    AReport.Page.Orientation := poPortrait;
  AReport.OnNeedData := ReportNeedData;

  LTotalWidth := 920;
  if AReport.Page.Orientation = poPortrait then
    LTotalWidth := 640;

  if ChkShowTitle.Checked or ChkShowDate.Checked then
  begin
    LTitleBand := TQRBand.Create(AReport);
    LTitleBand.Parent := AReport;
    SetBandType(LTitleBand, 0);
    LTitleBand.Height := 52;

    if ChkShowTitle.Checked then
    begin
      LLabel := TQRLabel.Create(AReport);
      LLabel.Parent := LTitleBand;
      LLabel.Left := 0;
      LLabel.Top := 4;
      LLabel.Width := LTotalWidth;
      LLabel.Height := 20;
      LLabel.Font.Style := [fsBold];
      LLabel.Caption := FData.Title;
    end;

    if ChkShowDate.Checked then
    begin
      LSysData := TQRSysData.Create(AReport);
      LSysData.Parent := LTitleBand;
      LSysData.Left := 0;
      LSysData.Top := 28;
      LSysData.Width := 220;
      LSysData.Data := qrsDateTime;
    end;
  end;

  LHeaderBand := TQRBand.Create(AReport);
  LHeaderBand.Parent := AReport;
  SetBandType(LHeaderBand, 8);
  LHeaderBand.Height := 24;
  for I := 0 to FData.ColumnCount - 1 do
  begin
    LLabel := TQRLabel.Create(AReport);
    LLabel.Parent := LHeaderBand;
    LLabel.Left := ColumnLeft(I, LTotalWidth);
    LLabel.Top := 4;
    LLabel.Width := ColumnPrintWidth(I, LTotalWidth) - 4;
    LLabel.Height := 16;
    LLabel.Font.Style := [fsBold];
    LLabel.Caption := FData.ColumnCaption(I);
  end;

  LDetailBand := TQRBand.Create(AReport);
  LDetailBand.Parent := AReport;
  SetBandType(LDetailBand, 2);
  LDetailBand.Height := 18;
  LDetailBand.BeforePrint := DetailBeforePrint;
  for I := 0 to FData.ColumnCount - 1 do
  begin
    LLabel := TQRLabel.Create(AReport);
    LLabel.Parent := LDetailBand;
    LLabel.Left := ColumnLeft(I, LTotalWidth);
    LLabel.Top := 2;
    LLabel.Width := ColumnPrintWidth(I, LTotalWidth) - 4;
    LLabel.Height := 14;
    FDetailLabels.Add(LLabel);
  end;

  if ChkShowPageNumber.Checked then
  begin
    LFooterBand := TQRBand.Create(AReport);
    LFooterBand.Parent := AReport;
    SetBandType(LFooterBand, 3);
    LFooterBand.Height := 24;
    LSysData := TQRSysData.Create(AReport);
    LSysData.Parent := LFooterBand;
    LSysData.Left := LTotalWidth - 80;
    LSysData.Top := 4;
    LSysData.Width := 80;
    LSysData.Data := qrsPageNumber;
  end;
end;

procedure TFrmCrudPreview.BtnCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmCrudPreview.BtnPreviewClick(Sender: TObject);
begin
  PreviewData;
end;

procedure TFrmCrudPreview.BtnPrintClick(Sender: TObject);
begin
  PrintData;
end;

procedure TFrmCrudPreview.BtnPrinterSetupClick(Sender: TObject);
begin
  PrinterSetupDialog.Execute;
end;

procedure TFrmCrudPreview.ClearDetailLabels;
begin
  if FDetailLabels <> nil then
    FDetailLabels.Clear;
end;

function TFrmCrudPreview.ColumnLeft(AIndex, ATotalWidth: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to AIndex - 1 do
    Inc(Result, ColumnPrintWidth(I, ATotalWidth));
end;

function TFrmCrudPreview.ColumnPrintWidth(AIndex, ATotalWidth: Integer): Integer;
begin
  if (FData = nil) or (TotalColumnWidth = 0) then
    Result := 80
  else
    Result := (FData.ColumnWidth(AIndex) * ATotalWidth) div TotalColumnWidth;
  if Result < 40 then
    Result := 40;
end;

procedure TFrmCrudPreview.Configure(AData: TCrudPreviewData);
begin
  FData.Free;
  FData := AData;
end;

procedure TFrmCrudPreview.DetailBeforePrint(Sender: TQRCustomBand;
  var PrintBand: Boolean);
var
  I: Integer;
  LLabel: TQRLabel;
begin
  if FData = nil then
    Exit;
  for I := 0 to FDetailLabels.Count - 1 do
  begin
    LLabel := TQRLabel(FDetailLabels[I]);
    LLabel.Caption := FData.Cell(FPrintRow, I);
  end;
  Inc(FPrintRow);
end;

procedure TFrmCrudPreview.PreviewData;
var
  LReport: TQuickRep;
begin
  if FData = nil then
    Exit;
  LReport := TQuickRep.Create(nil);
  try
    FPrintRow := 0;
    BuildReport(LReport);
    LReport.Preview;
  finally
    LReport.Free;
    ClearDetailLabels;
  end;
end;

procedure TFrmCrudPreview.PrintData;
var
  LReport: TQuickRep;
begin
  if FData = nil then
    Exit;
  LReport := TQuickRep.Create(nil);
  try
    FPrintRow := 0;
    BuildReport(LReport);
    LReport.Print;
  finally
    LReport.Free;
    ClearDetailLabels;
  end;
end;

procedure TFrmCrudPreview.ReportNeedData(Sender: TObject; var MoreData: Boolean);
begin
  MoreData := (FData <> nil) and (FPrintRow < FData.RowCount);
end;

procedure TFrmCrudPreview.SetBandType(ABand: TQRBand; ABandType: Integer);
begin
  SetOrdProp(ABand, 'BandType', ABandType);
end;

function TFrmCrudPreview.TotalColumnWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  if FData = nil then
    Exit;
  for I := 0 to FData.ColumnCount - 1 do
    Inc(Result, FData.ColumnWidth(I));
end;

end.
