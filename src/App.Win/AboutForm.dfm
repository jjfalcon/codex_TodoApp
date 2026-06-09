object FrmAbout: TFrmAbout
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Acerca de'
  ClientHeight = 320
  ClientWidth = 420
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  object LblTitle: TLabel
    Left = 20
    Top = 16
    Width = 380
    Height = 19
    Caption = 'Delphi TDD App'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LblAppName: TLabel
    Left = 20
    Top = 48
    Width = 380
    Height = 13
    Caption = 'Aplicacion Windows'
  end
  object LblVersion: TLabel
    Left = 20
    Top = 68
    Width = 380
    Height = 13
    Caption = 'Version: 1.0.0'
  end
  object LblDescription: TLabel
    Left = 20
    Top = 92
    Width = 380
    Height = 26
    Caption = 'Aplicacion Windows desarrollada en Delphi siguiendo principios TDD.'
    WordWrap = True
  end
  object LblCopyright: TLabel
    Left = 20
    Top = 124
    Width = 380
    Height = 13
    Caption = 'Copyright 2026'
  end
  object LblTechHeader: TLabel
    Left = 20
    Top = 156
    Width = 380
    Height = 13
    Caption = 'Informacion tecnica'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LblExecVersion: TLabel
    Left = 20
    Top = 180
    Width = 380
    Height = 13
    Caption = 'Version del ejecutable: No disponible'
  end
  object LblOS: TLabel
    Left = 20
    Top = 200
    Width = 380
    Height = 13
    Caption = 'Sistema operativo: Windows'
  end
  object LblArch: TLabel
    Left = 20
    Top = 220
    Width = 380
    Height = 13
    Caption = 'Arquitectura: No disponible'
  end
  object LblBuildDate: TLabel
    Left = 20
    Top = 240
    Width = 380
    Height = 13
    Caption = 'Fecha de compilacion: No disponible'
  end
  object LblDbPath: TLabel
    Left = 20
    Top = 260
    Width = 380
    Height = 13
    Caption = 'Base de datos: No disponible'
  end
  object BtnAccept: TButton
    Left = 172
    Top = 288
    Width = 75
    Height = 23
    Caption = 'Aceptar'
    TabOrder = 0
    OnClick = BtnAcceptClick
  end
end
