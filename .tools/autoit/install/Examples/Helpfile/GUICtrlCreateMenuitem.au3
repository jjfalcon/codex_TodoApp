#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>
#include <StaticConstants.au3>

Example()

Func Example()
	GUICreate("My GUI menu", 300, 200)

	Local $sStatus = "Ready"

	Local $idMnu_File = GUICtrlCreateMenu("&File")
	Local $idMni_File = GUICtrlCreateMenuItem("Open", $idMnu_File)
	GUICtrlSetState(-1, $GUI_DEFBUTTON)
	Local $idMnu_Help = GUICtrlCreateMenu("?")
	GUICtrlCreateMenuItem("Save", $idMnu_File)
	GUICtrlSetState(-1, $GUI_DISABLE)
	Local $idMni_Info = GUICtrlCreateMenuItem("Info", $idMnu_Help)
	Local $idMni_Exit = GUICtrlCreateMenuItem("Exit", $idMnu_File)
	Local $idMnu_RecentFiles = GUICtrlCreateMenu("Recent Files", $idMnu_File, 1)

	GUICtrlCreateMenuItem("", $idMnu_File, 2) ; Create a separator line

	Local $idMnu_View = GUICtrlCreateMenu("View", -1, 1) ; Is created before "?" menu
	Local $idMni_ViewStatus = GUICtrlCreateMenuItem("Statusbar", $idMnu_View)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlCreateButton("OK", 50, 130, 70, 20)
	GUICtrlSetState(-1, $GUI_FOCUS)
	Local $idBtn_Cancel = GUICtrlCreateButton("Cancel", 180, 130, 70, 20)

	Local $idLbl_Status = GUICtrlCreateLabel($sStatus, 0, 165, 300, 16, BitOR($SS_SIMPLE, $SS_SUNKEN))

	GUISetState(@SW_SHOW)

	Local $sFilePath
	; Loop until the user exits.
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $idBtn_Cancel, $idMni_Exit
				Exit

			Case $idMni_Info
				MsgBox($MB_SYSTEMMODAL, "Info", "Only a test...")

			Case $idMni_File
				$sFilePath = FileOpenDialog("Choose a file...", @TempDir, "All (*.*)")
				If @error Then
					ContinueLoop
				EndIf
				GUICtrlCreateMenuItem($sFilePath, $idMnu_RecentFiles)

			Case $idMni_ViewStatus
				If BitAND(GUICtrlRead($idMni_ViewStatus), $GUI_CHECKED) = $GUI_CHECKED Then
					GUICtrlSetState($idMni_ViewStatus, $GUI_UNCHECKED)
					GUICtrlSetState($idLbl_Status, $GUI_HIDE)
				Else
					GUICtrlSetState($idMni_ViewStatus, $GUI_CHECKED)
					GUICtrlSetState($idLbl_Status, $GUI_SHOW)
				EndIf
		EndSwitch
	WEnd
EndFunc   ;==>Example
