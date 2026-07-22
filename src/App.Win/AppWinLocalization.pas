unit AppWinLocalization;

interface

uses
  Forms,
  AppCoreLocalization;

procedure ApplyLocalization(AForm: TForm; const ALocalization: ILocalizationService;
  AStrict: Boolean);

implementation

uses
  Classes,
  SysUtils,
  TypInfo;

procedure SetStringProperty(AComponent: TComponent; const APropertyName,
  AValue: string; AStrict: Boolean);
begin
  if IsPublishedProp(AComponent, APropertyName) then
    SetStrProp(AComponent, APropertyName, AValue)
  else if AStrict then
    raise Exception.Create(AComponent.Name + ' does not expose property ' + APropertyName + '.');
end;

procedure ApplyLocalization(AForm: TForm; const ALocalization: ILocalizationService;
  AStrict: Boolean);
var
  LKeys: TStringList;
  I: Integer;
  LKey: string;
  LRest: string;
  LDot: Integer;
  LComponentName: string;
  LPropertyName: string;
  LComponent: TComponent;
begin
  if ALocalization = nil then
    Exit;

  LKeys := TStringList.Create;
  try
    ALocalization.AddKeysForForm(AForm.Name, LKeys);
    for I := 0 to LKeys.Count - 1 do
    begin
      LKey := LKeys[I];
      LRest := Copy(LKey, Length(AForm.Name) + 2, MaxInt);
      LDot := Pos('.', LRest);

      if LDot = 0 then
        SetStringProperty(AForm, LRest, ALocalization.Text(LKey), AStrict)
      else
      begin
        LComponentName := Copy(LRest, 1, LDot - 1);
        LPropertyName := Copy(LRest, LDot + 1, MaxInt);
        LComponent := AForm.FindComponent(LComponentName);
        if LComponent = nil then
        begin
          if AStrict then
            raise Exception.Create('Component not found for localization key ' + LKey + '.');
          Continue;
        end;
        SetStringProperty(LComponent, LPropertyName, ALocalization.Text(LKey), AStrict);
      end;
    end;
  finally
    LKeys.Free;
  end;
end;

end.
