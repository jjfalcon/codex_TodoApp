unit CrudForm;

interface

uses
  Classes,
  Controls,
  DB,
  DBClient,
  DBGrids,
  Dialogs,
  ExtCtrls,
  Forms,
  Graphics,
  Grids,
  StdCtrls,
  SysUtils,
  Windows,
  AppCoreCrud,
  AppCoreLocalization,
  CrudPreviewForm;

type
  TFrmCrud = class(TForm)
    PnlHeader: TPanel;
    EdtSearch: TEdit;
    BtnSearch: TButton;
    BtnRefresh: TButton;
    BtnPreview: TButton;
    BtnNew: TButton;
    BtnDelete: TButton;
    LblEditMode: TLabel;
    CmbEditMode: TComboBox;
    Grid: TDBGrid;
    DataSource: TDataSource;
    ClientDataSet: TClientDataSet;
    procedure BtnSearchClick(Sender: TObject);
    procedure BtnRefreshClick(Sender: TObject);
    procedure BtnPreviewClick(Sender: TObject);
    procedure BtnNewClick(Sender: TObject);
    procedure BtnDeleteClick(Sender: TObject);
    procedure ClientDataSetAfterPost(DataSet: TDataSet);
    procedure CmbEditModeChange(Sender: TObject);
    procedure GridDblClick(Sender: TObject);
    procedure GridColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
    procedure GridDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure GridTitleClick(Column: TColumn);
  private
    FProvider: ICrudProvider;
    FSchema: TCrudSchema;
    FEditMode: TCrudEditMode;
    FSortField: string;
    FSortAscending: Boolean;
    FLoading: Boolean;
    FLayout: ICrudGridLayoutRepository;
    FLayoutKey: string;
    FFilters: TStringList;
    FSearchText: string;
    FSearchForm: TForm;
    FLocalization: ILocalizationService;
    procedure BuildDataset;
    function ColumnBaseCaption(const AFieldName: string): string;
    function CurrentRecord: TCrudRecord;
    procedure ApplyEditMode;
    procedure LoadData;
    procedure LoadLayout;
    procedure OpenDetail(AIsNew: Boolean);
    procedure PromptColumnFilter(Column: TColumn);
    procedure SaveGridConfig;
    procedure SearchChanged(Sender: TObject; const AText: string);
    procedure SetNewRecordDefaults(ARecord: TCrudRecord);
    procedure SyncEditModeSelector;
    function TextOrDefault(const AKey, ADefault: string): string;
    procedure UpdateColumnTitles;
    procedure RecordToDataset(ARecord: TCrudRecord);
    procedure DatasetToRecord(ARecord: TCrudRecord);
  public
    destructor Destroy; override;
    procedure ApplyLocalization(const ALocalization: ILocalizationService;
      AStrict: Boolean);
    procedure Configure(const AProvider: ICrudProvider; AEditMode: TCrudEditMode;
      const ALayout: ICrudGridLayoutRepository = nil; const ALayoutKey: string = '');
    function CellMatchesSearch(const AValue: string): Boolean;
    function CreatePreviewData: TCrudPreviewData;
    procedure SaveLayout;
    procedure SetColumnFilter(const AFieldName, AValue: string);
    procedure SetColumnVisible(const AFieldName: string; AVisible: Boolean);
    procedure SetSearchText(const AText: string);
    property EditMode: TCrudEditMode read FEditMode;
  end;

implementation

{$R *.dfm}

uses
  CrudDetailForm,
  CrudSearchForm,
  AppWinLocalization;

procedure TFrmCrud.ApplyLocalization(const ALocalization: ILocalizationService;
  AStrict: Boolean);
begin
  FLocalization := ALocalization;
  AppWinLocalization.ApplyLocalization(Self, FLocalization, AStrict);
  SyncEditModeSelector;
  UpdateColumnTitles;
  if FSearchForm <> nil then
    TFrmCrudSearch(FSearchForm).ApplyLocalization(FLocalization, AStrict);
end;

procedure TFrmCrud.ApplyEditMode;
begin
  Grid.ReadOnly := FEditMode <> emGrid;
  BtnNew.Enabled := FEditMode <> emNone;
  BtnDelete.Enabled := FEditMode <> emNone;
end;

destructor TFrmCrud.Destroy;
begin
  SaveLayout;
  FFilters.Free;
  FSearchForm.Free;
  FSchema.Free;
  inherited Destroy;
