object FrmMain: TFrmMain
  Left = 192
  Top = 107
  Width = 720
  Height = 420
  Caption = 'Delphi TDD App'
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
  object PnlTop: TPanel
    Left = 0
    Top = 0
    Width = 704
    Height = 56
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object EdtTitle: TEdit
      Left = 12
      Top = 16
      Width = 280
      Height = 21
      TabOrder = 0
    end
    object BtnAdd: TButton
      Left = 300
      Top = 14
      Width = 90
      Height = 25
      Caption = 'Anadir'
      TabOrder = 1
      OnClick = BtnAddClick
    end
    object EdtSearch: TEdit
      Left = 420
      Top = 16
      Width = 180
      Height = 21
      TabOrder = 2
    end
    object BtnSearch: TButton
      Left = 608
      Top = 14
      Width = 90
      Height = 25
      Caption = 'Buscar'
      TabOrder = 3
      OnClick = BtnSearchClick
    end
  end
  object LstTasks: TListBox
    Left = 0
    Top = 56
    Width = 704
    Height = 288
    Align = alClient
    ItemHeight = 13
    TabOrder = 1
  end
  object PnlBottom: TPanel
    Left = 0
    Top = 344
    Width = 704
    Height = 48
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object BtnComplete: TButton
      Left = 12
      Top = 12
      Width = 110
      Height = 25
      Caption = 'Completar'
      TabOrder = 0
      OnClick = BtnCompleteClick
    end
    object BtnDelete: TButton
      Left = 132
      Top = 12
      Width = 90
      Height = 25
      Caption = 'Eliminar'
      TabOrder = 1
      OnClick = BtnDeleteClick
    end
    object BtnRefresh: TButton
      Left = 232
      Top = 12
      Width = 90
      Height = 25
      Caption = 'Refrescar'
      TabOrder = 2
      OnClick = BtnRefreshClick
    end
  end
end
