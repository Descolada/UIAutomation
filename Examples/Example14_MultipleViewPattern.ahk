﻿#Requires AutoHotkey v1.1.33+
#SingleInstance, force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetTitleMatchMode, 2
SetBatchLines, -1

;#include <UIA_Interface> ; Uncomment if you have moved UIA_Interface.ahk to your main Lib folder
#include ..\Lib\UIA_Interface.ahk

Run, explore C:\
UIA := UIA_Interface()
DriveGet, CDriveName, Label, C:
CDriveName := CDriveName " (C:)"
WinWaitActive, %CDriveName%
explorerEl := UIA.ElementFromHandle("A")
listEl := explorerEl.FindFirstByType("List")

mvPattern := listEl.GetCurrentPatternAs("MultipleView")
MsgBox, % "MultipleView properties: "
	. "`nCurrentCurrentView: " (currentView := mvPattern.CurrentCurrentView)

supportedViews := mvPattern.GetCurrentSupportedViews()
viewNames := ""
for _, view in supportedViews {
	viewNames .= mvPattern.GetViewName(view) " (" view ")`n"
}
MsgBox, % "This MultipleView supported views:`n" viewNames
MsgBox, % "Press OK to set MultipleView to view 4."
mvPattern.SetCurrentView(4)

Sleep, 500
MsgBox, % "Press OK to reset back to view " currentView "."
mvPattern.SetCurrentView(currentView)

ExitApp
