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
MsgBox, % npEl.DumpAll() ; Display all the sub-elements for the Notepad window. Press OK to continue
documentEl := npEl.FindFirst("Type=Document or Type=Edit") ; Find the first Document/Edit control (in Notepad there is only one). In older Windows builds it's Edit, in newer it's Document.
documentEl.Value := "Lorem ipsum" ; Set the value of the document control, same as documentEl.SetValue("Lorem ipsum")
MsgBox, Press OK to test saving. ; Wait for the user to press OK
fileEl := npEl.FindFirstByNameAndType("File", "MenuItem") ; Find the "File" menu item
fileEl.Highlight()
fileEl.Click()
saveEl := npEl.WaitElementExistByName("Save",,2) ; Wait for the "Save" menu item to exist
saveEl.Highlight()
saveEl.Click() ; And now click Save
ExitApp

