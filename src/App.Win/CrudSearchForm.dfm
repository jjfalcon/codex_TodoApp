object FrmCrudSearch: TFrmCrudSearch
  Left = 260
  Top = 180
  Width = 340
  Height = 86
  BorderStyle = bsSizeToolWin
  Caption = 'Buscar'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object EdtSearch: TEdit
    Left = 8
    Top = 12
    Width = 220
    Height = 21
    TabOrder = 0
    OnChange = EdtSearchChange
  end
  object BtnClear: TButton
    Left = 236
    Top = 10
    Width = 80
    Height = 25
    Caption = 'Limpiar'
    TabOrder = 1
    OnClick = BtnClearClick
  end
end
