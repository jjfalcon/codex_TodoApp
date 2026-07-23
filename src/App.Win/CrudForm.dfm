object FrmCrud: TFrmCrud
  Left = 192
  Top = 107
  Width = 696
  Height = 493
  BorderStyle = bsNone
  Caption = 'CRUD'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object PnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 696
    Height = 48
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object EdtSearch: TEdit
      Left = 12
      Top = 12
      Width = 220
      Height = 21
      TabOrder = 0
      Visible = False
    end
    object BtnSearch: TButton
      Left = 240
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Buscar'
      TabOrder = 1
      OnClick = BtnSearchClick
    end
    object BtnRefresh: TButton
      Left = 328
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Reset'
      TabOrder = 2
      OnClick = BtnRefreshClick
    end
    object BtnNew: TButton
      Left = 416
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Nuevo'
      TabOrder = 3
      OnClick = BtnNewClick
    end
    object BtnDelete: TButton
      Left = 504
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Eliminar'
      TabOrder = 4
      OnClick = BtnDeleteClick
    end
  end
  object Grid: TDBGrid
    Left = 0
    Top = 48
    Width = 696
    Height = 445
    Align = alClient
    DataSource = DataSource
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDblClick = GridDblClick
    OnColumnMoved = GridColumnMoved
    OnDrawColumnCell = GridDrawColumnCell
    OnTitleClick = GridTitleClick
  end
  object DataSource: TDataSource
    DataSet = ClientDataSet
    Left = 24
    Top = 72
  end
  object ClientDataSet: TClientDataSet
    Aggregates = <>
    Params = <>
    AfterPost = ClientDataSetAfterPost
    Left = 64
    Top = 72
  end
end
