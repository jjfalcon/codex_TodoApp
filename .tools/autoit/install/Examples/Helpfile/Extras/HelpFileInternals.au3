#include-once

; to be include to have run notepad script under Win11 with the new notepad.exe

; #INDEX# =======================================================================================================================
; Title .........: GUI Ctrl Extended UDF Library for AutoIt3
; AutoIt Version : 3.3.16.1
; Description ...: Functions that assist display of Registered Events.
; Author(s) .....: jpm
; ===============================================================================================================================

#include <ColorConstants.au3>
#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <SendMessage.au3>
#include <StringConstants.au3>
#include <StructureConstants.au3>
#include <TreeViewConstants.au3>
#include <WindowsStylesConstants.au3>

#Region Global Variables and Constants

; #VARIABLES# ===================================================================================================================
Global $_g_idLst_Memo
Global $_g_hEditMemo
Global $_g_hGuiMemo
Global $_g_iEditOffset
; ===============================================================================================================================

#EndRegion Global Variables and Constants

#Region Functions list

; #EXAMPLE_USE_ONLY# =============================================================================================================
;
; _NotepadForceClose
;
; _Extras_PathFull
;
; _MemoCreate
; _MemoCreateOutProcess
; _MemoWrite
; _MemoSetHandleInProcess
; _MemoGetHandleInProcess
; _MemoReSetHandleInProcess
; _MemoRunAU3OutProcess
; _MemoMsgBoxStatus
; _MemoMsgBox
;
; _GUICtrlTreeView_GetHitString
; _GUICtrlTreeView_GetStateString
; _GUICtrlTreeView_GetItemHandle_
; _GUICtrlTreeView_GetState_
; ===============================================================================================================================

#EndRegion Functions list

; #EXAMPLE_USE_ONLY# =============================================================================================================
; Name ..........: _NotepadForceClose
; Description ...: Close a running Notepad
; Syntax.........: _NotepadForceClose($hWnd, $iWaitTime = 2000)
; Parameters ....: $hWnd      - Notepad Windows Handle
;                  $iWaitTime - Wait time before closing
; Return values .: None
; Author ........: Jpm
; Modified ......:
; Related .......:
; ===============================================================================================================================
Func _NotepadForceClose($hWnd, $iWaitTime = 2000)
	ControlSend($hWnd, "", ControlGetFocus($hWnd), @CRLF & "Will automatically close in " & $iWaitTime / 1000 & " seconds ..." & @CRLF)

	; Wait for 2 seconds by default.
	Sleep($iWaitTime)

	; Ignore Buffer modification
	If @OSBuild >= 22000 Then ;Win11
		Send("^a{DEL}") ; will change the buffer as empty so no popup to confirm modification saving
	Else
		_SendMessage(ControlGetHandle($hWnd, "", "Edit1"), 0xB9, False) ; $EM_SETMODIFY = false
	EndIf

	; Close the Notepad window using the handle returned by WinWait.
	WinClose($hWnd)
