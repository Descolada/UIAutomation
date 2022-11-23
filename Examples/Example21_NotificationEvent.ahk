#NoEnv
#Warn
#SingleInstance force
SetTitleMatchMode, 2

;#include <UIA_Interface> ; Uncomment if you have moved UIA_Interface.ahk to your main Lib folder
#include ..\Lib\UIA_Interface.ahk

Run, calc.exe
UIA := UIA_Interface() ; Initialize UIA interface
winTitle := "Calculator"
WinWaitActive, %winTitle%
cEl := UIA.ElementFromHandle(winTitle)
MsgBox, % "Press OK to create a new EventHandler for the Notification event.`nTo test this, interact with the Calculator window, and a tooltip should pop up.`n`nTo exit the script, press F5."
handler := UIA_CreateEventHandler("NotificationEventHandler", "Notification")
UIA.AddNotificationEventHandler(cEl,,, handler)
OnExit("ExitFunc") ; Set up an OnExit call to clean up the handler when exiting the script
return

NotificationEventHandler(sender, notificationKind, notificationProcessing, displayString, activityId) {
    ToolTip, % "Sender: " sender.Dump() 
        . "`nNotification kind: " notificationKind " (" UIA_Enum.NotificationKind(notificationKind) ")"
	    . "`nNotification processing: " notificationProcessing " (" UIA_Enum.NotificationProcessing(notificationProcessing) ")"
	    . "`nDisplay string: " displayString
	    . "`nActivity Id: " activityId
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
