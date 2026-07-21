; right click on gui to bring up context Menu.
; right click on the "ok" button to bring up a controll specific context menu.

#include <GUIConstantsEx.au3>
#include <MsgBoxConstants.au3>

Example()

Func Example()
	GUICreate("My GUI Context Menu", 300, 200)

	Local $idContextmenu = GUICtrlCreateContextMenu()

	Local $idMnu_Newsub = GUICtrlCreateMenu("new", $idContextmenu)
	Local $idMni_NewsubmenuText = GUICtrlCreateMenuItem("text", $idMnu_Newsub)

	Local $idButton = GUICtrlCreateButton("OK", 100, 100, 70, 20)
	Local $idCtx_Button = GUICtrlCreateContextMenu($idButton)
	Local $idMni_About = GUICtrlCreateMenuItem("About button", $idCtx_Button)

	Local $idMni_Open = GUICtrlCreateMenuItem("Open", $idContextmenu)
	Local $idMni_Save = GUICtrlCreateMenuItem("Save", $idContextmenu)
	GUICtrlCreateMenuItem("", $idContextmenu) ; separator

	Local $idMni_Info = GUICtrlCreateMenuItem("Info", $idContextmenu)

	GUISetState(@SW_SHOW)

	; Loop until the user exits.
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $idButton
				MsgBox($MB_SYSTEMMODAL, "Button Clicked", 'OK')
			Case $idMni_About
				MsgBox($MB_SYSTEMMODAL, "Menu Selected", 'About')
			Case $idMni_Open
				MsgBox($MB_SYSTEMMODAL, "Menu Selected", 'Open')
			Case $idMni_Save
				MsgBox($MB_SYSTEMMODAL, "Menu Selected", 'Save')
			Case $idMni_Info
				MsgBox($MB_SYSTEMMODAL, "Menu Selected", 'Info')
			Case $idMni_NewsubmenuText
				MsgBox($MB_SYSTEMMODAL, "SubMenu Selected", 'Text')
		EndSwitch
	WEnd
	GUIDelete()
EndFunc   ;==>Example
