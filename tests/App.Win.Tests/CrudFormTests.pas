unit CrudFormTests;

interface

procedure RunCrudFormTests(var AFailures: Integer);

implementation

uses
  Classes,
  DBGrids,
  StdCtrls,
  SysUtils,
  CrudForm,
  CrudDetailForm,
  CrudPreviewForm,
  AppCoreCrud,
  AppCoreLocalization,
  AppCorePreferencesFileRepository;

type
  TTestProc = procedure;

  TFakeCrudProvider = class(TInterfacedObject, ICrudProvider)
  public
    function Schema: TCrudSchema;
    function List(const ASearchText, ASortField: string; AAscending: Boolean;
      AFilters: TStrings): TList;
    function CreateRecord(ARecord: TCrudRecord): string;
    procedure UpdateRecord(const AId: string; ARecord: TCrudRecord);
    procedure DeleteRecord(const AId: string);
  end;

  TFakeLocalization = class(TInterfacedObject, ILocalizationService)
  public
    function Language: string;
    function HasText(const AKey: string): Boolean;
    function Text(const AKey: string): string;
    procedure AddKeysForForm(const AFormName: string; AKeys: TStrings);
    procedure ChangeLanguage(const ALanguage: string);
  end;

var
  GLastFilters: TStringList;
  GIncludeCsvSpecialRecord: Boolean;

