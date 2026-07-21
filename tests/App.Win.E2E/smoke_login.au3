Opt("WinTitleMatchMode", 2)
Opt("WinWaitDelay", 100)

If $CmdLine[0] < 2 Then
    ConsoleWrite("Usage: smoke_login.au3 <WindowsApp.exe> <working-dir>" & @CRLF)
    Exit 2
EndIf

Global $AppExe = $CmdLine[1]
Global $WorkingDir = $CmdLine[2]
Global $LoginTitle = "[TITLE:Login]"
Global $MainTitle = "[TITLE:Delphi TDD App - FMain]"
Global $Pid = Run('"' & $AppExe & '"', $WorkingDir, @SW_SHOW)

If $Pid = 0 Then
    ConsoleWrite("Could not start application." & @CRLF)
    Exit 10
EndIf

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
Send("^a")
Send("admin")

If Not ControlFocus($LoginTitle, "", "[CLASS:TEdit; INSTANCE:2]") Then
    ConsoleWrite("Could not focus password." & @CRLF)
    ProcessClose($Pid)
    Exit 13
EndIf
Send("^a")
Send("admin")

Send("{ENTER}")

If Not WinWait($MainTitle, "", 10) Then
    Global $Message = ControlGetText($LoginTitle, "", "[CLASS:TLabel; INSTANCE:3]")
    If $Message <> "" Then
        ConsoleWrite("Login message: " & $Message & @CRLF)
    EndIf

    Global $Windows = WinList()
    For $I = 1 To $Windows[0][0]
        If WinGetProcess($Windows[$I][1]) = $Pid Then
            ConsoleWrite("Process window: " & $Windows[$I][0] & @CRLF)
        EndIf
    Next

    ConsoleWrite("Main window was not shown after login." & @CRLF)
    ProcessClose($Pid)
    Exit 15
EndIf

WinClose($MainTitle)
If Not ProcessWaitClose($Pid, 5) Then
    ProcessClose($Pid)
EndIf

ConsoleWrite("Smoke login passed." & @CRLF)
Exit 0
