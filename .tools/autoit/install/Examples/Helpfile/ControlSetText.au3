#include "Extras\HelpFileInternals.au3"

#include <MsgBoxConstants.au3>

Example()

Func Example()
	; Run Notepad
	Run("notepad.exe")

	; Wait 10 seconds for the Notepad window to appear.
	Local $hWnd = WinWait("[CLASS:Notepad]", "", 10)

	; Set the edit control in Notepad with some text. The handle returned by WinWait is used for the "title" parameter of ControlSetText.
	ControlSetText($hWnd, "", ControlGetFocus($hWnd), "This is some text")

	; Retrieve the text of the edit control in Notepad. The handle returned by WinWait is used for the "title" parameter of ControlGetText.
	Local $sText = ControlGetText($hWnd, "", ControlGetFocus($hWnd))

	; Display the text of the edit control.
	MsgBox($MB_SYSTEMMODAL, "", "The text in " & ControlGetFocus($hWnd) & " is: " & $sText)

	; Close the Notepad window using the handle returned by WinWait.
	WinClose($hWnd)
EndFunc   ;==>Example
