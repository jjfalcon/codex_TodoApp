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
Global $DetailTitle = "[CLASS:TFrmCrudDetail]"
Global $TaskTitle = "E2E task " & @YEAR & @MON & @MDAY & @HOUR & @MIN & @SEC
Global $TasksFile = $WorkingDir & "\tasks.json"
Global $CsvFile = $WorkingDir & "\tasks-export.csv"
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

    For $I = 1 To 2
        Global $GridHandle = ControlGetHandle($MainTitle, "", "[CLASS:TDBGrid; INSTANCE:" & $I & "]")
        If $GridHandle <> "" Then ConsoleWrite("Grid " & $I & ": " & $GridHandle & @CRLF)
    Next

    Global $CsvDialogTitle = "[TITLE:Exportar CSV]"
    If Not WinExists($CsvDialogTitle) Then $CsvDialogTitle = "[TITLE:Export CSV]"
    If WinExists($CsvDialogTitle) Then
        For $I = 1 To 8
            Global $DialogButtonText = ControlGetText($CsvDialogTitle, "", "[CLASS:Button; INSTANCE:" & $I & "]")
            If @error = 0 Then ConsoleWrite("CSV dialog button " & $I & ": " & $DialogButtonText & @CRLF)
        Next
        For $I = 1 To 4
            Global $DialogEditText = ControlGetText($CsvDialogTitle, "", "[CLASS:Edit; INSTANCE:" & $I & "]")
            If @error = 0 Then ConsoleWrite("CSV dialog edit " & $I & ": " & $DialogEditText & @CRLF)
        Next
    EndIf

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

Func ClickControl($Title, $Control)
    If ControlClick($Title, "", $Control) Then Return True

    Global $Handle = ControlGetHandle($Title, "", $Control)
    If $Handle = "" Then Return False

    If ControlClick($Title, "", $Handle) Then Return True
    If Not ControlFocus($Title, "", $Handle) Then Return False
    Send("{SPACE}")
    Return True
EndFunc

Func ClickDialogButton($Title, $Control)
    If ControlClick($Title, "", $Control) Then Return True

    Global $ControlPos = ControlGetPos($Title, "", $Control)
    Global $WindowPos = WinGetPos($Title)
    If (Not IsArray($ControlPos)) Or (Not IsArray($WindowPos)) Then Return False

    MouseClick("left", $WindowPos[0] + $ControlPos[0] + Int($ControlPos[2] / 2), _
        $WindowPos[1] + $ControlPos[1] + Int($ControlPos[3] / 2), 1, 0)
    Return True
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

Func WaitForFileText($FileName, $Text, $TimeoutSeconds)
    Global $Deadline = TimerInit()
    While TimerDiff($Deadline) < ($TimeoutSeconds * 1000)
        If FileExists($FileName) Then
            Global $Content = FileRead($FileName)
            If StringInStr($Content, $Text) Then Return True
        EndIf
        Sleep(100)
    WEnd
    Return False
EndFunc

