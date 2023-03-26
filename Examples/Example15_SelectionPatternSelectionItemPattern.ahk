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

selectionPattern := listEl.SelectionPattern ; Getting a pattern this way will get exactly that pattern. By default, GetCurrentPattern() will get the highest pattern available (for example SelectionPattern2 might also be available).
MsgBox, % "SelectionPattern properties: "
	. "`nCurrentCanSelectMultiple: " selectionPattern.CurrentCanSelectMultiple
	. "`nCurrentIsSelectionRequired: " selectionPattern.CurrentIsSelectionRequired

currentSelectionEls := selectionPattern.GetCurrentSelection()
currentSelections := ""
for index,selection in currentSelectionEls
	currentSelections .= index ": " selection.Dump() "`n"

windowsListItem := explorerEl.FindFirstByNameAndType("Windows", "ListItem")
selectionItemPattern := windowsListItem.GetCurrentPatternAs("SelectionItem")
MsgBox, % "ListItemPattern properties for Windows folder list item:"
	. "`nCurrentIsSelected: " selectionItemPattern.CurrentIsSelected
	. "`nCurrentSelectionContainer: " selectionItemPattern.CurrentSelectionContainer.Dump()

MsgBox, % "Press OK to select ""Windows"" folder list item."
selectionItemPattern.Select()
MsgBox, % "Press OK to add to selection ""Program Files"" folder list item."
explorerEl.FindFirstByNameAndType("Program Files", "ListItem").SelectionItemPattern.AddToSelection()
MsgBox, % "Press OK to remove selection from ""Windows"" folder list item."
selectionItemPattern.RemoveFromSelection()

ExitApp
