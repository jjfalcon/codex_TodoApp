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
    object LblEditMode: TLabel
      Left = 12
      Top = 15
      Width = 43
      Height = 13
      Caption = 'editMode'
    end
    object CmbEditMode: TComboBox
      Left = 64
      Top = 11
      Width = 128
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
      OnChange = CmbEditModeChange
      Items.Strings = (
        'Sin edicion'
        'Grid'
        'Detalle')
    end
    object BtnSearch: TButton
      Left = 204
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Buscar'
      TabOrder = 2
      OnClick = BtnSearchClick
    end
    object BtnRefresh: TButton
      Left = 292
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Reset'
      TabOrder = 3
      OnClick = BtnRefreshClick
    end
    object BtnPreview: TButton
      Left = 380
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Preview'
      TabOrder = 4
      OnClick = BtnPreviewClick
    end
    object BtnNew: TButton
      Left = 468
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Nuevo'
      TabOrder = 5
      OnClick = BtnNewClick
    end
    object BtnDelete: TButton
      Left = 556
      Top = 10
      Width = 80
      Height = 25
      Caption = 'Eliminar'
      TabOrder = 6
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
