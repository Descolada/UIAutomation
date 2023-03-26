#Requires AutoHotkey v1.1.33+
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
WinWaitActive, %CDriveName%,,1
explorerEl := UIA.ElementFromHandle("A")
CDriveEl := explorerEl.FindFirstByNameAndType(CDriveName, "TreeItem")
if !CDriveEl {
	MsgBox, Drive C: element not found! Exiting app...
	ExitApp
}

; expColPattern := CDriveEl.GetCurrentPatternAs("ExpandCollapse") ; Old method
expColPattern := CDriveEl.ExpandCollapsePattern
Sleep, 500
MsgBox, % "ExpandCollapsePattern properties: "
	. "`nCurrentExpandCollapseState: " (state := expColPattern.ExpandCollapseState) " (" UIA_Enum.ExpandCollapseState(state) ")"

MsgBox, Press OK to expand drive C: element
expColPattern.Expand()
Sleep, 500
MsgBox, Press OK to collapse drive C: element
expColPattern.Collapse()

ExitApp
