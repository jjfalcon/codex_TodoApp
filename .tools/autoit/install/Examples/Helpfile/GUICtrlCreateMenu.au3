#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>

Example()

Func Example()
	Local $sDefaultstatus = "Ready"

	GUICreate("My GUI menu", 300, 200)

	Local $idMnu_File = GUICtrlCreateMenu("&File")
	Local $idMni_File = GUICtrlCreateMenuItem("Open", $idMnu_File)
	GUICtrlSetState(-1, $GUI_DEFBUTTON)
	Local $idMnu_Help = GUICtrlCreateMenu("?")
	GUICtrlCreateMenuItem("Save", $idMnu_File)
	GUICtrlSetState(-1, $GUI_DISABLE)
	Local $idMni_Info = GUICtrlCreateMenuItem("Info", $idMnu_Help)
	Local $idMni_Exit = GUICtrlCreateMenuItem("Exit", $idMnu_File)
	Local $idMnu_Recentfiles = GUICtrlCreateMenu("Recent Files", $idMnu_File, 1)

	GUICtrlCreateMenuItem("", $idMnu_File, 2) ; create a separator line

	Local $idMnu_View = GUICtrlCreateMenu("View", -1, 1) ; is created before "?" menu
	Local $idMni_Viewstatus = GUICtrlCreateMenuItem("Statusbar", $idMnu_View)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlCreateButton("OK", 50, 130, 70, 20)
	GUICtrlSetState(-1, $GUI_FOCUS)
	Local $idBtn_Cancel = GUICtrlCreateButton("Cancel", 180, 130, 70, 20)

	Local $idLbl_Status = GUICtrlCreateLabel($sDefaultstatus, 0, 165, 300, 16, BitOR($SS_SIMPLE, $SS_SUNKEN))

	GUISetState(@SW_SHOW)

	Local $sFile
	; Loop until the user exits.
	While 1
		Switch GUIGetMsg()
			Case $idMni_File
				$sFile = FileOpenDialog("Choose file...", @TempDir, "All (*.*)")
				If @error <> 1 Then GUICtrlCreateMenuItem($sFile, $idMnu_Recentfiles)
			Case $idMni_Viewstatus
				If BitAND(GUICtrlRead($idMni_Viewstatus), $GUI_CHECKED) = $GUI_CHECKED Then
					GUICtrlSetState($idMni_Viewstatus, $GUI_UNCHECKED)
					GUICtrlSetState($idLbl_Status, $GUI_HIDE)
				Else
					GUICtrlSetState($idMni_Viewstatus, $GUI_CHECKED)
					GUICtrlSetState($idLbl_Status, $GUI_SHOW)
				EndIf
			Case $GUI_EVENT_CLOSE, $idBtn_Cancel, $idMni_Exit
				ExitLoop
			Case $idMni_Info
				MsgBox($MB_SYSTEMMODAL, "Info", "Only a test...")
		EndSwitch
	WEnd
	GUIDelete()
EndFunc   ;==>Example
