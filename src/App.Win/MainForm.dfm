object FrmMain: TFrmMain
  Left = 192
  Top = 107
  Width = 860
  Height = 520
  Caption = 'Delphi TDD App - FMain'
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
  object PnlSidebar: TPanel
    Left = 0
    Top = 0
    Width = 148
    Height = 493
    Align = alLeft
    BevelOuter = bvNone
    Color = clBtnShadow
    TabOrder = 0
    object BtnDashboard: TButton
      Left = 12
      Top = 16
      Width = 124
      Height = 32
      Caption = 'Dashboard'
      TabOrder = 0
      OnClick = BtnDashboardClick
    end
    object BtnTasks: TButton
      Left = 12
      Top = 56
      Width = 124
      Height = 32
      Caption = 'Tareas'
      TabOrder = 1
      OnClick = BtnTasksClick
    end
    object BtnUsers: TButton
      Left = 12
      Top = 96
      Width = 124
      Height = 32
      Caption = 'Usuarios'
      TabOrder = 2
      OnClick = BtnUsersClick
    end
    object BtnPreferences: TButton
      Left = 12
      Top = 136
      Width = 124
      Height = 32
      Caption = 'Preferencias'
      TabOrder = 3
      OnClick = BtnPreferencesClick
    end
    object BtnAbout: TButton
      Left = 12
      Top = 448
      Width = 124
      Height = 32
      Caption = 'Acerca de'
      TabOrder = 4
      OnClick = BtnAboutClick
    end
  end
  object PnlContent: TPanel
    Left = 148
    Top = 0
    Width = 696
    Height = 493
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
  end
end