Func SaveCsvDialog($FileName)
    Global $DialogTitle = "[TITLE:Exportar CSV]"
    If Not WinWait($DialogTitle, "", 5) Then $DialogTitle = "[TITLE:Export CSV]"
    If Not WinWait($DialogTitle, "", 5) Then Return False

    WinActivate($DialogTitle)
    Global $LastSlash = StringInStr($FileName, "\", 0, -1)
    Global $DialogFileName = $FileName
    If $LastSlash > 0 Then $DialogFileName = StringTrimLeft($FileName, $LastSlash)

    ClipPut($DialogFileName)
    Send("!n")
    Sleep(100)
    Send("^a")
    Send("^v")
    Sleep(100)
    If ControlGetText($DialogTitle, "", "[CLASS:Edit; INSTANCE:1]") = "" Then _
        ControlSetText($DialogTitle, "", "[CLASS:Edit; INSTANCE:1]", $DialogFileName)

    ClickDialogButton($DialogTitle, "[CLASS:Button; INSTANCE:2]")
    Sleep(250)
    If WinExists($DialogTitle) Then Send("!g")
    Sleep(250)
    If WinExists($DialogTitle) Then Send("{ENTER}")
    WinWaitClose($DialogTitle, "", 5)
    Return Not WinExists($DialogTitle)
EndFunc

Func CloseMessageIfOpen()
    Global $MessageTitle = "[TITLE:Delphi TDD App]"
    If WinWait($MessageTitle, "", 1) Then
        WinActivate($MessageTitle)
        Send("{ENTER}")
        WinWaitClose($MessageTitle, "", 3)
    EndIf
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

Global $TskButton = FindButton($MainTitle, "Tareas", "Tasks", "")
If $TskButton = "" Then _
    Fail(16, "Could not find TSK button.")

WinActivate($MainTitle)
If Not ClickControl($MainTitle, $TskButton) Then _
    Fail(16, "Could not click TSK button.")
Sleep(250)

If Not WaitForControl($MainTitle, "[CLASS:TDBGrid; INSTANCE:1]", 5) Then _
    Fail(17, "TSK grid was not shown.")

Global $NewButton = FindButton($MainTitle, "Nuevo", "New", "")
If $NewButton = "" Then _
    Fail(18, "Could not find New task button.")

If Not ClickControl($MainTitle, $NewButton) Then _
    Fail(18, "Could not click New task.")

If Not WinWait($DetailTitle, "", 5) Then _
    Fail(19, "Task detail was not shown for create.")

If Not ControlFocus($DetailTitle, "", "[CLASS:TEdit; INSTANCE:1]") Then _
    Fail(20, "Could not focus task title in detail.")
ControlSetText($DetailTitle, "", "[CLASS:TEdit; INSTANCE:1]", $TaskTitle)

Global $SaveButton = FindButton($DetailTitle, "Guardar", "Save", "")
If $SaveButton = "" Then _
    Fail(21, "Could not find Save button for create.")

If Not ClickControl($DetailTitle, $SaveButton) Then _
    Fail(21, "Could not save new task.")

If Not WaitForFileText($TasksFile, $TaskTitle, 5) Then _
    Fail(22, "Created task was not persisted.")

ControlClick($MainTitle, "", "[CLASS:TDBGrid; INSTANCE:1]", "left", 2, 40, 40)
If Not WinWait($DetailTitle, "", 5) Then _
    Fail(23, "Task detail was not shown for edit.")

ControlCommand($DetailTitle, "", "[CLASS:TCheckBox; INSTANCE:1]", "Check", "")

$SaveButton = FindButton($DetailTitle, "Guardar", "Save", "")
If $SaveButton = "" Then _
    Fail(24, "Could not find Save button for edit.")

If Not ClickControl($DetailTitle, $SaveButton) Then _
    Fail(24, "Could not save completed task.")

If Not WaitForFileText($TasksFile, '"status": "completed"', 5) Then _
    Fail(25, "Completed task was not persisted.")

Global $CsvButton = FindButton($MainTitle, "CSV", "CSV", "")
If $CsvButton = "" Then _
    Fail(26, "Could not find CSV export button.")

If FileExists($CsvFile) Then FileDelete($CsvFile)

If Not ClickControl($MainTitle, $CsvButton) Then _
    Fail(26, "Could not click CSV export button.")

If Not SaveCsvDialog($CsvFile) Then _
    Fail(27, "Could not save CSV export.")

If Not WaitForFileText($CsvFile, $TaskTitle, 5) Then _
    Fail(28, "CSV export did not contain created task.")

If Not WaitForFileText($CsvFile, ";", 5) Then _
    Fail(29, "CSV export did not use semicolon separator.")

CloseMessageIfOpen()

WinClose($MainTitle)
If Not ProcessWaitClose($Pid, 5) Then
    ProcessClose($Pid)
EndIf

ConsoleWrite("Smoke login, task CRUD and CSV export flow passed." & @CRLF)
Exit 0
