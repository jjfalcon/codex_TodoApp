#include "Extras\HelpFileInternals.au3"

#include <MsgBoxConstants.au3>

Example()

Func Example()
	; Run Notepad
	Run("notepad.exe")

	; Wait 10 seconds for the Notepad window to appear.
	Local $hWnd = WinWait("[CLASS:Notepad]", "", 10)

	; Retrieve the handle of the edit control in Notepad. The handle returned by WinWait is used for the "title" parameter of ControlGetHandle.
	Local $hControl = ControlGetHandle($hWnd, "", ControlGetFocus($hWnd))

	; Display the handle of the edit control.
	MsgBox($MB_SYSTEMMODAL, "", "The handle of " & ControlGetFocus($hWnd) & " is: " & $hControl)

	; Close the Notepad window using the handle returned by WinWait.
	WinClose($hWnd)
EndFunc   ;==>Example
