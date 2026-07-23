object FrmPreferences: TFrmPreferences
  Left = 192
  Top = 107
  Width = 696
  Height = 493
  BorderStyle = bsNone
  Caption = 'Preferencias'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object LblTitle: TLabel
    Left = 24
    Top = 24
    Width = 118
    Height = 19
    Caption = 'Preferencias'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LblLastUsername: TLabel
    Left = 24
    Top = 72
    Width = 67
    Height = 13
    Caption = 'Ultimo usuario'
  end
  object LblLanguage: TLabel
    Left = 24
    Top = 120
    Width = 32
    Height = 13
    Caption = 'Idioma'
  end
  object LblLastMainOption: TLabel
    Left = 24
    Top = 168
    Width = 88
    Height = 13
    Caption = 'Pantalla de inicio'
  end
  object LblMessage: TLabel
    Left = 24
    Top = 256
    Width = 3
    Height = 13
    Caption = ''
  end
  object EdtLastUsername: TEdit
    Left = 160
    Top = 68
    Width = 220
    Height = 21
    TabOrder = 0
  end
  object CmbLanguage: TComboBox
    Left = 160
    Top = 116
    Width = 120
    Height = 21
    ItemHeight = 13
    TabOrder = 1
  end
  object CmbLastMainOption: TComboBox
    Left = 160
    Top = 164
    Width = 160
    Height = 21
    ItemHeight = 13
    TabOrder = 2
  end
  object BtnSave: TButton
    Left = 160
    Top = 212
    Width = 90
    Height = 25
    Caption = 'Guardar'
    TabOrder = 3
    OnClick = BtnSaveClick
  end
end
