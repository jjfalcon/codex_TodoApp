#include "Extras\HelpFileInternals.au3"

Example()

Func Example()
	; Run Notepad
	Run("notepad.exe")

	; Wait 10 seconds for the Notepad window to appear.
	Local $hWnd = WinWait("[CLASS:Notepad]", "", 10)

	; Set input focus to the edit control of Notepad using the handle returned by WinWait.
	ControlFocus($hWnd, "", ControlGetFocus($hWnd))

	; Wait for 2 seconds.
	Sleep(2000)

	; Close the Notepad window using the handle returned by WinWait.
	WinClose($hWnd)
EndFunc   ;==>Example
