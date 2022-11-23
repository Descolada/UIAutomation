#NoEnv
#Warn
#SingleInstance force
SetTitleMatchMode, 2

;#include <UIA_Interface> ; Uncomment if you have moved UIA_Interface.ahk to your main Lib folder
#include ..\Lib\UIA_Interface.ahk

UIA := UIA_Interface()
Run, explore C:\
DriveGet, CDriveName, Label, C:
CDriveName := CDriveName " (C:)"
WinWaitActive, %CDriveName%,,1
explorerEl := UIA.ElementFromHandle()
MsgBox, % "Press OK to create a new EventHandler for the StructureChanged event.`nTo test this, interact with the Explorer window, and a tooltip should pop up.`n`nTo exit the script, press F5."
handler := UIA_CreateEventHandler("StructureChangedEventHandler", "StructureChanged")
UIA.AddStructureChangedEventHandler(explorerEl,,, handler)
OnExit("ExitFunc") ; Set up an OnExit call to clean up the handler when exiting the script
return

StructureChangedEventHandler(sender, changeType, runtimeId) {
    try ToolTip, % "Sender: " sender.Dump() 
        . "`nChange type: " changeType
        . "`nRuntime Id: " PrintArray(runtimeId)
	SetTimer, RemoveToolTip, -3000
}

PrintArray(arr) {
	ret := ""
	for k, v in arr
		ret .= "Key: " k " Value: " (IsFunc(v)? v.name:IsObject(v)?PrintArray(v):v) "`n"
	return ret
}

ExitFunc() {
	UIA_Interface().RemoveAllEventHandlers()
}

RemoveToolTip:
	ToolTip
	return

F5::ExitApp
