#NoEnv
#SingleInstance force
SetTitleMatchMode, 2
#include ..\lib\UIA_Interface.ahk
#include ..\lib\UIA_Browser.ahk

F5::ExitApp
F1::
	browserExe := "msedge.exe"
	Run, %browserExe% -inprivate --force-renderer-accessibility ; Run in Incognito mode to avoid any extensions interfering. Force accessibility in case its disabled by default.
	WinWaitActive, ahk_exe %browserExe%
	cUIA := new UIA_Browser("ahk_exe " browserExe) ; Initialize UIA_Browser, which also initializes UIA_Interface
	cUIA.WaitPageLoad("New Tab", 5000) ; Wait the New Tab page to load with a timeout of 5 seconds
	cUIA.SetURL("google.com", True) ; Set the URL to google and navigate
	cUIA.WaitPageLoad()
	langBut := cUIA.WaitElementExist("ClassName=neDYw tHlp8d AND ControlType=Button") ; First lets make sure the selected language is correct. First lets get the language menu button using its ClassName
	expandCollapsePattern := langBut.GetCurrentPatternAs("ExpandCollapse") ; Since this isn't a normal button, we need to get the ExpandCollapse pattern for it and then call the correct method.
	if (expandCollapsePattern.CurrentExpandCollapseState == UIA_ExpandCollapseState_Collapsed) ; Check that it is collapsed
		expandCollapsePattern.Expand() ; Expand the menu
	cUIA.WaitElementExist("Name=English AND ControlType=MenuItem").Click() ; Select the English language

	cUIA.WaitElementExistByNameAndType("I agree", UIA_ButtonControlTypeId).Click() ; If the "I agree" button exists, then click it to get rid of the consent form
	searchBox := cUIA.WaitElementExist("Name=Searc AND ControlType=ComboBox",,2) ; Looking for a partial name match "Searc" using matchMode=2. FindFirstByNameAndType is not used here, because if the "I agree" button was clicked then this element might not exist right away, so lets first wait for it to exist.
	searchBox.SetValue("autohotkey forums") ; Set the search box text to "autohotkey forums"
	cUIA.FindFirstByName("Google Search").Click() ; Click the search button to search
	cUIA.WaitPageLoad()
	; Now that the Google search results have loaded, lets scroll the page to the end.
	docEl := cUIA.GetCurrentDocumentElement() ; Get the document element
	sbPat := docEl.GetCurrentPatternAs("Scroll") ; Get the Scroll pattern to access scrolling methods and properties
	hPer := sbPat.CurrentHorizontalScrollPercent ; Horizontal scroll percent doesn't actually interest us, but the SetScrollPercent method requires both horizontal and vertical scroll percents...
	ToolTip, % "Current scroll percent: " sbPat.CurrentVerticalScrollPercent
	for k, v in [10, 20, 30, 40, 50, 60, 70, 80, 90, 100] { ; Lets scroll down in steps of 10%
		sbPat.SetScrollPercent(hPer, v)
		Sleep, 500
		ToolTip, % "Current scroll percent: " sbPat.CurrentVerticalScrollPercent
	}
	Sleep, 3000
	ToolTip
	return
