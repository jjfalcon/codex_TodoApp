unit CrudSearchForm;

interface

uses
  Classes,
  Forms,
  StdCtrls,
  AppCoreLocalization;

type
  TCrudSearchChangedEvent = procedure(Sender: TObject; const AText: string) of object;

  TFrmCrudSearch = class(TForm)
    EdtSearch: TEdit;
    BtnClear: TButton;
    procedure BtnClearClick(Sender: TObject);
    procedure EdtSearchChange(Sender: TObject);
  private
    FOnSearchChanged: TCrudSearchChangedEvent;
  public
    procedure ApplyLocalization(const ALocalization: ILocalizationService;
      AStrict: Boolean);
    property OnSearchChanged: TCrudSearchChangedEvent read FOnSearchChanged write FOnSearchChanged;
  end;

implementation

{$R *.dfm}

uses
  AppWinLocalization;

procedure TFrmCrudSearch.ApplyLocalization(const ALocalization: ILocalizationService;
  AStrict: Boolean);
begin
  AppWinLocalization.ApplyLocalization(Self, ALocalization, AStrict);
end;

procedure TFrmCrudSearch.BtnClearClick(Sender: TObject);
begin
  EdtSearch.Text := '';
end;

procedure TFrmCrudSearch.EdtSearchChange(Sender: TObject);
begin
  if Assigned(FOnSearchChanged) then
    FOnSearchChanged(Self, EdtSearch.Text);
end;

end.