end;

procedure TFrmCrud.BtnDeleteClick(Sender: TObject);
begin
  if ClientDataSet.Active and (not ClientDataSet.IsEmpty) then
  begin
    if MessageDlg(TextOrDefault('Crud.DeleteConfirm.Message',
      'Esta seguro de que desea eliminar este registro?'), mtConfirmation,
      [mbYes, mbNo], 0) <> mrYes then
      Exit;
    FProvider.DeleteRecord(ClientDataSet.FieldByName('id').AsString);
    LoadData;
  end;
end;

procedure TFrmCrud.BtnNewClick(Sender: TObject);
begin
  if FEditMode <> emNone then
    OpenDetail(True);
end;

procedure TFrmCrud.BtnPreviewClick(Sender: TObject);
var
  LForm: TFrmCrudPreview;
begin
  LForm := TFrmCrudPreview.Create(Self);
  try
    LForm.ApplyLocalization(FLocalization, False);
    LForm.Configure(CreatePreviewData);
    LForm.ShowModal;
  finally
    LForm.Free;
  end;
end;

procedure TFrmCrud.BtnRefreshClick(Sender: TObject);
begin
  FFilters.Clear;
  FSearchText := '';
  FSortField := '';
  if FSearchForm <> nil then
    TFrmCrudSearch(FSearchForm).EdtSearch.Text := '';
  SaveGridConfig;
  UpdateColumnTitles;
  LoadData;
end;

procedure TFrmCrud.BtnSearchClick(Sender: TObject);
begin
  if FSearchForm = nil then
  begin
    FSearchForm := TFrmCrudSearch.Create(Self);
    TFrmCrudSearch(FSearchForm).ApplyLocalization(FLocalization, False);
    TFrmCrudSearch(FSearchForm).OnSearchChanged := SearchChanged;
  end;
  FSearchForm.Show;
  FSearchForm.BringToFront;
end;

function TFrmCrud.ColumnBaseCaption(const AFieldName: string): string;
var
  LField: TCrudFieldDef;
begin
  Result := AFieldName;
  if (FLayoutKey <> '') and (FLocalization <> nil) and
    FLocalization.HasText('Crud.' + FLayoutKey + '.' + AFieldName + '.Caption') then
  begin
    Result := FLocalization.Text('Crud.' + FLayoutKey + '.' + AFieldName + '.Caption');
    Exit;
  end;
  if FSchema = nil then
    Exit;
  LField := FSchema.FieldByName(AFieldName);
  if LField <> nil then
    Result := LField.Caption;
end;

procedure TFrmCrud.BuildDataset;
var
  I: Integer;
  LField: TCrudFieldDef;
  LColumn: TColumn;
begin
  ClientDataSet.Close;
  ClientDataSet.FieldDefs.Clear;
  for I := 0 to FSchema.FieldCount - 1 do
  begin
    LField := FSchema.FieldAt(I);
    case LField.FieldType of
      cftBoolean:
        ClientDataSet.FieldDefs.Add(LField.Name, ftString, 5);
      cftInteger:
        ClientDataSet.FieldDefs.Add(LField.Name, ftInteger);
      cftDateTime:
        ClientDataSet.FieldDefs.Add(LField.Name, ftDateTime);
    else
      ClientDataSet.FieldDefs.Add(LField.Name, ftString, 255);
    end;
  end;
  ClientDataSet.CreateDataSet;

  Grid.Columns.Clear;
  for I := 0 to FSchema.FieldCount - 1 do
  begin
    LField := FSchema.FieldAt(I);
    if LField.Visible then
    begin
      LColumn := Grid.Columns.Add;
      LColumn.FieldName := LField.Name;
      LColumn.Title.Caption := LField.Caption;
      LColumn.Width := LField.Width;
    end;
  end;
end;

procedure TFrmCrud.ClientDataSetAfterPost(DataSet: TDataSet);
var
  LRecord: TCrudRecord;
begin
  if FLoading or (FEditMode <> emGrid) then
    Exit;
  LRecord := CurrentRecord;
  try
    FProvider.UpdateRecord(ClientDataSet.FieldByName('id').AsString, LRecord);
  finally
    LRecord.Free;
  end;
end;

procedure TFrmCrud.Configure(const AProvider: ICrudProvider;
  AEditMode: TCrudEditMode; const ALayout: ICrudGridLayoutRepository;
  const ALayoutKey: string);
