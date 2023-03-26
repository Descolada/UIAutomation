#Requires AutoHotkey v1.1.33+
#NoEnv
#Warn
#SingleInstance force
SetTitleMatchMode, 2
SetBatchLines, -1

;#include <UIA_Interface> ; Uncomment if you have moved UIA_Interface.ahk to your main Lib folder
#include ..\Lib\UIA_Interface.ahk

Run, notepad.exe
UIA := UIA_Interface() ; Initialize UIA interface
WinWaitActive, ahk_exe notepad.exe
npEl := UIA.ElementFromHandle("ahk_exe notepad.exe") ; Get the element for the Notepad window
documentEl := npEl.FindFirst("Type=Document or Type=Edit") ; Find the first Document/Edit control (in Notepad there is only one). In older Windows builds it's Edit, in newer it's Document.
documentEl.Highlight() ; Highlight the found element
documentEl.Value := "Lorem ipsum" ; Set the value for the document control. 

; This could also be done in one line:
;UIA.ElementFromHandle("ahk_exe notepad.exe").FindFirst("Type=Document or Type=Edit").Highlight().Value := "Lorem ipsum"

; Equivalent ways of setting the value:
; documentEl.CurrentValue := "Lorem ipsum"
; documentEl.SetValue("Lorem ipsum")
ExitApp
