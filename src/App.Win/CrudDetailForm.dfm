object FrmCrudDetail: TFrmCrudDetail
  Left = 240
  Top = 160
  Width = 420
  Height = 260
  BorderStyle = bsDialog
  Caption = 'Detalle'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 13
  object BtnSave: TButton
    Left = 140
    Top = 200
    Width = 90
    Height = 25
    Caption = 'Guardar'
    Default = True
    TabOrder = 0
    OnClick = BtnSaveClick
  end
  object BtnCancel: TButton
    Left = 240
    Top = 200
    Width = 90
    Height = 25
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 1
  end
end
