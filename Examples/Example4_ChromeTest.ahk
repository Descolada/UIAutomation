#Requires AutoHotkey v1.1.33+
#NoEnv
#Warn
#SingleInstance force
SetTitleMatchMode, 2
SetBatchLines, -1
;#include <UIA_Interface> ; Uncomment if you have moved UIA_Interface.ahk to your main Lib folder
#include ..\Lib\UIA_Interface.ahk
;#include <UIA_Browser> ; Uncomment if you have moved UIA_Browser.ahk to your main Lib folder
#include ..\Lib\UIA_Browser.ahk

browserExe := "chrome.exe"
Run, %browserExe% -incognito --force-renderer-accessibility ; Run in Incognito mode to avoid any extensions interfering. Force accessibility in case its disabled by default.
WinWaitActive, ahk_exe %browserExe%
cUIA := new UIA_Browser("ahk_exe " browserExe) ; Initialize UIA_Browser, which also initializes UIA_Interface
Clipboard= ; Clear clipboard
Clipboard := cUIA.GetCurrentDocumentElement().DumpAll() ; Get the current document element (this excludes the URL bar, navigation buttons etc) and dump all the information about it in the clipboard. Use Ctrl+V to paste it somewhere, such as in Notepad.
ClipWait, 1
if Clipboard
	MsgBox, Page information successfully dumped. Use Ctrl+V to paste the info somewhere, such as in Notepad.
else
	MsgBox, Something went wrong and nothing was dumped in the clipboard!
ExitApp
