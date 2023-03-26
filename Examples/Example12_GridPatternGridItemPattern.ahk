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
WinWaitActive, %CDriveName%
explorerEl := UIA.ElementFromHandle("A")
listEl := explorerEl.FindFirstByType("List")

gridPattern := listEl.GridPattern
Sleep, 500
MsgBox, % "GridPattern properties: "
	. "`nCurrentRowCount: " gridPattern.RowCount
	. "`nCurrentColumnCount: " gridPattern.ColumnCount

MsgBox, % "Getting grid item from row 4, column 1 (0-based indexing)"
editEl := gridPattern.GetItem(3,0)
MsgBox, % "Got this element: `n" editEl.Dump()

gridItemPattern := editEl.GridItemPattern
MsgBox, % "GridItemPattern properties: "
	. "`nCurrentRow: " gridItemPattern.Row
	. "`nCurrentColumn: " gridItemPattern.Column
	. "`nCurrentRowSpan: " gridItemPattern.RowSpan
	. "`nCurrentColumnSpan: " gridItemPattern.ColumnSpan
	; gridItemPattern.CurrentContainingGrid should return listEl

ExitApp
