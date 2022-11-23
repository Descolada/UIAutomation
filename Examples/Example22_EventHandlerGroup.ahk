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

ehGroup := UIA.CreateEventHandlerGroup()
h1 := UIA_CreateEventHandler("AutomationEventHandler")
h2 := UIA_CreateEventHandler("NotificationEventHandler", "Notification")
ehGroup.AddAutomationEventHandler(UIA_Enum.UIA_AutomationFocusChangedEventId,,, h1)
ehGroup.AddNotificationEventHandler(,,h2)
UIA.AddEventHandlerGroup(cEl, ehGroup)

OnExit("ExitFunc") ; Set up an OnExit call to clean up the handler when exiting the script
return

AutomationEventHandler(sender, eventId) {
	ToolTip, % "Sender: " sender.Dump()
		. "`nEvent Id: " eventId
	Sleep, 500
	SetTimer, RemoveToolTip, -3000
}

NotificationEventHandler(sender, notificationKind, notificationProcessing, displayString, activityId) {
    ToolTip, % "Sender: " sender.Dump() 
        . "`nNotification kind: " notificationKind " (" UIA_Enum.NotificationKind(notificationKind) ")"
	    . "`nNotification processing: " notificationProcessing " (" UIA_Enum.NotificationProcessing(notificationProcessing) ")"
	    . "`nDisplay string: " displayString
	    . "`nActivity Id: " activityId
	Sleep, 500
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
