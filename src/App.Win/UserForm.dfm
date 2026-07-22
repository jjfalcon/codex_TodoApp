object FrmUsers: TFrmUsers
  Left = 0
  Top = 0
  Width = 696
  Height = 493
  BorderStyle = bsNone
  Caption = 'Usuarios'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object LblUsername: TLabel
    Left = 272
    Top = 48
    Width = 36
    Height = 13
    Caption = 'Usuario'
  end
  object LblDisplayName: TLabel
    Left = 272
    Top = 96
    Width = 73
    Height = 13
    Caption = 'Nombre visible'
  end
  object LblEmail: TLabel
    Left = 272
    Top = 144
    Width = 24
    Height = 13
    Caption = 'Email'
  end
  object LblPassword: TLabel
    Left = 272
    Top = 192
    Width = 57
    Height = 13
    Caption = 'Contraseña'
  end
  object LblMessage: TLabel
    Left = 272
    Top = 424
    Width = 393
    Height = 41
    AutoSize = False
    WordWrap = True
  end
  object LstUsers: TListBox
    Left = 16
    Top = 48
    Width = 232
    Height = 369
    ItemHeight = 13
    TabOrder = 3
    OnClick = LstUsersClick
  end
  object EdtSearch: TEdit
    Left = 16
    Top = 16
    Width = 152
    Height = 21
    TabOrder = 0
  end
  object BtnSearch: TButton
    Left = 176
    Top = 14
    Width = 72
    Height = 25
    Caption = 'Buscar'
    TabOrder = 1
    OnClick = BtnSearchClick
  end
  object ChkShowDeleted: TCheckBox
    Left = 16
    Top = 424
    Width = 160
    Height = 17
    Caption = 'Mostrar eliminados'
    TabOrder = 2
    OnClick = ChkShowDeletedClick
  end
  object EdtUsername: TEdit
    Left = 272
    Top = 64
    Width = 200
    Height = 21
    TabOrder = 4
  end
  object EdtDisplayName: TEdit
    Left = 272
    Top = 112
    Width = 200
    Height = 21
    TabOrder = 5
  end
  object EdtEmail: TEdit
    Left = 272
    Top = 160
    Width = 200
    Height = 21
    TabOrder = 6
  end
  object EdtPassword: TEdit
    Left = 272
    Top = 208
    Width = 200
    Height = 21
    PasswordChar = '*'
    TabOrder = 7
  end
  object CmbRole: TComboBox
    Left = 496
    Top = 64
    Width = 160
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    TabOrder = 8
  end
  object ChkActive: TCheckBox
    Left = 496
    Top = 112
    Width = 97
    Height = 17
    Caption = 'Activo'
    TabOrder = 9
  end
  object ChkLocked: TCheckBox
    Left = 496
    Top = 144
    Width = 97
    Height = 17
    Caption = 'Bloqueado'
    TabOrder = 10
  end
  object BtnNew: TButton
    Left = 272
    Top = 256
    Width = 96
    Height = 29
    Caption = 'Crear'
    TabOrder = 11
    OnClick = BtnNewClick
  end
  object BtnSave: TButton
    Left = 376
    Top = 256
    Width = 96
    Height = 29
    Caption = 'Guardar'
    TabOrder = 12
    OnClick = BtnSaveClick
  end
  object BtnPassword: TButton
    Left = 480
    Top = 256
    Width = 120
    Height = 29
    Caption = 'Cambiar contraseña'
    TabOrder = 13
    OnClick = BtnPasswordClick
  end
  object BtnUnlock: TButton
    Left = 272
    Top = 296
    Width = 96
    Height = 29
    Caption = 'Desbloquear'
    TabOrder = 14
    OnClick = BtnUnlockClick
  end
  object BtnDelete: TButton
    Left = 376
    Top = 296
    Width = 96
    Height = 29
    Caption = 'Eliminar'
    TabOrder = 15
    OnClick = BtnDeleteClick
  end
end
