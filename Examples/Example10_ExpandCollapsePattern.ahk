#SingleInstance, force
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetTitleMatchMode, 2

#include <UIA_Interface>

Run, explore C:\
UIA := UIA_Interface()
WinWaitActive, (C:)
explorerEl := UIA.ElementFromHandle(WinActive("A"))
CDriveEl := explorerEl.FindFirstByNameAndType("Windows (C:)", "TreeItem")
if !CDriveEl {
	MsgBox, Drive C: element not found! Exiting app...
	ExitApp
}

expColPattern := CDriveEl.GetCurrentPatternAs("ExpandCollapse")
Sleep, 500
MsgBox, % "ExpandCollapsePattern properties: "
	. "`nCurrentExpandCollapseState: " (state := expColPattern.CurrentExpandCollapseState) " (" UIA_Enum.ExpandCollapseState(state) ")"

MsgBox, Press OK to expand drive C: element
expColPattern.Expand()
Sleep, 500
MsgBox, Press OK to collapse drive C: element
expColPattern.Collapse()

ExitApp
