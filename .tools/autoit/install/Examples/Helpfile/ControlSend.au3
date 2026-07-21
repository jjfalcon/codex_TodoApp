#include "Extras\HelpFileInternals.au3"

Example()

Func Example()
	; Run Notepad
	Run("notepad.exe")

	; Wait 10 seconds for the Notepad window to appear.
	Local $hWnd = WinWait("[CLASS:Notepad]", "", 10)

	; Wait for 2 seconds.
	Sleep(2000)

	; Send a string of text to the edit control of Notepad. The handle returned by WinWait is used for the "title" parameter of ControlSend.
	ControlSend($hWnd, "", ControlGetFocus($hWnd), "This is some text")

	_NotepadForceClose($hWnd)
EndFunc   ;==>Example
