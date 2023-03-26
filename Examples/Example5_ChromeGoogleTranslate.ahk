#Requires AutoHotkey v1.1.33+
#NoEnv
#Warn
#SingleInstance force
SetTitleMatchMode, 2
SetBatchLines, -1
;#include <UIA_Interface> ; Uncomment if you have moved UIA_Interface.ahk to your main Lib folder
#include ..\Lib\UIA_Interface.ahk
;#include <UIA_Browser> ; Uncomment if you have moved UIA_Browser.ahk to your main Lib folder
#include ..\Lib\UIA_Browser.ahk

browserExe := "chrome.exe"
Run, %browserExe% -incognito --force-renderer-accessibility ; Run in Incognito mode to avoid any extensions interfering. Force accessibility in case its disabled by default.
WinWaitActive, ahk_exe %browserExe%
cUIA := new UIA_Browser("ahk_exe " browserExe) ; Initialize UIA_Browser, which also initializes UIA_Interface
cUIA.Navigate("https://www.google.com/preferences#languages") ; Set the URL and navigate to it. WaitPageLoad is not necessary with Navigate.

EnglishEl := cUIA.WaitElementExistByName("English") ; Find the English language radiobutton
EnglishEl.Click() ; Select English
TW := cUIA.CreateTreeWalker(cUIA.CreateCondition("ControlType", "Button")) ; To find the "Save" button, we need to use a TreeWalker to get the next button element from the radiobutton, since "Save" differs between languages
TW.GetNextSiblingElement(EnglishEl).Click(2000) ; Find the "Save" button, click it, and Sleep for 2000ms
cUIA.CloseAlert() ; Sometimes a dialog pops up that confirms the save, in that case press "OK"
cUIA.WaitPageLoad("Google") ; Wait for Google main page to load, default timeout of 10 seconds

cUIA.Navigate("https://translate.google.com/") ; Navigate to Google Translate
cUIA.FindFirstByName("More source languages").Click() ; Click source languages selection
cUIA.WaitElementExistByName("Spanish").Click(500) ; Select Spanish, Sleep for 500ms
cUIA.FindFirstByName("More target languages").Click(500) ; Open target languages selection, Sleep for 500ms
allEnglishEls := cUIA.FindAllByName("English") ; Find all elements with name "English"
allEnglishEls[allEnglishEls.MaxIndex()].Click() ; Select the last element with the name English (because English might also be an option in source languages, in which case it would be found first)

cUIA.WaitElementExistByName("Source text").SetValue("Este es un texto de muestra") ; Set some text to translate
ExitApp
