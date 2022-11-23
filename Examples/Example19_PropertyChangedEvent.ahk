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
explorerEl := UIA.ElementFromHandle(WinActive("A"))
MsgBox, % "Press OK to create a new EventHandler for the PropertyChanged event (property UIA_NamePropertyId).`nTo test this, click on any file/folder, and a tooltip should pop up.`n`nTo exit the script, press F5."
handler := UIA_CreateEventHandler("PropertyChangedEventHandler", "PropertyChanged")
UIA.AddPropertyChangedEventHandler(explorerEl,0x4,,handler, [UIA_Enum.UIA_NamePropertyId]) ; Multiple properties can be specified in the array
OnExit("ExitFunc") ; Set up an OnExit call to clean up the handler when exiting the script
return

PropertyChangedEventHandler(sender, propertyId, newValue) {
    ToolTip, % "Sender: " sender.Dump() 
        . "`nPropertyId: " propertyId
        . "`nNew value: " newValue
	SetTimer, RemoveToolTip, -3000
}

ExitFunc() {
	UIA_Interface().RemoveAllEventHandlers()
}

RemoveToolTip:
	ToolTip
	return

F5::ExitApp
