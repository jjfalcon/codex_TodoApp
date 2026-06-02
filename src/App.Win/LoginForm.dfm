object FrmLogin: TFrmLogin
  Left = 240
  Top = 160
  BorderStyle = bsDialog
  Caption = 'Login'
  ClientHeight = 177
  ClientWidth = 320
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object LblUsername: TLabel
    Left = 24
    Top = 24
    Width = 36
    Height = 13
    Caption = 'Usuario'
  end
  object LblPassword: TLabel
    Left = 24
    Top = 72
    Width = 61
    Height = 13
    Caption = 'Contrasena'
  end
  object LblMessage: TLabel
    Left = 24
    Top = 112
    Width = 272
    Height = 13
    AutoSize = False
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clRed
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    ParentFont = False
  end
  object EdtUsername: TEdit
    Left = 24
    Top = 40
    Width = 272
    Height = 21
    TabOrder = 0
  end
  object EdtPassword: TEdit
    Left = 24
    Top = 88
    Width = 272
    Height = 21
    TabOrder = 1
  end
  object BtnLogin: TButton
    Left = 136
    Top = 136
    Width = 76
    Height = 25
    Caption = 'Entrar'
    Default = True
    TabOrder = 2
    OnClick = BtnLoginClick
  end
  object BtnCancel: TButton
    Left = 220
    Top = 136
    Width = 76
    Height = 25
    Cancel = True
    Caption = 'Cancelar'
    ModalResult = 2
    TabOrder = 3
  end
end
