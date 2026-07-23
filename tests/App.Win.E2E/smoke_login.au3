Opt("WinTitleMatchMode", 2)
Opt("WinWaitDelay", 100)

If $CmdLine[0] < 2 Then
    ConsoleWrite("Usage: smoke_login.au3 <WindowsApp.exe> <working-dir> [diagnostics-dir]" & @CRLF)
    Exit 2
EndIf

Global $AppExe = $CmdLine[1]
Global $WorkingDir = $CmdLine[2]
Global $DiagnosticsDir = $WorkingDir & "\diagnostics"
If $CmdLine[0] >= 3 Then $DiagnosticsDir = $CmdLine[3]
Global $LoginTitle = "[TITLE:Login]"
Global $MainTitle = "[CLASS:TFrmMain]"
Global $TaskTitle = "E2E task " & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
Global $Pid = Run('"' & $AppExe & '"', $WorkingDir, @SW_SHOW)

If $Pid = 0 Then
    ConsoleWrite("Could not start application." & @CRLF)
    Exit 10
EndIf

Func CaptureScreenshot($Reason)
    If $DiagnosticsDir = "" Then Return
    If Not FileExists($DiagnosticsDir) Then DirCreate($DiagnosticsDir)

    Global $Target = $DiagnosticsDir & "\failure.png"
    Global $Script = $DiagnosticsDir & "\capture-screen.ps1"
    Global $File = FileOpen($Script, 2)
    If $File = -1 Then
        ConsoleWrite("Screenshot could not be prepared: " & $Script & @CRLF)
        Return
    EndIf

    FileWriteLine($File, "Add-Type -AssemblyName System.Windows.Forms")
    FileWriteLine($File, "Add-Type -AssemblyName System.Drawing")
    FileWriteLine($File, "$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds")
    FileWriteLine($File, "$bmp = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height")
    FileWriteLine($File, "$graphics = [System.Drawing.Graphics]::FromImage($bmp)")
    FileWriteLine($File, "$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)")
    FileWriteLine($File, "$bmp.Save('" & $Target & "', [System.Drawing.Imaging.ImageFormat]::Png)")
    FileWriteLine($File, "$graphics.Dispose()")
    FileWriteLine($File, "$bmp.Dispose()")
    FileClose($File)

    If WinExists($MainTitle) Then
        WinActivate($MainTitle)
    ElseIf WinExists($LoginTitle) Then
        WinActivate($LoginTitle)
    EndIf
    Sleep(250)

    RunWait('powershell -NoProfile -ExecutionPolicy Bypass -File "' & $Script & '"', $WorkingDir, @SW_HIDE)
    If FileExists($Target) Then
        ConsoleWrite("Screenshot: " & $Target & @CRLF)
    Else
        ConsoleWrite("Screenshot was not created." & @CRLF)
    EndIf
EndFunc

Func DumpDiagnostics($Reason)
    ConsoleWrite("Diagnostic: " & $Reason & @CRLF)

    Global $Windows = WinList()
    For $I = 1 To $Windows[0][0]
        If WinGetProcess($Windows[$I][1]) = $Pid Then
            ConsoleWrite("Process window: " & $Windows[$I][0] & @CRLF)
            ConsoleWrite("Class list:" & @CRLF & WinGetClassList($Windows[$I][1]) & @CRLF)
        EndIf
    Next

    For $I = 1 To 12
        Global $ButtonText = ControlGetText($MainTitle, "", "[CLASS:TButton; INSTANCE:" & $I & "]")
        If $ButtonText <> "" Then ConsoleWrite("Button " & $I & ": " & $ButtonText & @CRLF)
    Next

    For $I = 1 To 4
        Global $EditText = ControlGetText($MainTitle, "", "[CLASS:TEdit; INSTANCE:" & $I & "]")
        If @error = 0 Then ConsoleWrite("Edit " & $I & ": " & $EditText & @CRLF)
    Next

    Global $Selected = ControlCommand($MainTitle, "", "[CLASS:TListBox; INSTANCE:1]", "GetCurrentSelection", "")
    If @error = 0 Then ConsoleWrite("List current selection: " & $Selected & @CRLF)

    For $I = 1 To 4
        Global $LoginButtonText = ControlGetText($LoginTitle, "", "[CLASS:TButton; INSTANCE:" & $I & "]")
        If $LoginButtonText <> "" Then ConsoleWrite("Login button " & $I & ": " & $LoginButtonText & @CRLF)
    Next

    For $I = 1 To 2
        Global $LoginEditText = ControlGetText($LoginTitle, "", "[CLASS:TEdit; INSTANCE:" & $I & "]")
        If @error = 0 Then ConsoleWrite("Login edit " & $I & ": " & $LoginEditText & @CRLF)
    Next

    For $I = 1 To 4
        Global $LoginLabelText = ControlGetText($LoginTitle, "", "[CLASS:TLabel; INSTANCE:" & $I & "]")
        If $LoginLabelText <> "" Then ConsoleWrite("Login label " & $I & ": " & $LoginLabelText & @CRLF)
    Next
EndFunc

Func Fail($Code, $Message)
    ConsoleWrite($Message & @CRLF)
    CaptureScreenshot($Message)
    DumpDiagnostics($Message)
    ProcessClose($Pid)
    Exit $Code