EndFunc   ;==>_NotepadForceClose

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _Extras_PathFull
; Description ...: Full path Filename contained in @scriptDir &  "\Extras\"
; Syntax.........: _Extras_PathFull($sFile, $bExit = True)
; Parameters ....: $sFile      - Notepad Windows Handle
;                  $bExit      - True to exit the script execution
; Return values .: Full path of $File contained in @scriptDir &  "\Extras\"
; Author ........: Jpm
; Modified ......:
; Related .......:
; ===============================================================================================================================
Func _Extras_PathFull($sFile, $bExit = True)
	Local $sFullFileName = @ScriptDir & "\Extras\" & $sFile
	If Not FileExists($sFullFileName) Then
		$sFullFileName = StringReplace(@AutoItExe, "autoit3.exe", "Examples\Helpfile") & '\Extras\' & $sFile
		If Not FileExists($sFullFileName) Then
			If $bExit Then
				MsgBox(($MB_ICONERROR + $MB_SYSTEMMODAL), 'Error', @ScriptDir & '\Extras\' & $sFile & ' not found.')
				Exit
			EndIf
			Return ""
		EndIf
	EndIf
	Return $sFullFileName
EndFunc   ;==>_Extras_PathFull

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoCreate
; Description ...: Create an Edit control for _MemoWrite()
; Syntax.........: _MemoCreate($iX = 2, $iY = 2, $iW = 446, $iH = 274, $iStatusOffset = 9, $iStyle = $WS_VSCROLL)
; Parameters ....: $iX, ...       - edit ctrl position, size
;                  $iStatusOffset - Offset of Status label
;                  $iStyle        - Style of the Edit control
; Return values .: None
; Author ........: Jpm
; Modified ......:
; Related .......: _MemoCreateOutProcess
; ===============================================================================================================================
Func _MemoCreate($iX, $iY, $iW, $iH, $iStatusOffset = 0, $iStyle = $WS_VSCROLL)
	; Create memo control
	$_g_iEditOffset = $iStatusOffset
	$_g_idLst_Memo = GUICtrlCreateList("", $iX, $iY, $iW, $iH, $iStyle)
	GUICtrlSetFont(-1, 9, 400, 0, "Courier New")
	_MemoMsgBoxStatus() ; Status creation
EndFunc   ;==>_MemoCreate

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoWrite
; Description ...: Write to the edit control
; Syntax.........: _MemoWrite($sMessage = " ")
; Parameters ....: $sMessage  - message to be write on the edit ctrl
; Return values .: None
; Author ........: Jpm
; Modified ......:
; Related .......: _MemoCreate
; ===============================================================================================================================
Func _MemoWrite($sMessage = " ")
	If StringLeft($sMessage, 2) = @CRLF Then $sMessage = StringTrimLeft($sMessage, 2)
	$sMessage = StringReplace($sMessage, @TAB, "    ")
	Local $aLines = StringSplit($sMessage, @CRLF, 1) ; $STR_ENTIRESPLIT
	If @error Then
		GUICtrlSetData($_g_idLst_Memo, $sMessage & "|")
	Else
		For $i = 1 To $aLines[0]
			GUICtrlSetData($_g_idLst_Memo, $aLines[$i] & "|")
		Next
	EndIf

EndFunc   ;==>_MemoWrite

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoCreateOutProcess
; Description ...: Set handle of an Edit out process
; Syntax.........: _MemoCreateOutProcess($hWin, $iInstance = 1)
; Parameters ....: $hWin      - Handle to outprocess windows
;                  $iInstance - Instance of the Edit control
; Return values .: None
; Author ........: Jpm
; Modified ......:
; Related .......: _MemoWrite
; ===============================================================================================================================
Func _MemoCreateOutProcess($hWin, $sClass, $nAction, $sFromTo)
	Local $sTitle = StringSplit(WinGetTitle($hWin), " v(", $STR_ENTIRESPLIT)[1]
	Local $aPos = WinGetPos($hWin)
	$_g_hGuiMemo = GUICreate($sTitle & $sFromTo, 450, 300, $aPos[2] + 94, 100)
	$_g_idLst_Memo = GUICtrlCreateList("", 2, 8, 444, 259, $WS_VSCROLL)
	GUICtrlSetFont(-1, 9, 400, 0, "Courier New")
	GUISetState(@SW_SHOW)
	If $nAction Then _MemoMsgBox(0, "", "", -$nAction)  ; WinClose("Information", "")

	_MemoMsgBoxStatus()

	Local $hWnd
	For $i = 1 To 3
		$hWnd = ControlGetHandle($hWin, "", "[CLASS:" & $sClass & "; INSTANCE:" & $i & "]")
		If $hWnd Then Return $hWnd
	Next

	Return $hWnd

EndFunc   ;==>_MemoCreateOutProcess

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoSetHandleInProcess
; Description ...: Memorize the Instance of a control
; Syntax.........: _MemoSetHandleInProcess($hWnd)
; Parameters ....: $hWnd    - Handle of a Control
; Return values .: None, @error if the memorization failed
; Author ........: Jpm
; Modified ......:
; Related .......: _MemoSetHandleInProcess
; ===============================================================================================================================
Func _MemoSetHandleInProcess($hWnd)
	RegWrite("HKCU\SOFTWARE\AutoIt v3\Au3Example", "HandleInProcess", "REG_QWORD", $hWnd)
EndFunc   ;==>_MemoSetHandleInProcess

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoGetHandleInProcess
; Description ...: Get the Memorized Instance of a control
; Syntax.........: _MemoGetHandleInProcess()
; Parameters ....: None.
; Return values .: None, @error if the memorization failed
; Author ........: Jpm
; Modified ......:
; Related .......: _MemoSetInstanceInProcess
; ===============================================================================================================================
Func _MemoGetHandleInProcess()
	Local $iRead = RegRead("HKCU\SOFTWARE\AutoIt v3\Au3Example", "HandleInProcess")
	Return SetError(@error, @extended, Ptr($iRead))
EndFunc   ;==>_MemoGetHandleInProcess

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoResetHandleInProcess
; Description ...: Get the Memorized Instance of a control
; Syntax.........: _MemoResetHandleInProcess()
; Parameters ....: $sClass  - Class of the  control
; Return values .: None, @error if the memorization failed
; Author ........: Jpm
; Modified ......:
; Related .......: _MemoSetInstanceInProcess
; ===============================================================================================================================
Func _MemoResetHandleInProcess($hWnd)
	#forceref $hWnd
	Local $iRead = RegRead("HKCU\SOFTWARE\AutoIt v3\Au3Example", "HandleInProcess")
	If @error Or (Ptr($iRead) <> $hWnd) Then Return False
	Return RegDelete("HKCU\SOFTWARE\AutoIt v3\Au3Example", "HandleInProcess")
EndFunc   ;==>_MemoResetHandleInProcess

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoRunAU3OutProcess
; Description ...: Run a process in different mode
; Syntax.........: _MemoRunAU3OutProcess(ByRef $sRetFromTo)
; Parameters ....: $sRetFromTo  - string to illustrate the run process mode
; Return values .: Handle to run window
; Author ........: Jpm
; Modified ......:
; Related .......:
; ===============================================================================================================================
Func _MemoRunAU3OutProcess(ByRef $sFromTo, $bSameMode = False, $sScriptToRun = "")
	Local Static $sAutoItExe
	If $bSameMode Then
		$sFromTo = " (same mode)"
		$sAutoItExe = @AutoItExe
	Else
		If $sAutoItExe = "" Then
			If @AutoItX64 = 0 Then
				$sAutoItExe = StringReplace(@AutoItExe, ".exe", "_x64.exe")
				$sFromTo = " (X86 to X64)"
			Else
				$sAutoItExe = StringReplace(@AutoItExe, "_x64.exe", ".exe")
				$sFromTo = " (X64 to X86)"
			EndIf
			If Not FileExists(@AutoItExe) Then
				$sAutoItExe = @AutoItExe
				$sFromTo = ""
			EndIf
;~ 		$sAutoItExe = @AutoItExe
		EndIf
	EndIf

	Local $sScriptToBeRun
	If $sScriptToRun Then
		$sScriptToBeRun = $sScriptToRun & ".au3"
	Else
		$sScriptToBeRun = StringRegExpReplace(@ScriptName, "\[\d+\]", "")
		If @extended = 0 Then
			MsgBox($MB_ICONERROR, "_MemoRunAU3OutProcess()", "Invalid ScriptName = " & @ScriptName)
			Exit
		EndIf
	EndIf
	Run($sAutoItExe & " " & $sScriptToBeRun) ; launch the external process
	ProcessWait(StringTrimLeft($sAutoItExe, StringInStr($sAutoItExe, "\", 0, -1)))
	Sleep(250) ; so the Script can display the GUI
	Local $hWin = WinWaitActive("[ACTIVE]")
	Return $hWin
EndFunc   ;==>_MemoRunAU3OutProcess

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoMsgBoxStatus
; Description ...: Create/Delete an Status control for _MemoMsgBox()
; Syntax.........: _MemoMsgBoxStatus($sText = "Move the mouse to execute next actions ...", $iY = 272, $hWin = Defult)
; Parameters ....: $sText     - Status Text
;                  $iY        - edit ctrl position
;                  $hWnd      - Handle of a Window to be closed
; Return values .: None
; Author ........: Jpm
; Modified ......:
; Related .......: _MemoMsgBox
; ===============================================================================================================================
Func _MemoMsgBoxStatus($sText = "Move the mouse to execute next actions ...", $iY = Default, $hWin = Default)
	If $iY = Default Then $iY = 266 + 6 + $_g_iEditOffset
	; Status creation
	Local Static $idLbl_Memo = GUICtrlCreateLabel($sText, 10, $iY, 444, 20)
	GUICtrlSetColor($idLbl_Memo, $COLOR_RED)

	If $sText = "" Then
		; no more action, wait GUI for closing, close also OutProcess GUI
		If $iY = -2 Then
			GUICtrlSetData($idLbl_Memo, "Wait GUI closing")
		ElseIf $iY = -1 Then
			GUICtrlSetData($idLbl_Memo, "No more action. Wait GUI closing")
			GUICtrlSetColor($idLbl_Memo, $COLOR_GREEN)
		ElseIf $iY > 0 Then
			GUICtrlSetData($idLbl_Memo, "No more action. Wait GUI closing")
			GUICtrlSetColor($idLbl_Memo, $COLOR_GREEN)
			ToolTip("")
		EndIf

		If $hWin <> Default Then
			; wait GUI for closing
			Do
			Until GUIGetMsg() = $GUI_EVENT_CLOSE

			; close also OutProcess GUI
			WinClose($hWin)
			Exit
		EndIf

	EndIf
EndFunc   ;==>_MemoMsgBoxStatus

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _MemoMsgBox
; Description ...: Replace a MsgBox by a ToolTip
; Syntax.........: _MemoMsgBox($iType, $sTitle, $sText, $iTimeOut = 0)
; Parameters ....: Normal MsgBox parameters
; Return values .: None
; Author ........: Jpm
; Modified ......:
; Related .......:
; ===============================================================================================================================
Func _MemoMsgBox($iType, $sTitle, $sText, $iTimeOut = 0)
	Local $aPos
	If $iTimeOut < 0 Then
		For $i = 1 To -$iTimeOut
			; to execute the tooltip action of an outprocess using _MemoMsgBox()
			$aPos = MouseGetPos()
			MouseMove($aPos[0] + 1, $aPos[1] + 1)
			Sleep(1000)
		Next
		Return
	EndIf

	Local $sError = ""
	If $iType = $MB_ICONERROR Then
		$sError = "Error : "
		Beep(750, 250)
	EndIf
	_MemoWrite(@CRLF & ">>> " & $sError & $sText)
	If $sError Then Return

	If $_g_hGuiMemo Then
		ToolTip($sText, 350 + 450, 300, $sTitle)
		Beep(1200, 125)
	Else
		ToolTip($sText, 350, 300, $sTitle)
		Beep(1000, 125)
	EndIf
	If $iTimeOut Then
		Sleep($iTimeOut * 1000)
	Else
		Local $iPosX = MouseGetPos(0)
		Local $iPosY = MouseGetPos(1)
		Do
			$aPos = MouseGetPos()
		Until $aPos[0] <> $iPosX Or $aPos[1] <> $iPosY
		Sleep(500)
	EndIf
EndFunc   ;==>_MemoMsgBox

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _GUICtrlTreeView_GetHitString
; Description ...: Convert a TreeView Hit Flags to String
; Syntax.........: GUICtrlTreeView_GetHitString($vFlags)
; Parameters ....: $vFlags - Flags to be converted can be a DllStruct
; Return values .: Converted String
; Author ........: Jpm
; Modified ......:
; Related .......:
; ===============================================================================================================================
Func _GUICtrlTreeView_GetHitString($vFlags)
	If IsDllStruct($vFlags) Then
		$vFlags = DllStructGetData($vFlags, "Flags")
	ElseIf $vFlags > $TVHT_ONITEMSTATEICON Then
		$vFlags *= 2 ; numerical value to match $TVHT_*
	EndIf
	Select
		Case BitAND($vFlags, $TVHT_NOWHERE) <> 0
			Return "In the client area, but below the last item"
		Case BitAND($vFlags, $TVHT_ONITEMICON) <> 0
			Return "On the bitmap associated with an item"
		Case BitAND($vFlags, $TVHT_ONITEMLABEL) <> 0
			Return "On the text associated with an item"
		Case BitAND($vFlags, $TVHT_ONITEMINDENT) <> 0
			Return "In the indentation associated with an item"
		Case BitAND($vFlags, $TVHT_ONITEMBUTTON) <> 0
			Return "On the button associated with an item"
		Case BitAND($vFlags, $TVHT_ONITEMRIGHT) <> 0
			Return "In the area to the right of an item"
		Case BitAND($vFlags, $TVHT_ONITEMSTATEICON) <> 0
			Return "On the state icon for a item that is in a user-defined state"
		Case BitAND($vFlags, $TVHT_ABOVE) <> 0
			Return "Above the client area"
		Case BitAND($vFlags, $TVHT_BELOW) <> 0
			Return "Below the client area"
		Case BitAND($vFlags, $TVHT_TORIGHT) <> 0
			Return "To the left of the client area"
		Case BitAND($vFlags, $TVHT_TOLEFT) <> 0
			Return "To the right of the client area"
	EndSelect
EndFunc   ;==>_GUICtrlTreeView_GetHitString

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _GUICtrlTreeView_GetStateString
; Description ...: Convert a TreeView State to String
; Syntax.........: _GUICtrlTreeView_GetStateString($hWnd, $hItem = Null)
; Parameters ....: $hWnd   -
;                  $hItem  -
; Return values .: Converted string
; Author ........: Jpm
; Modified ......:
; Related .......:
; ===============================================================================================================================
Func _GUICtrlTreeView_GetStateString($hWnd, $hItem = Null)
	Local $iState = _GUICtrlTreeView_GetState_($hWnd, $hItem)
	Local $sString = ""

	If BitAND($iState, $TVIS_FOCUSED) Then $sString &= "TVIS_FOCUSED+"
	If BitAND($iState, $TVIS_SELECTED) Then $sString &= "TVIS_SELECTED+"
	If BitAND($iState, $TVIS_CUT) Then $sString &= "TVIS_CUT+"
	If BitAND($iState, $TVIS_DROPHILITED) Then $sString &= "TVIS_DROPHILITED+"
	If BitAND($iState, $TVIS_EXPANDED) Then $sString &= "TVIS_EXPANDED+"
	If BitAND($iState, $TVIS_EXPANDEDONCE) Then $sString &= "TVIS_EXPANDEDONCE+"
	If BitAND($iState, $TVIS_EXPANDPARTIAL) Then $sString &= "TVIS_EXPANDPARTIAL+"
	If BitAND($iState, $TVIS_OVERLAYMASK) Then $sString &= "TVIS_OVERLAYMASK+"
	If BitAND($iState, $TVIS_UNCHECKED) Or BitAND($iState, $TVIS_CHECKED) Then
		If BitAND($iState, $TVIS_UNCHECKED) Then $sString &= "TVIS_UNCHECKED+"
		If BitAND($iState, $TVIS_CHECKED) Then $sString &= "TVIS_CHECKED+"
	Else
		If BitAND($iState, $TVIS_USERMASK) Then $sString &= "TVIS_USERMASK+"
	EndIf

	Return StringTrimRight($sString, 1)
EndFunc   ;==>_GUICtrlTreeView_GetStateString

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _GUICtrlTreeView_GetItemHandle_
; Description ...: Duplicate of _GUICtrlTreeView_GetItemHandle()
; Author ........: Jpm
; Modified ......:
; ===============================================================================================================================
Func _GUICtrlTreeView_GetItemHandle_($hWnd, $hItem = Null)
	If IsHWnd($hWnd) Then
		If $hItem = Null Then $hItem = _SendMessage($hWnd, $TVM_GETNEXTITEM, $TVGN_ROOT, 0, 0, "wparam", "lparam", "handle")
	Else
		If $hItem = Null Then
			$hItem = Ptr(GUICtrlSendMsg($hWnd, $TVM_GETNEXTITEM, $TVGN_ROOT, 0))
		Else
			Local $hTempItem = GUICtrlGetHandle($hItem)
			; Danyfirex discovery:
			; If $hItem is a x64 handle GUICtrlGetHandle will often fail by returning
			; an unknown x64 value (certainly not a handle) instead of 0.
			; IsPtr is used to check if returned value is indeed a valid handle
			If $hTempItem And Not IsPtr($hItem) Then
				$hItem = $hTempItem
			Else
				SetExtended(1)
			EndIf
		EndIf
	EndIf

	Return $hItem
EndFunc   ;==>_GUICtrlTreeView_GetItemHandle_

; #EXAMPLE_USE_ONLY# ===========================================================================================================
; Name ..........: _GUICtrlTreeView_GetState_
; Description ...: Duplicate of _GUICtrlTreeView_GetState()
; Author ........: Jpm
; Modified ......:
; ===============================================================================================================================
Func _GUICtrlTreeView_GetState_($hWnd, $hItem)
	If Not IsHWnd($hItem) Then $hItem = _GUICtrlTreeView_GetItemHandle_($hWnd, $hItem)

	Local $tItem = DllStructCreate($tagTVITEMEX)
	DllStructSetData($tItem, "Mask", $TVIF_STATE)
	DllStructSetData($tItem, "hItem", $hItem)

;~ 	__GUICtrl_SendMsg($hWnd, $TVM_GETITEMA, 0, $tItem)
	If IsHWnd($hWnd) Then
		DllCall("user32.dll", "lresult", "SendMessageW", "hwnd", $hWnd, "uint", $TVM_GETITEMA, "wparam", 0, "struct*", $tItem)
	Else
		GUICtrlSendMsg($hWnd, $TVM_GETITEMA, 0, DllStructGetPtr($tItem))
	EndIf

	Return DllStructGetData($tItem, "State")
EndFunc   ;==>_GUICtrlTreeView_GetState_
