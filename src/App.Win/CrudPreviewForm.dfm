object FrmCrudPreview: TFrmCrudPreview
  Left = 220
  Top = 140
  Width = 420
  Height = 210
  Caption = 'Preview'
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
  object LblOrientation: TLabel
    Left = 16
    Top = 20
    Width = 60
    Height = 13
    Caption = 'Orientacion'
  end
  object CmbOrientation: TComboBox
    Left = 112
    Top = 16
    Width = 160
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 0
    Items.Strings = (
      'Vertical'
      'Horizontal')
  end
  object ChkShowTitle: TCheckBox
    Left = 16
    Top = 52
    Width = 180
    Height = 17
    Caption = 'Mostrar titulo'
    TabOrder = 1
  end
  object ChkShowDate: TCheckBox
    Left = 16
    Top = 76
    Width = 180
    Height = 17
    Caption = 'Mostrar fecha'
    TabOrder = 2
  end
  object ChkShowPageNumber: TCheckBox
    Left = 16
    Top = 100
    Width = 180
    Height = 17
    Caption = 'Mostrar pagina'
    TabOrder = 3
  end
  object BtnPreview: TButton
    Left = 16
    Top = 140
    Width = 88
    Height = 25
    Caption = 'Vista previa'
    Default = True
    TabOrder = 4
    OnClick = BtnPreviewClick
  end
  object BtnPrinterSetup: TButton
    Left = 112
    Top = 140
    Width = 88
    Height = 25
    Caption = 'Configurar'
    TabOrder = 5
    OnClick = BtnPrinterSetupClick
  end
  object BtnPrint: TButton
    Left = 208
    Top = 140
    Width = 88
    Height = 25
    Caption = 'Imprimir'
    TabOrder = 6
    OnClick = BtnPrintClick
  end
  object BtnClose: TButton
    Left = 304
    Top = 140
    Width = 88
    Height = 25
    Cancel = True
    Caption = 'Cerrar'
    TabOrder = 7
    OnClick = BtnCloseClick
  end
  object PrinterSetupDialog: TPrinterSetupDialog
    Left = 344
    Top = 16
  end
end