EndFunc

Func WaitForControl($Title, $Control, $TimeoutSeconds)
    Global $Deadline = TimerInit()
    While TimerDiff($Deadline) < ($TimeoutSeconds * 1000)
        If ControlGetHandle($Title, "", $Control) <> "" Then Return True
        Sleep(100)
    WEnd
    Return False
EndFunc

Func FindLoginButton()
    For $I = 1 To 4
        Global $Text = ControlGetText($LoginTitle, "", "[CLASS:TButton; INSTANCE:" & $I & "]")
        If ($Text = "Entrar") Or ($Text = "Sign in") Then Return "[CLASS:TButton; INSTANCE:" & $I & "]"
    Next
    Return ""
EndFunc

Func FindButton($Title, $Text1, $Text2, $Text3)
    For $I = 1 To 12
        Global $Text = ControlGetText($Title, "", "[CLASS:TButton; INSTANCE:" & $I & "]")
        If ($Text = $Text1) Or ($Text = $Text2) Or ($Text = $Text3) Then Return "[CLASS:TButton; INSTANCE:" & $I & "]"
        If ($Text1 <> "") And StringInStr($Text, $Text1) Then Return "[CLASS:TButton; INSTANCE:" & $I & "]"
        If ($Text2 <> "") And StringInStr($Text, $Text2) Then Return "[CLASS:TButton; INSTANCE:" & $I & "]"
        If ($Text3 <> "") And StringInStr($Text, $Text3) Then Return "[CLASS:TButton; INSTANCE:" & $I & "]"
    Next
    Return ""
EndFunc

If Not WinWait($LoginTitle, "", 10) Then
    ConsoleWrite("Login window was not shown." & @CRLF)
    ProcessClose($Pid)
    Exit 11
EndIf

WinActivate($LoginTitle)

If Not ControlFocus($LoginTitle, "", "[CLASS:TEdit; INSTANCE:1]") Then
    ConsoleWrite("Could not focus username." & @CRLF)
    ProcessClose($Pid)
    Exit 12
EndIf
ControlSetText($LoginTitle, "", "[CLASS:TEdit; INSTANCE:1]", "admin")

If Not ControlFocus($LoginTitle, "", "[CLASS:TEdit; INSTANCE:2]") Then
    ConsoleWrite("Could not focus password." & @CRLF)
    ProcessClose($Pid)
    Exit 13
EndIf
ControlSetText($LoginTitle, "", "[CLASS:TEdit; INSTANCE:2]", "admin")

Global $LoginButton = FindLoginButton()
If $LoginButton = "" Then _
    Fail(14, "Could not find login button.")

If Not ControlClick($LoginTitle, "", $LoginButton) Then _
    Fail(14, "Could not click login button.")

If Not WinWait($MainTitle, "", 10) Then
    Global $Message = ControlGetText($LoginTitle, "", "[CLASS:TLabel; INSTANCE:3]")
    If $Message <> "" Then
        ConsoleWrite("Login message: " & $Message & @CRLF)
    EndIf

    Fail(15, "Main window was not shown after login.")
EndIf

Global $TasksButton = FindButton($MainTitle, "Tareas", "Tasks", "")
If $TasksButton = "" Then _
    Fail(16, "Could not find Tasks button.")

If Not ControlClick($MainTitle, "", $TasksButton) Then _
    Fail(16, "Could not open Tasks screen.")

If Not WaitForControl($MainTitle, "[CLASS:TListBox; INSTANCE:1]", 5) Then _
    Fail(17, "Tasks list was not shown.")

If Not ControlFocus($MainTitle, "", "[CLASS:TEdit; INSTANCE:1]") Then _
    Fail(18, "Could not focus task title.")
For $I = 1 To 4
    ControlSetText($MainTitle, "", "[CLASS:TEdit; INSTANCE:" & $I & "]", $TaskTitle)
Next

Global $AddButton = FindButton($MainTitle, "adir", "Anadir", "Add")
If $AddButton = "" Then _
    Fail(19, "Could not find Add task button.")

If Not ControlClick($MainTitle, "", $AddButton) Then _
    Fail(19, "Could not click Add task.")

Sleep(500)
If ControlCommand($MainTitle, "", "[CLASS:TListBox; INSTANCE:1]", "FindString", "[ ] " & $TaskTitle) < 0 Then _
    Fail(20, "Created task was not listed as pending.")

ControlCommand($MainTitle, "", "[CLASS:TListBox; INSTANCE:1]", "SelectString", "[ ] " & $TaskTitle)
Global $CompleteButton = FindButton($MainTitle, "Completar", "Complete", "")
If $CompleteButton = "" Then _
    Fail(21, "Could not find Complete task button.")

If Not ControlClick($MainTitle, "", $CompleteButton) Then _
    Fail(21, "Could not click Complete task.")

Sleep(500)
If ControlCommand($MainTitle, "", "[CLASS:TListBox; INSTANCE:1]", "FindString", "[x] " & $TaskTitle) < 0 Then _
    Fail(22, "Completed task was not listed with [x] prefix.")

WinClose($MainTitle)
If Not ProcessWaitClose($Pid, 5) Then
    ProcessClose($Pid)
EndIf

ConsoleWrite("Smoke login and task CRUD flow passed." & @CRLF)
Exit 0