begin
  FProvider := AProvider;
  FEditMode := AEditMode;
  FLayout := ALayout;
  FLayoutKey := ALayoutKey;
  if FFilters = nil then
    FFilters := TStringList.Create;
  FFilters.Clear;
  FSearchText := '';
  FreeAndNil(FSchema);
  FSchema := FProvider.Schema;
  FSortField := '';
  FSortAscending := True;
  SyncEditModeSelector;
  ApplyEditMode;
  BuildDataset;
  LoadLayout;
  UpdateColumnTitles;
  LoadData;
end;

procedure TFrmCrud.CmbEditModeChange(Sender: TObject);
begin
  case CmbEditMode.ItemIndex of
    0:
      FEditMode := emNone;
    1:
      FEditMode := emGrid;
  else
    FEditMode := emDetail;
  end;
  ApplyEditMode;
end;

function TFrmCrud.CellMatchesSearch(const AValue: string): Boolean;
begin
  Result := (Trim(FSearchText) <> '') and
    (Pos(UpperCase(Trim(FSearchText)), UpperCase(AValue)) > 0);
end;

function TFrmCrud.CreatePreviewData: TCrudPreviewData;
var
  I: Integer;
  LColumn: TColumn;
  LValues: TStringList;
  LBookmark: TBookmark;
begin
  Result := TCrudPreviewData.Create;
  Result.Title := Caption;
  for I := 0 to Grid.Columns.Count - 1 do
  begin
    LColumn := Grid.Columns[I];
    if LColumn.Visible then
      Result.AddColumnEx(LColumn.Title.Caption, LColumn.Width);
  end;

  if (not ClientDataSet.Active) or ClientDataSet.IsEmpty then
    Exit;

  LBookmark := ClientDataSet.GetBookmark;
  ClientDataSet.DisableControls;
  LValues := TStringList.Create;
  try
    ClientDataSet.First;
    while not ClientDataSet.Eof do
    begin
      LValues.Clear;
      for I := 0 to Grid.Columns.Count - 1 do
      begin
        LColumn := Grid.Columns[I];
        if LColumn.Visible then
          LValues.Add(ClientDataSet.FieldByName(LColumn.FieldName).AsString);
      end;
      Result.AddRow(LValues);
      ClientDataSet.Next;
    end;
  finally
    LValues.Free;
    if LBookmark <> nil then
    begin
      ClientDataSet.GotoBookmark(LBookmark);
      ClientDataSet.FreeBookmark(LBookmark);
    end;
    ClientDataSet.EnableControls;
  end;
end;

function TFrmCrud.CurrentRecord: TCrudRecord;
begin
  Result := TCrudRecord.Create;
  DatasetToRecord(Result);
end;