procedure AssertEquals(AExpected, AActual: Integer; const AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected ' + IntToStr(AExpected) + ', got ' + IntToStr(AActual) + '.');
end;

procedure AssertEquals(const AExpected, AActual, AMessage: string); overload;
begin
  if AExpected <> AActual then
    raise Exception.Create(AMessage + ' Expected "' + AExpected + '", got "' + AActual + '".');
end;

procedure AssertTrue(AValue: Boolean; const AMessage: string);
begin
  if not AValue then
    raise Exception.Create(AMessage);
end;

procedure AssertFalse(AValue: Boolean; const AMessage: string);
begin
  if AValue then
    raise Exception.Create(AMessage);
end;

procedure AssertContains(const AText, AFragment, AMessage: string);
begin
  if Pos(AFragment, AText) = 0 then
    raise Exception.Create(AMessage + ' Expected "' + AText + '" to contain "' + AFragment + '".');
end;

function ColumnByField(AForm: TFrmCrud; const AFieldName: string): TColumn;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AForm.Grid.Columns.Count - 1 do
    if SameText(AForm.Grid.Columns[I].FieldName, AFieldName) then
    begin
      Result := AForm.Grid.Columns[I];
      Exit;
    end;
  raise Exception.Create('Column not found: ' + AFieldName);
end;

procedure RunTest(const AName: string; AProc: TTestProc; var AFailures: Integer);
begin
  try
    AProc;
    Writeln('[OK] ', AName);
  except
    on E: Exception do
    begin
      Inc(AFailures);
      Writeln('[FAIL] ', AName, ': ', E.Message);
    end;
  end;
end;

procedure TFakeLocalization.AddKeysForForm(const AFormName: string; AKeys: TStrings);
begin
  if SameText(AFormName, 'FrmCrud') then
  begin
    AKeys.Add('FrmCrud.Caption');
    AKeys.Add('FrmCrud.BtnSearch.Caption');
    AKeys.Add('FrmCrud.BtnExportCsv.Caption');
  end;
end;

procedure TFakeLocalization.ChangeLanguage(const ALanguage: string);
begin
end;

function TFakeLocalization.HasText(const AKey: string): Boolean;
begin
  Result := SameText(AKey, 'Crud.Test.email.Caption') or
    SameText(AKey, 'Crud.Test.name.Caption') or
    SameText(AKey, 'FrmCrud.Caption') or
    SameText(AKey, 'FrmCrud.BtnSearch.Caption') or
    SameText(AKey, 'FrmCrud.BtnExportCsv.Caption');
end;

function TFakeLocalization.Language: string;
begin
  Result := 'en';
end;

function TFakeLocalization.Text(const AKey: string): string;
begin
  if SameText(AKey, 'Crud.Test.email.Caption') then
    Result := 'E-mail address'
  else if SameText(AKey, 'Crud.Test.name.Caption') then
    Result := 'Full name'
  else if SameText(AKey, 'FrmCrud.Caption') then
    Result := 'Records'
  else if SameText(AKey, 'FrmCrud.BtnSearch.Caption') then
    Result := 'Find'
  else if SameText(AKey, 'FrmCrud.BtnExportCsv.Caption') then
    Result := 'CSV'
  else
    Result := '';
end;

function TFakeCrudProvider.CreateRecord(ARecord: TCrudRecord): string;
begin
  Result := 'new-id';
end;

procedure TFakeCrudProvider.DeleteRecord(const AId: string);
begin
end;

function TFakeCrudProvider.List(const ASearchText, ASortField: string;
  AAscending: Boolean; AFilters: TStrings): TList;
var
  LRecord: TCrudRecord;
begin
  GLastFilters.Assign(AFilters);
  Result := TList.Create;
  LRecord := TCrudRecord.Create;
  LRecord.SetValue('id', '1');
  LRecord.SetValue('name', 'First');
  LRecord.SetValue('email', 'first@example.test');
  Result.Add(LRecord);
  if GIncludeCsvSpecialRecord then
  begin
    LRecord := TCrudRecord.Create;
    LRecord.SetValue('id', '2');
    LRecord.SetValue('name', 'Second; quoted');
    LRecord.SetValue('email', 'second "mail"'#13#10'next@example.test');
    Result.Add(LRecord);
  end;
end;

procedure CrudFormPassesColumnFiltersToProvider;
var
  LForm: TFrmCrud;
begin
  GLastFilters.Clear;
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail);
    LForm.SetColumnFilter('email', 'first@example.test');
    AssertEquals('first@example.test', GLastFilters.Values['email'], 'Column filter should be passed to provider.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormSearchMatchesCellsWithoutFiltering;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail);
    LForm.SetSearchText('first');
    AssertTrue(LForm.CellMatchesSearch('First'), 'Search should match cell text case-insensitively.');
    AssertFalse(LForm.CellMatchesSearch('Second'), 'Search should not match unrelated cell text.');
    AssertEquals(1, LForm.ClientDataSet.RecordCount, 'Search highlight should not filter dataset rows.');
  finally
    LForm.Free;
  end;
end;

procedure CrudDetailWritesEditableFields;
var
  LForm: TFrmCrudDetail;
  LSchema: TCrudSchema;
  LRecord: TCrudRecord;
  I: Integer;
begin
  LSchema := TCrudSchema.Create;
  LRecord := TCrudRecord.Create;
  LForm := TFrmCrudDetail.Create(nil);
  try
    LSchema.AddField(TCrudFieldDef.Create('name', 'Name', cftString, True, True, True, 120));
    LRecord.SetValue('name', 'Old');
    LForm.Configure(LSchema, LRecord);
    for I := 0 to LForm.ControlCount - 1 do
      if LForm.Controls[I] is TEdit then
        TEdit(LForm.Controls[I]).Text := 'New';
    LForm.BtnSaveClick(nil);
    AssertEquals('New', LRecord.Value('name'), 'Detail save should write edited field by name.');
  finally
    LForm.Free;
    LRecord.Free;
    LSchema.Free;
  end;
end;

procedure CrudDetailUsesCheckboxForBooleanFields;
var
  LForm: TFrmCrudDetail;
  LSchema: TCrudSchema;
  LRecord: TCrudRecord;
  I: Integer;
  LCheck: TCheckBox;
begin
  LSchema := TCrudSchema.Create;
  LRecord := TCrudRecord.Create;
  LForm := TFrmCrudDetail.Create(nil);
  try
    LSchema.AddField(TCrudFieldDef.Create('completed', 'Completed', cftBoolean, True, True, False, 80));
    LRecord.SetValue('completed', 'false');
    LForm.Configure(LSchema, LRecord);
    LCheck := nil;
    for I := 0 to LForm.ControlCount - 1 do
      if LForm.Controls[I] is TCheckBox then
        LCheck := TCheckBox(LForm.Controls[I]);
    AssertTrue(LCheck <> nil, 'Boolean field should use checkbox in detail form.');
    LCheck.Checked := True;
    LForm.BtnSaveClick(nil);
    AssertEquals('true', LRecord.Value('completed'), 'Checkbox should write boolean text value.');
  finally
    LForm.Free;
    LRecord.Free;
    LSchema.Free;
  end;
end;

procedure CrudFormShowsSortAndFilterIndicators;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail);
    LForm.GridTitleClick(ColumnByField(LForm, 'email'));
    AssertContains(ColumnByField(LForm, 'email').Title.Caption, '^', 'Ascending sort should be shown in header.');
    LForm.GridTitleClick(ColumnByField(LForm, 'email'));
    AssertContains(ColumnByField(LForm, 'email').Title.Caption, 'v', 'Descending sort should be shown in header.');
    LForm.SetColumnFilter('email', 'first');
    AssertContains(ColumnByField(LForm, 'email').Title.Caption, '*', 'Active filter should be shown in header.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormPersistsColumnFilters;
var
  LFileName: string;
  LForm: TFrmCrud;
  LLayout: ICrudGridLayoutRepository;
begin
  LFileName := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    'crud-form-filter-test.config';
  DeleteFile(LFileName);

  LLayout := TFileLoginPreferencesRepository.Create(LFileName) as ICrudGridLayoutRepository;
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail, LLayout, 'Test');
    LForm.SetColumnFilter('email', 'first');
    AssertEquals('first', LLayout.ReadGridValue('Test', 'Filter.email'), 'Filter should be saved in grid config.');
  finally
    LForm.Free;
    LLayout := nil;
    DeleteFile(LFileName);
  end;
end;

procedure CrudFormLocalizesStaticTextsAndColumnCaptions;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.ApplyLocalization(TFakeLocalization.Create, False);
    LForm.Configure(TFakeCrudProvider.Create, emDetail, nil, 'Test');
    AssertEquals('Records', LForm.Caption, 'CRUD form caption should be localized.');
    AssertEquals('Find', LForm.BtnSearch.Caption, 'CRUD static button caption should be localized.');
    AssertEquals('E-mail address', ColumnByField(LForm, 'email').Title.Caption,
      'CRUD column caption should use layout-specific localization key.');
  finally
    LForm.Free;
  end;
end;

procedure CrudDetailLocalizesFieldLabels;
var
  LForm: TFrmCrudDetail;
  LSchema: TCrudSchema;
  LRecord: TCrudRecord;
  I: Integer;
  LFound: Boolean;
begin
  LSchema := TCrudSchema.Create;
  LRecord := TCrudRecord.Create;
  LForm := TFrmCrudDetail.Create(nil);
  try
    LSchema.AddField(TCrudFieldDef.Create('email', 'Email', cftString, True, True, True, 120));
    LRecord.SetValue('email', 'first@example.test');
    LForm.ApplyLocalization(TFakeLocalization.Create, False);
    LForm.Configure(LSchema, LRecord, 'Test');
    LFound := False;
    for I := 0 to LForm.ControlCount - 1 do
      if (LForm.Controls[I] is TLabel) and
        (TLabel(LForm.Controls[I]).Caption = 'E-mail address') then
        LFound := True;
    AssertTrue(LFound, 'CRUD detail field labels should use layout-specific localization key.');
  finally
    LForm.Free;
    LRecord.Free;
    LSchema.Free;
  end;
end;

procedure CrudFormPreviewButtonIsAvailable;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail);
    AssertTrue(LForm.BtnPreview.Visible, 'CRUD preview button should be visible.');
    AssertTrue(LForm.BtnPreview.Enabled, 'CRUD preview button should be enabled.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormPreviewDataUsesVisibleGridExactly;
var
  LForm: TFrmCrud;
  LData: TCrudPreviewData;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.ApplyLocalization(TFakeLocalization.Create, False);
    LForm.Configure(TFakeCrudProvider.Create, emDetail, nil, 'Test');
    LForm.SetColumnVisible('name', False);
    ColumnByField(LForm, 'email').Width := 222;
    LData := LForm.CreatePreviewData;
    try
      AssertEquals(1, LData.ColumnCount, 'Preview should include only visible grid columns.');
      AssertEquals('E-mail address', LData.ColumnCaption(0), 'Preview should use current grid title caption.');
      AssertEquals(222, LData.ColumnWidth(0), 'Preview should preserve current grid column width.');
      AssertEquals(1, LData.RowCount, 'Preview should include currently loaded grid rows.');
      AssertEquals('first@example.test', LData.Cell(0, 0), 'Preview should use current dataset value.');
    finally
      LData.Free;
    end;
  finally
    LForm.Free;
  end;
end;

procedure CrudFormCsvExportUsesVisibleGridAndSemicolon;
var
  LForm: TFrmCrud;
  LCsv: string;
begin
  GIncludeCsvSpecialRecord := True;
  LForm := TFrmCrud.Create(nil);
  try
    LForm.ApplyLocalization(TFakeLocalization.Create, False);
    LForm.Configure(TFakeCrudProvider.Create, emDetail, nil, 'Test');
    LForm.SetColumnVisible('name', False);
    LCsv := LForm.CreateCsvText;
    AssertEquals('E-mail address' + sLineBreak +
      'first@example.test' + sLineBreak +
      '"second ""mail""' + sLineBreak +
      'next@example.test"' + sLineBreak,
      LCsv, 'CSV should export visible grid state with semicolon CSV escaping.');
  finally
    LForm.Free;
    GIncludeCsvSpecialRecord := False;
  end;
end;

procedure CrudPreviewFormExposesLayoutOptions;
var
  LForm: TFrmCrudPreview;
begin
  LForm := TFrmCrudPreview.Create(nil);
  try
    AssertEquals(2, LForm.CmbOrientation.Items.Count, 'Preview should allow orientation selection.');
    AssertTrue(LForm.ChkShowTitle.Checked, 'Preview should allow showing title by default.');
    AssertTrue(LForm.ChkShowDate.Checked, 'Preview should allow showing date by default.');
    AssertTrue(LForm.ChkShowPageNumber.Checked, 'Preview should allow showing page number by default.');
  finally
    LForm.Free;
  end;
end;

function TFakeCrudProvider.Schema: TCrudSchema;
begin
  Result := TCrudSchema.Create;
  Result.AddField(TCrudFieldDef.Create('id', 'Id', cftString, False, False, False, 60));
  Result.AddField(TCrudFieldDef.Create('name', 'Name', cftString, True, True, True, 120));
  Result.AddField(TCrudFieldDef.Create('email', 'Email', cftString, True, True, True, 140));
end;

procedure TFakeCrudProvider.UpdateRecord(const AId: string; ARecord: TCrudRecord);
begin
end;

procedure CrudFormEmNoneIsReadOnly;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emNone);
    AssertTrue(LForm.Grid.ReadOnly, 'emNone should make grid read-only.');
    AssertFalse(LForm.BtnNew.Enabled, 'emNone should disable new.');
    AssertFalse(LForm.BtnDelete.Enabled, 'emNone should disable delete.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormEmGridAllowsGridEditing;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emGrid);
    AssertFalse(LForm.Grid.ReadOnly, 'emGrid should allow grid editing.');
    AssertTrue(LForm.BtnNew.Enabled, 'emGrid should allow new.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormEmDetailKeepsGridReadOnly;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail);
    AssertTrue(LForm.Grid.ReadOnly, 'emDetail should keep grid read-only.');
    AssertTrue(LForm.BtnNew.Enabled, 'emDetail should allow detail create.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormEditModeSelectorChangesMode;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emNone);
    AssertEquals(3, LForm.CmbEditMode.Items.Count, 'Edit mode selector should expose all modes.');
    AssertEquals(0, LForm.CmbEditMode.ItemIndex, 'Edit mode selector should show current mode.');

    LForm.CmbEditMode.ItemIndex := 1;
    LForm.CmbEditModeChange(nil);
    AssertEquals(Ord(emGrid), Ord(LForm.EditMode), 'Selecting grid mode should update edit mode.');
    AssertFalse(LForm.Grid.ReadOnly, 'Selecting grid mode should allow grid editing.');
    AssertTrue(LForm.BtnNew.Enabled, 'Selecting grid mode should enable new.');

    LForm.CmbEditMode.ItemIndex := 2;
    LForm.CmbEditModeChange(nil);
    AssertEquals(Ord(emDetail), Ord(LForm.EditMode), 'Selecting detail mode should update edit mode.');
    AssertTrue(LForm.Grid.ReadOnly, 'Selecting detail mode should keep grid read-only.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormBuildsColumnsFromSchema;
var
  LForm: TFrmCrud;
begin
  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail);
    AssertEquals(2, LForm.Grid.Columns.Count, 'Grid should include only visible schema fields.');
    AssertEquals(1, LForm.ClientDataSet.RecordCount, 'Grid dataset should load provider records.');
  finally
    LForm.Free;
  end;
end;

procedure CrudFormPersistsColumnLayout;
var
  LFileName: string;
  LForm: TFrmCrud;
begin
  LFileName := IncludeTrailingPathDelimiter(GetEnvironmentVariable('TEMP')) +
    'crud-form-layout-test.layout';
  DeleteFile(LFileName);

  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail,
      TFileLoginPreferencesRepository.Create(LFileName) as ICrudGridLayoutRepository, 'Test');
    ColumnByField(LForm, 'email').Width := 222;
    ColumnByField(LForm, 'email').Index := 0;
    LForm.SetColumnVisible('name', False);
    LForm.SaveLayout;
  finally
    LForm.Free;
  end;

  LForm := TFrmCrud.Create(nil);
  try
    LForm.Configure(TFakeCrudProvider.Create, emDetail,
      TFileLoginPreferencesRepository.Create(LFileName) as ICrudGridLayoutRepository, 'Test');
    AssertEquals(0, ColumnByField(LForm, 'email').Index, 'Column order should be restored.');
    AssertEquals(222, ColumnByField(LForm, 'email').Width, 'Column width should be restored.');
    AssertFalse(ColumnByField(LForm, 'name').Visible, 'Column visibility should be restored.');
  finally
    LForm.Free;
    DeleteFile(LFileName);
  end;
end;

procedure RunCrudFormTests(var AFailures: Integer);
begin
  RunTest('CrudForm_emNone_is_read_only', CrudFormEmNoneIsReadOnly, AFailures);
  RunTest('CrudForm_emGrid_allows_grid_editing', CrudFormEmGridAllowsGridEditing, AFailures);
  RunTest('CrudForm_emDetail_keeps_grid_read_only', CrudFormEmDetailKeepsGridReadOnly, AFailures);
  RunTest('CrudForm_edit_mode_selector_changes_mode', CrudFormEditModeSelectorChangesMode, AFailures);
  RunTest('CrudForm_builds_columns_from_schema', CrudFormBuildsColumnsFromSchema, AFailures);
  RunTest('CrudForm_persists_column_layout', CrudFormPersistsColumnLayout, AFailures);
  RunTest('CrudForm_passes_column_filters_to_provider', CrudFormPassesColumnFiltersToProvider, AFailures);
  RunTest('CrudForm_search_matches_cells_without_filtering', CrudFormSearchMatchesCellsWithoutFiltering, AFailures);
  RunTest('CrudDetail_writes_editable_fields', CrudDetailWritesEditableFields, AFailures);
  RunTest('CrudDetail_uses_checkbox_for_boolean_fields', CrudDetailUsesCheckboxForBooleanFields, AFailures);
  RunTest('CrudForm_shows_sort_and_filter_indicators', CrudFormShowsSortAndFilterIndicators, AFailures);
  RunTest('CrudForm_persists_column_filters', CrudFormPersistsColumnFilters, AFailures);
  RunTest('CrudForm_localizes_static_texts_and_column_captions', CrudFormLocalizesStaticTextsAndColumnCaptions, AFailures);
  RunTest('CrudDetail_localizes_field_labels', CrudDetailLocalizesFieldLabels, AFailures);
  RunTest('CrudForm_preview_button_is_available', CrudFormPreviewButtonIsAvailable, AFailures);
  RunTest('CrudForm_preview_data_uses_visible_grid_exactly', CrudFormPreviewDataUsesVisibleGridExactly, AFailures);
  RunTest('CrudForm_csv_export_uses_visible_grid_and_semicolon', CrudFormCsvExportUsesVisibleGridAndSemicolon, AFailures);
  RunTest('CrudPreviewForm_exposes_layout_options', CrudPreviewFormExposesLayoutOptions, AFailures);
end;

initialization
  GLastFilters := TStringList.Create;

finalization
  GLastFilters.Free;

end.
