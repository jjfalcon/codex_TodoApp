unit CrudDetailForm;

interface

uses
  Classes,
  Controls,
  Forms,
  StdCtrls,
  SysUtils,
  AppCoreCrud,
  AppCoreLocalization;

type
  TFrmCrudDetail = class(TForm)
    BtnSave: TButton;
    BtnCancel: TButton;
    procedure BtnSaveClick(Sender: TObject);
  private
    FSchema: TCrudSchema;
    FRecord: TCrudRecord;
    FControls: TStringList;
    FLocalization: ILocalizationService;
    FLayoutKey: string;
    procedure ClearDynamicControls;
    procedure CreateFieldControl(AField: TCrudFieldDef; ATop: Integer);
    function FieldCaption(AField: TCrudFieldDef): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyLocalization(const ALocalization: ILocalizationService;
      AStrict: Boolean);
    procedure Configure(ASchema: TCrudSchema; ARecord: TCrudRecord;
      const ALayoutKey: string = '');
  end;

implementation

{$R *.dfm}

uses
  AppWinLocalization;

procedure TFrmCrudDetail.ApplyLocalization(const ALocalization: ILocalizationService;
  AStrict: Boolean);
begin
  FLocalization := ALocalization;
  AppWinLocalization.ApplyLocalization(Self, FLocalization, AStrict);
end;

constructor TFrmCrudDetail.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FControls := TStringList.Create;
end;

destructor TFrmCrudDetail.Destroy;
begin
  FControls.Free;
  inherited Destroy;
end;

procedure TFrmCrudDetail.BtnSaveClick(Sender: TObject);
var
  I: Integer;
  LName: string;
  LControl: TControl;
begin
  for I := 0 to FControls.Count - 1 do
  begin
    LName := FControls[I];
    LControl := TControl(FControls.Objects[I]);
    if LControl is TEdit then
      FRecord.SetValue(LName, TEdit(LControl).Text)
    else if LControl is TCheckBox then
      if TCheckBox(LControl).Checked then
        FRecord.SetValue(LName, 'true')
      else
        FRecord.SetValue(LName, 'false');
  end;
  ModalResult := mrOk;
end;

procedure TFrmCrudDetail.ClearDynamicControls;
var
  I: Integer;
begin
  for I := FControls.Count - 1 downto 0 do
    FControls.Objects[I].Free;
  FControls.Clear;
end;

procedure TFrmCrudDetail.Configure(ASchema: TCrudSchema; ARecord: TCrudRecord;
  const ALayoutKey: string);
var
  I: Integer;
  LTop: Integer;
  LField: TCrudFieldDef;
begin
  ClearDynamicControls;
  FSchema := ASchema;
  FRecord := ARecord;
  FLayoutKey := ALayoutKey;
  LTop := 16;
  for I := 0 to FSchema.FieldCount - 1 do
  begin
    LField := FSchema.FieldAt(I);
    if LField.Editable then
    begin
      CreateFieldControl(LField, LTop);
      Inc(LTop, 32);
    end;
  end;
  BtnSave.Top := LTop + 8;
  BtnCancel.Top := BtnSave.Top;
  ClientHeight := BtnSave.Top + BtnSave.Height + 16;
end;

function TFrmCrudDetail.FieldCaption(AField: TCrudFieldDef): string;
begin
  Result := AField.Caption;
  if (FLayoutKey <> '') and (FLocalization <> nil) and
    FLocalization.HasText('Crud.' + FLayoutKey + '.' + AField.Name + '.Caption') then
    Result := FLocalization.Text('Crud.' + FLayoutKey + '.' + AField.Name + '.Caption');
end;

procedure TFrmCrudDetail.CreateFieldControl(AField: TCrudFieldDef; ATop: Integer);
var
  LLabel: TLabel;
  LEdit: TEdit;
  LCheck: TCheckBox;
begin
  LLabel := TLabel.Create(Self);
  LLabel.Parent := Self;
  LLabel.Left := 16;
  LLabel.Top := ATop + 4;
  LLabel.Caption := FieldCaption(AField);
  FControls.AddObject(AField.Name + '_label', LLabel);

  if AField.FieldType = cftBoolean then
  begin
    LCheck := TCheckBox.Create(Self);
    LCheck.Parent := Self;
    LCheck.Left := 140;
    LCheck.Top := ATop;
    LCheck.Checked := SameText(FRecord.Value(AField.Name), 'true');
    FControls.AddObject(AField.Name, LCheck);
  end
  else
  begin
    LEdit := TEdit.Create(Self);
    LEdit.Parent := Self;
    LEdit.Left := 140;
    LEdit.Top := ATop;
    LEdit.Width := 220;
    LEdit.Text := FRecord.Value(AField.Name);
    FControls.AddObject(AField.Name, LEdit);
  end;
end;

end.
