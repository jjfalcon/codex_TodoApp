#RequireAdmin

#include "Extras\HelpFileInternals.au3"

#include <AutoItConstants.au3>

Example()

Func Example()
	; Run Notepad
	Run("notepad.exe")

	; Wait 10 seconds for the Notepad window to appear.
	Local $hWnd = WinWait("[CLASS:Notepad]", "", 10)

	; Retrieve the control that has keyboard focus in Notepad.
	Local $sEditControl = ControlGetFocus($hWnd)

	; Disable user input from the mouse and keyboard.
	BlockInput($BI_DISABLE)

	; typing have not effect

	; Wait for 2 seconds.
	Sleep(2000)

	; Send the 'F5' key to the edit control of Notepad to display the date and time.
	; The handle returned by WinWait is used for the "title" parameter of ControlSend.
	; the controlSend will be honored even if the BlockInput() is disable
	ControlSend($hWnd, "", $sEditControl, "{F5}")

	; Enable user input from the mouse and keyboard.
	BlockInput($BI_ENABLE)

	; typing has effect

	; Wait for 2 seconds to test if input is enable
	Sleep(4000)

	_NotepadForceClose($hWnd)
EndFunc   ;==>Example