procedure TFrmCrud.GridDrawColumnCell(Sender: TObject; const Rect: TRect;
  DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  if CellMatchesSearch(Column.Field.AsString) then
  begin
    Grid.Canvas.Brush.Color := clYellow;
    Grid.Canvas.FillRect(Rect);
  end;
  Grid.DefaultDrawColumnCell(Rect, DataCol, Column, State);
end;

procedure TFrmCrud.DatasetToRecord(ARecord: TCrudRecord);
var
  I: Integer;
  LField: TCrudFieldDef;
begin
  for I := 0 to FSchema.FieldCount - 1 do
  begin
    LField := FSchema.FieldAt(I);
    ARecord.SetValue(LField.Name, ClientDataSet.FieldByName(LField.Name).AsString);
  end;
end;

procedure TFrmCrud.GridDblClick(Sender: TObject);
begin
  if FEditMode = emDetail then
    OpenDetail(False);
end;

procedure TFrmCrud.GridColumnMoved(Sender: TObject; FromIndex, ToIndex: Longint);
begin
  SaveLayout;
end;

procedure TFrmCrud.GridTitleClick(Column: TColumn);
begin
  if GetKeyState(VK_CONTROL) < 0 then
  begin
    PromptColumnFilter(Column);
    Exit;
  end;

  if FSortField = Column.FieldName then
    FSortAscending := not FSortAscending
  else
  begin
    FSortField := Column.FieldName;
    FSortAscending := True;
  end;
  SaveGridConfig;
  UpdateColumnTitles;
  LoadData;
end;

procedure TFrmCrud.LoadData;
var
  LRecords: TList;
  I: Integer;
begin
  FLoading := True;
  try
    ClientDataSet.EmptyDataSet;
    LRecords := FProvider.List('', FSortField, FSortAscending, FFilters);
    try
      for I := 0 to LRecords.Count - 1 do
        RecordToDataset(TCrudRecord(LRecords[I]));
    finally
      FreeCrudRecordList(LRecords);
    end;
  finally
    FLoading := False;
  end;
end;

procedure TFrmCrud.PromptColumnFilter(Column: TColumn);
var
  LValue: string;
begin
  if Column = nil then
    Exit;
  LValue := FFilters.Values[Column.FieldName];
  if InputQuery(TextOrDefault('Crud.FilterDialog.Caption', 'Filtro'),
    ColumnBaseCaption(Column.FieldName), LValue) then
    SetColumnFilter(Column.FieldName, LValue);
end;

procedure TFrmCrud.LoadLayout;
var
  I: Integer;
  LColumn: TColumn;
  LFieldName: string;
  LWidth: Integer;
  LVisible: Boolean;
  LValue: string;
begin
  if (FLayout = nil) or (FLayoutKey = '') then
    Exit;

  FSortField := FLayout.ReadGridValue(FLayoutKey, 'Sort.Field');
  FSortAscending := FLayout.ReadGridValue(FLayoutKey, 'Sort.Ascending') <> '0';

  for I := 0 to Grid.Columns.Count - 1 do
  begin
    LColumn := Grid.Columns[I];
    LFieldName := LColumn.FieldName;
    LWidth := StrToIntDef(FLayout.ReadGridValue(FLayoutKey, LFieldName + '.Width'), LColumn.Width);
    LVisible := FLayout.ReadGridValue(FLayoutKey, LFieldName + '.Visible') <> '0';
    LColumn.Width := LWidth;
    LColumn.Visible := LVisible;
    LValue := FLayout.ReadGridValue(FLayoutKey, 'Filter.' + LFieldName);
    if LValue <> '' then
      FFilters.Values[LFieldName] := LValue;
  end;
  for I := 0 to Grid.Columns.Count - 1 do
  begin
    LColumn := Grid.Columns[I];
    LFieldName := LColumn.FieldName;
    if FLayout.ReadGridValue(FLayoutKey, LFieldName + '.Index') <> '' then
      LColumn.Index := StrToIntDef(FLayout.ReadGridValue(FLayoutKey, LFieldName + '.Index'), LColumn.Index);
  end;
end;

procedure TFrmCrud.OpenDetail(AIsNew: Boolean);
var
  LForm: TFrmCrudDetail;
  LRecord: TCrudRecord;
  LId: string;
begin
  if (not AIsNew) and (ClientDataSet.IsEmpty) then
    Exit;
  if AIsNew then
  begin
    LRecord := TCrudRecord.Create;
    SetNewRecordDefaults(LRecord);
  end
  else
    LRecord := CurrentRecord;
  LForm := TFrmCrudDetail.Create(Self);
  try
    LForm.ApplyLocalization(FLocalization, False);
    LForm.Configure(FSchema, LRecord, FLayoutKey);
    if LForm.ShowModal = mrOk then
    begin
      if AIsNew then
        LId := FProvider.CreateRecord(LRecord)
      else
      begin
        LId := ClientDataSet.FieldByName('id').AsString;
        FProvider.UpdateRecord(LId, LRecord);
      end;
      LoadData;
      if LId <> '' then
        if not ClientDataSet.Locate('id', LId, []) then
        begin
          FFilters.Clear;
          SaveGridConfig;
          UpdateColumnTitles;
          LoadData;
          ClientDataSet.Locate('id', LId, []);
        end;
    end;
  finally
    LForm.Free;
    LRecord.Free;
  end;
end;

procedure TFrmCrud.RecordToDataset(ARecord: TCrudRecord);
var
  I: Integer;
  LField: TCrudFieldDef;
begin
  ClientDataSet.Append;
  for I := 0 to FSchema.FieldCount - 1 do
  begin
    LField := FSchema.FieldAt(I);
    ClientDataSet.FieldByName(LField.Name).AsString := ARecord.Value(LField.Name);
  end;
  ClientDataSet.Post;
end;

procedure TFrmCrud.SaveLayout;
begin
  SaveGridConfig;
end;

procedure TFrmCrud.SaveGridConfig;
var
  I: Integer;
  LColumn: TColumn;
begin
  if (FLayout = nil) or (FLayoutKey = '') or (Grid = nil) then
    Exit;
  FLayout.WriteGridValue(FLayoutKey, 'Sort.Field', FSortField);
  if FSortAscending then
    FLayout.WriteGridValue(FLayoutKey, 'Sort.Ascending', '1')
  else
    FLayout.WriteGridValue(FLayoutKey, 'Sort.Ascending', '0');
  for I := 0 to Grid.Columns.Count - 1 do
  begin
    LColumn := Grid.Columns[I];
    FLayout.WriteGridValue(FLayoutKey, LColumn.FieldName + '.Index', IntToStr(LColumn.Index));
    FLayout.WriteGridValue(FLayoutKey, LColumn.FieldName + '.Width', IntToStr(LColumn.Width));
    if LColumn.Visible then
      FLayout.WriteGridValue(FLayoutKey, LColumn.FieldName + '.Visible', '1')
    else
      FLayout.WriteGridValue(FLayoutKey, LColumn.FieldName + '.Visible', '0');
    if FFilters <> nil then
      FLayout.WriteGridValue(FLayoutKey, 'Filter.' + LColumn.FieldName,
        FFilters.Values[LColumn.FieldName]);
  end;
end;

procedure TFrmCrud.SearchChanged(Sender: TObject; const AText: string);
begin
  SetSearchText(AText);
end;

procedure TFrmCrud.SetColumnFilter(const AFieldName, AValue: string);
begin
  if FFilters = nil then
    FFilters := TStringList.Create;
  FFilters.Values[AFieldName] := AValue;
  SaveGridConfig;
  UpdateColumnTitles;
  LoadData;
end;

procedure TFrmCrud.SetNewRecordDefaults(ARecord: TCrudRecord);
begin
  if FSchema.FieldByName('active') <> nil then
    ARecord.SetValue('active', 'true');
  if FSchema.FieldByName('locked') <> nil then
    ARecord.SetValue('locked', 'false');
  if FSchema.FieldByName('role') <> nil then
    ARecord.SetValue('role', 'user');
end;

function TFrmCrud.TextOrDefault(const AKey, ADefault: string): string;
begin
  Result := ADefault;
  if (FLocalization <> nil) and FLocalization.HasText(AKey) then
    Result := FLocalization.Text(AKey);
end;

procedure TFrmCrud.SetColumnVisible(const AFieldName: string; AVisible: Boolean);
var
  I: Integer;
begin
  for I := 0 to Grid.Columns.Count - 1 do
    if SameText(Grid.Columns[I].FieldName, AFieldName) then
    begin
      Grid.Columns[I].Visible := AVisible;
      SaveLayout;
      Exit;
    end;
end;

procedure TFrmCrud.SetSearchText(const AText: string);
begin
  FSearchText := AText;
  Grid.Invalidate;
end;

procedure TFrmCrud.SyncEditModeSelector;
var
  LIndex: Integer;
begin
  if CmbEditMode = nil then
    Exit;
  LIndex := Ord(FEditMode);
  CmbEditMode.Items.BeginUpdate;
  try
    CmbEditMode.Items.Clear;
    CmbEditMode.Items.Add(TextOrDefault('Crud.EditMode.None', 'Sin edicion'));
    CmbEditMode.Items.Add(TextOrDefault('Crud.EditMode.Grid', 'Grid'));
    CmbEditMode.Items.Add(TextOrDefault('Crud.EditMode.Detail', 'Detalle'));
    CmbEditMode.ItemIndex := LIndex;
  finally
    CmbEditMode.Items.EndUpdate;
  end;
end;

procedure TFrmCrud.UpdateColumnTitles;
var
  I: Integer;
  LColumn: TColumn;
  LCaption: string;
begin
  for I := 0 to Grid.Columns.Count - 1 do
  begin
    LColumn := Grid.Columns[I];
    LCaption := ColumnBaseCaption(LColumn.FieldName);
    if (FFilters <> nil) and (Trim(FFilters.Values[LColumn.FieldName]) <> '') then
      LCaption := '* ' + LCaption;
    if SameText(FSortField, LColumn.FieldName) then
      if FSortAscending then
        LCaption := '^ ' + LCaption
      else
        LCaption := 'v ' + LCaption;
    LColumn.Title.Caption := LCaption;
  end;
end;

end.
