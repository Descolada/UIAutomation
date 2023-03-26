#Requires AutoHotkey v1.1.33+
#SingleInstance, force
#Warn
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetTitleMatchMode, 2
SetBatchLines, -1

;#include <UIA_Interface> ; Uncomment if you have moved UIA_Interface.ahk to your main Lib folder
#include ..\Lib\UIA_Interface.ahk

Run, explore C:\
UIA := UIA_Interface()
WinWaitActive, (C:)
explorerEl := UIA.ElementFromHandle("A")
fileEl := explorerEl.FindFirstByNameAndType("File tab", "Button")
invokePattern := fileEl.InvokePattern
MsgBox, % "Invoke pattern doesn't have any properties. Press OK to call Invoke on the ""File"" button..."
invokePattern.Invoke()

Sleep, 1000
MsgBox, Press OK to navigate to the View tab to test TogglePattern... ; Not part of this demonstration
explorerEl.FindFirstByNameAndType("View", "TabItem").SelectionItemPattern.Select() ; Not part of this demonstration

hiddenItemsCB := explorerEl.FindFirstByNameAndType("Hidden items", "CheckBox")
togglePattern := hiddenItemsCB.TogglePattern
Sleep, 500
MsgBox, % "TogglePattern properties for ""Hidden items"" checkbox: "
	. "`nCurrentToggleState: " togglePattern.CurrentToggleState

MsgBox, % "Press OK to toggle"
togglePattern.Toggle()
Sleep, 500
MsgBox, % "Press OK to toggle again"
togglePattern.Toggle()

; togglePattern.ToggleState := 1 ; CurrentToggleState can also be used to set the state

ExitApp
