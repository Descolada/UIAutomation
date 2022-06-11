#NoEnv
#SingleInstance force
SetTitleMatchMode, 2
#include <UIA_Interface>
#include <UIA_Browser>

F5::ExitApp
F1::
	browserExe := "chrome.exe"
	Run, %browserExe% -incognito --force-renderer-accessibility ; Run in Incognito mode to avoid any extensions interfering. Force accessibility in case its disabled by default.
	WinWaitActive, ahk_exe %browserExe%
	cUIA := new UIA_Browser("ahk_exe " browserExe) ; Initialize UIA_Browser, which also initializes UIA_Interface
	cUIA.WaitPageLoad("New Tab", 3000) ; Wait the New Tab page to load with a timeout of 3 seconds
	cUIA.SetURL("https://www.autohotkey.com/boards/ucp.php?mode=login", True) ; Set the URL and navigate to it
	cUIA.WaitPageLoad() ; Wait the page to load
	cUIA.FindFirstBy("Name=Username: AND ControlType=Edit").SetValue("myusername") ; Set the username field to "myusername". Looking for the "Username:" by only the name would not work, because there is also a label control with the same name.
	cUIA.FindFirstBy("Name=Password: AND ControlType=Edit").SetValue("mypassword") ; Set the password field to "mypassword".
	cUIA.FindFirstBy("Name=Remember me AND ControlType=CheckBox").Click() ; Lets remember our login. 
	; cUIA.FindFirstBy("Name=Login AND ControlType=Button").Click() ; Could also click the Login button now
	return
