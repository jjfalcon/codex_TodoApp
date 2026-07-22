program AppWinVisualTests;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  Graphics,
  Forms,
  LoginForm in '..\..\src\App.Win\LoginForm.pas',
  AppCoreAuth in '..\..\src\App.Core\AppCoreAuth.pas',
  AppCoreClock in '..\..\src\App.Core\AppCoreClock.pas',
  AppCorePreferences in '..\..\src\App.Core\AppCorePreferences.pas',
  AppCoreRepositoryFactory in '..\..\src\App.Core\AppCoreRepositoryFactory.pas',
  AppCoreUser in '..\..\src\App.Core\AppCoreUser.pas',
  AppCoreUserRepository in '..\..\src\App.Core\AppCoreUserRepository.pas',
  AppCoreUserService in '..\..\src\App.Core\AppCoreUserService.pas';

type
  TVisualMode = (vmVerify, vmApprove);

  TFakeAuthService = class(TInterfacedObject, IAuthService)
  public
    function Login(const AUsername, APassword: string): TUser;
    procedure Logout;
  end;

function TFakeAuthService.Login(const AUsername, APassword: string): TUser;
begin
  Result := nil;
end;

procedure TFakeAuthService.Logout;
begin
end;

procedure EnsureDirectory(const APath: string);
begin
  if not DirectoryExists(APath) then
    ForceDirectories(APath);
end;

function ModeFromArgs: TVisualMode;
var
  LMode: string;
begin
  Result := vmVerify;
  if ParamCount > 0 then
  begin
    LMode := LowerCase(ParamStr(1));
    if LMode = 'approve' then
      Result := vmApprove
    else if LMode = 'verify' then
      Result := vmVerify
    else
      raise Exception.Create('Usage: AppWinVisualTests.exe verify|approve');
  end;
end;

procedure CaptureClientArea(AForm: TForm; const AFileName: string);
var
  LBitmap: TBitmap;
  LDC: HDC;
begin
  LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := pf24bit;
    LBitmap.Width := AForm.ClientWidth;
    LBitmap.Height := AForm.ClientHeight;

    LDC := GetDC(AForm.Handle);
    try
      BitBlt(LBitmap.Canvas.Handle, 0, 0, LBitmap.Width, LBitmap.Height, LDC, 0, 0, SRCCOPY);
    finally
      ReleaseDC(AForm.Handle, LDC);
    end;

    LBitmap.SaveToFile(AFileName);
  finally
    LBitmap.Free;
  end;
end;

function ColorDistance(A, B: TColor): Integer;
begin
  A := ColorToRGB(A);
  B := ColorToRGB(B);
  Result := Abs(GetRValue(A) - GetRValue(B)) +
    Abs(GetGValue(A) - GetGValue(B)) +
    Abs(GetBValue(A) - GetBValue(B));
end;

procedure CompareBitmaps(const ABaselineFile, AActualFile, ADiffFile: string);
const
  MaxDifferentPixels = 20;
  MaxColorDistance = 30;
var
  LBaseline: TBitmap;
  LActual: TBitmap;
  LDiff: TBitmap;
  LX: Integer;
  LY: Integer;
  LDifferentPixels: Integer;
  LDistance: Integer;
begin
  LBaseline := TBitmap.Create;
  LActual := TBitmap.Create;
  LDiff := TBitmap.Create;
  try
    LBaseline.LoadFromFile(ABaselineFile);
    LActual.LoadFromFile(AActualFile);

    if (LBaseline.Width <> LActual.Width) or (LBaseline.Height <> LActual.Height) then
      raise Exception.Create('Visual size changed. Expected ' + IntToStr(LBaseline.Width) + 'x' +
        IntToStr(LBaseline.Height) + ', got ' + IntToStr(LActual.Width) + 'x' +
        IntToStr(LActual.Height) + '.');

    LDiff.PixelFormat := pf24bit;
    LDiff.Width := LActual.Width;
    LDiff.Height := LActual.Height;
    LDiff.Canvas.Draw(0, 0, LActual);

    LDifferentPixels := 0;
    for LY := 0 to LActual.Height - 1 do
      for LX := 0 to LActual.Width - 1 do
      begin
        LDistance := ColorDistance(LBaseline.Canvas.Pixels[LX, LY], LActual.Canvas.Pixels[LX, LY]);
        if LDistance > MaxColorDistance then
        begin
          Inc(LDifferentPixels);
          LDiff.Canvas.Pixels[LX, LY] := clRed;
        end;
      end;

    if LDifferentPixels > 0 then
      LDiff.SaveToFile(ADiffFile);

    if LDifferentPixels > MaxDifferentPixels then
      raise Exception.Create('Visual difference too high: ' + IntToStr(LDifferentPixels) +
        ' pixels differ. Diff: ' + ADiffFile);
  finally
    LDiff.Free;
    LActual.Free;
    LBaseline.Free;
  end;
end;

procedure RunLoginFormVisualTest(AMode: TVisualMode);
var
  LForm: TFrmLogin;
  LBaseDir: string;
  LActualDir: string;
  LDiffDir: string;
  LBaselineFile: string;
  LActualFile: string;
  LDiffFile: string;
begin
  LBaseDir := ExtractFilePath(ParamStr(0)) + 'baselines\';
  LActualDir := ExtractFilePath(ParamStr(0)) + 'actual\';
  LDiffDir := ExtractFilePath(ParamStr(0)) + 'diff\';

  EnsureDirectory(LBaseDir);
  EnsureDirectory(LActualDir);
  EnsureDirectory(LDiffDir);

  LBaselineFile := LBaseDir + 'LoginForm.bmp';
  LActualFile := LActualDir + 'LoginForm.bmp';
  LDiffFile := LDiffDir + 'LoginForm.diff.bmp';

  LForm := TFrmLogin.Create(nil);
  try
    LForm.ConfigureForTests(TFakeAuthService.Create);
    LForm.Position := poDesigned;
    LForm.Left := 0;
    LForm.Top := 0;
    LForm.Show;
    Application.ProcessMessages;

    CaptureClientArea(LForm, LActualFile);
  finally
    LForm.Free;
  end;

  if AMode = vmApprove then
  begin
    CopyFile(PChar(LActualFile), PChar(LBaselineFile), False);
    Writeln('[APPROVED] LoginForm baseline updated: ', LBaselineFile);
  end
  else
  begin
    if not FileExists(LBaselineFile) then
      raise Exception.Create('Missing baseline: ' + LBaselineFile + '. Run approve first.');

    CompareBitmaps(LBaselineFile, LActualFile, LDiffFile);
    Writeln('[OK] LoginForm visual baseline matches.');
  end;
end;

begin
  try
    Application.Initialize;
    RunLoginFormVisualTest(ModeFromArgs);
    Writeln('All visual tests passed.');
  except
    on E: Exception do
    begin
      Writeln('[FAIL] ', E.Message);
      Halt(1);
    end;
  end;
end.
