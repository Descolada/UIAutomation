/*
	Introduction:
	UIA_Browser implements some methods to help automate browsers with UIAutomation framework.

	Initiate new instance of UIA_Browser with
		cUIA := new UIA_Browser(wTitle="A", customNames="", maxVersion="")
			wTitle: the title of the browser
			customNames is currently unused, but may be used to implement language-specific elements
			maxVersion: specifies the highest UIA version that will be used (default is up to version 7).
		Example: cUIA := new UIA_Browser("ahk_exe chrome.exe")
	
	Instances for specific browsers may be initiated with UIA_Chrome, UIA_Edge, UIA_Mozilla (arguments are the same as for UIA_Browser).
	These are usually auto-detected by UIA_Browser, so do not have to be used.

	Available properties for UIA_Browser:
	UIA_Browser can return both UIA_Interface and the browser window elements properties and methods, depending on where the property exists.
		Example: cUIA.CurrentProcessId will return the ProcessId for the browser window element by calling cUIA.BrowserElement.CurrentProcessId.
	UIA
		The UIA_Interface object itself, which can be more readily accessed by just calling a UIA_Interface method/property from UIA_Browser (eg cUIA.CreateNotCondition() will actually call cUIA.UIA.CreateNotCondition())
	BrowserId
		ahk_id of the browser window
	BrowserType
		"Chrome", "Edge", "Mozilla" or "Unknown"
	BrowserElement
		The browser window element, which can also be accessed by just calling an element method from UIA_Browser (cUIA.FindFirst would call FindFirst method on the BrowserElement, is equal to cUIA.BrowserElement.FindFirst)
	MainPaneElement
		Element for the upper part of the browser containing the URL bar, tabs, extensions etc
	URLEditElement
		Element for the address bar
	TWT 
		A UIA TreeWalker that is created with TrueCondition
	All UIA enumerations/constants are also available in the UIA_Browser object. 
		cUIA.UIA_ControlTypePropertyId => returns UIA_ControlTypePropertyId from UIA_Enum, returning value 30003
		cUIA.ButtonControlTypeId => "UIA_" can be omitted. Returns UIA_ButtonControlTypeId from UIA_Enum class, returning value 50000

	UIA_Browser methods:
	UIA_Browser can return both UIA_Interface and the browser window elements properties and methods, depending on where the method exists. 
		Example: cUIA.CreateTreeWalker(condition) accesses the CreateTreeWalker method from UIA_Interface class; cUIA.FindFirst(condition) calls FindFirst on the browser window element (because FindFirst doesn't exist inside UIA_Interface).
	GetCurrentMainPaneElement()
		Refreshes UIA_Browser.MainPaneElement and also returns it
	GetCurrentDocumentElement()
		Returns the current document/content element of the browser. For Mozilla, the tab name which content to get can be specified.
	GetAllText()
		Gets all text from the browser element (CurrentName properties for all child elements)
	GetAllLinks()
		Gets all link elements from the browser (returns an array of elements)
	WaitTitleChange(targetTitle="", timeOut=-1)
		Waits the browser title to change to targetTitle (by default just waits for the title to change), timeOut is in milliseconds (default is indefinite waiting)
	WaitPageLoad(targetTitle="", timeOut=-1, sleepAfter=500, titleMatchMode=3, titleCaseSensitive=True) 
		Waits the browser page to load to targetTitle, default timeOut is indefinite waiting, sleepAfter additionally sleeps for 200ms after the page has loaded. 
	Back()
		Presses the Back button
	Forward()
		Presses the Forward button
	Reload()
		Presses the Reload button
	Home()
		Presses the Home button if it exists. 
	GetCurrentURL(fromAddressBar=False)
		Gets the current URL. fromAddressBar=True gets it straight from the URL bar element, which is not a very good method, because the text might be changed by the user and doesn't start with "http(s)://". Default of fromAddressBar=False will cause the real URL to be fetched, but the browser must be visible for it to work (if is not visible, it will be automatically activated).
	SetURL(newUrl, navigateToNewUrl = False)
		Sets the URL bar to newUrl, optionally also navigates to it if navigateToNewUrl=True
	Navigate(url, targetTitle="", waitLoadTimeOut=-1, sleepAfter=500)
		Navigates to URL and waits page to load
	NewTab()
		Presses the New tab button.
	GetTab(searchPhrase="", matchMode=3, caseSensitive=True)
		Returns a tab element with text of searchPhrase, or if empty then the currently selected tab. matchMode follows SetTitleMatchMode scheme: 1=tab name must must start with tabName; 2=can contain anywhere; 3=exact match; RegEx
	GetTabs(searchPhrase="", matchMode=3, caseSensitive=True)
		Returns all tab elements with text of searchPhrase, or if empty then all tabs. matchMode follows SetTitleMatchMode scheme: 1=tab name must must start with tabName; 2=can contain anywhere; 3=exact match; RegEx
	GetAllTabNames()
		Gets all the titles of tabs
	SelectTab(tabName, matchMode=3, caseSensitive=True) 
		Selects a tab with the text of tabName. matchMode follows SetTitleMatchMode scheme: 1=tab name must must start with tabName; 2=can contain anywhere; 3=exact match; RegEx
	CloseTab(tabElementOrName="", matchMode=3, caseSensitive=True)
		Close tab by either providing the tab element or the name of the tab. If tabElementOrName is left empty, the current tab will be closed.
	IsBrowserVisible()
		Returns True if any of the 4 corners of the browser are visible.
	Send(text)
		Uses ControlSend to send text to the browser.
	GetAlertText()
		Gets the text from an alert box
	CloseAlert()
		Closes an alert box
	JSExecute(js)
		Executes Javascript code using the address bar
	JSReturnThroughClipboard(js)
		Executes Javascript code using the address bar and returns the return value of the code using the clipboard (resetting it back afterwards)
	JSReturnThroughTitle(js, timeOut=500)
		Executes Javascript code using the address bar and returns the return value of the code using the browsers title (resetting it back afterwards). This might be unreliable, so the clipboard method is recommended instead.
	JSSetTitle(newTitle)
		Uses Javascript through the address bar to change the title of the browser
	JSGetElementPos(selector, useRenderWidgetPos=False)
		Uses Javascript's querySelector to get a Javascript element and then its position. useRenderWidgetPos=True uses position of the Chrome_RenderWidgetHostHWND1 control to locate the position element relative to the window, otherwise it uses UIA_Browsers CurrentDocumentElement position.
	JSClickElement(selector)
		Uses Javascript's querySelector to get and click a Javascript element
	ControlClickJSElement(selector, WhichButton="", ClickCount="", Options="", useRenderWidgetPos=False)
		Uses Javascript's querySelector to get a Javascript element and then ControlClicks that position. useRenderWidgetPos=True uses position of the Chrome_RenderWidgetHostHWND1 control to locate the position element relative to the window, otherwise it uses UIA_Browsers CurrentDocumentElement position.
	ClickJSElement(selector, WhichButton="", ClickCount=1, DownOrUp="", Relative="", useRenderWidgetPos=False)
		Uses Javascript's querySelector to get a Javascript element and then Clicks that position. useRenderWidgetPos=True uses position of the Chrome_RenderWidgetHostHWND1 control to locate the position element relative to the window, otherwise it uses UIA_Browsers CurrentDocumentElement position.
*/


/*
	If implementing new browser classes, then necessary methods/properties for main browser functions are:

	this.GetCurrentMainPaneElement() -- fetches MainPaneElement, NavigationBarElement, TabBarElement, URLEditElement 
		// this might be necessary to implement for speed reasons, and is automatically called by InitiateUIA method
	this.GetCurrentDocumentElement() -- fetches Document element for the current page // might be necessary to implement
	this.GetCurrentReloadButton()

	this.MainPaneElement -- element that doesn't contain page content: this element includes URL bar, navigation buttons, setting buttons etc
	this.NavigationBarElement -- smallest element (usually a Toolbar element) that contains the URL bar and navigation buttons
	this.TabBarElement -- contains only tabs
	this.URLEditElement -- the URL bar element
	this.ReloadButton
*/

class UIA_Chrome extends UIA_Browser {
	__New(wTitle:="A", customNames:="", maxVersion:="") {
		this.BrowserType := "Chrome"
		this.InitiateUIA(wTitle, customNames, maxVersion)
	}
	; Refreshes UIA_Browser.MainPaneElement and returns it
	GetCurrentMainPaneElement() { 
		this.BrowserElement.WaitElementExist("ControlType=Document")
		Loop, 2 
		{
			try this.URLEditElement := this.BrowserElement.FindFirstWithOptions(4, this.EditControlCondition, 2)
			try {
				if !this.URLEditElement
					this.URLEditElement := this.UIA.CreateTreeWalker(this.EditControlCondition).GetLastChildElement(this.BrowserElement)
				this.NavigationBarElement := this.UIA.CreateTreeWalker(this.ToolbarControlCondition).GetParentElement(this.URLEditElement)
				this.MainPaneElement := this.TWT.GetParentElement(this.NavigationBarElement)
				if !this.NavigationBarElement
					this.NavigationBarElement := this.BrowserElement
				if !this.MainPaneElement
					this.MainPaneElement := this.BrowserElement
				if !(this.TabBarElement := this.CreateTreeWalker(this.TabControlCondition).GetPreviousSiblingElement(this.NavigationBarElement))
					this.TabBarElement := this.MainPaneElement
				Loop 2 {
					try {
						this.ReloadButton := this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetFirstChildElement(this.NavigationBarElement)))
						this.ReloadButtonDescription := this.ReloadButton.GetCurrentPatternAs("LegacyIAccessible").CurrentDescription
						this.ReloadButtonName := this.ReloadButton.CurrentName
					}
					if (this.ReloadButtonDescription || this.ReloadButtonName)
						break
					Sleep 200
				}
				return this.MainPaneElement
			} catch {
				WinActivate, % "ahk_id " this.BrowserId
				WinWaitActive, % "ahk_id " this.BrowserId,,1
			}
		}
		; If all goes well, this part is not reached
	}
}

class UIA_Edge extends UIA_Browser {
	__New(wTitle:="A", customNames:="", maxVersion:="") {
		this.BrowserType := "Edge"
		this.InitiateUIA(wTitle, customNames, maxVersion)
	}

	; Refreshes UIA_Browser.MainPaneElement and returns it
	GetCurrentMainPaneElement() { 
		local
		this.BrowserElement.WaitElementExist("ControlType=Document")
		Loop, 2 
		{
			try {
				if !(this.URLEditElement := this.BrowserElement.FindFirst(this.EditControlCondition)) {
					this.ToolbarElements := this.BrowserElement.FindAll(this.ToolbarControlCondition), topCoord := 10000000
					for k, v in this.ToolbarElements {
						if ((bT := v.CurrentBoundingRectangle.t) && (bt < topCoord))
							topCoord := bT, this.NavigationBarElement := v
					}
					this.URLEditElement := this.NavigationBarElement.FindFirst(this.EditControlCondition)
					if this.URLEditElement.GetChildren().MaxIndex()
						this.URLEditElement := (el := this.URLEditElement.FindFirst(this.EditControlCondition)) ? el : this.URLEditElement
				} Else {
					this.NavigationBarElement := this.UIA.CreateTreeWalker(this.ToolbarControlCondition).GetParentElement(this.URLEditElement)
				}
				this.MainPaneElement := this.TWT.GetParentElement(this.NavigationBarElement)
				if !this.NavigationBarElement
					this.NavigationBarElement := this.BrowserElement
				if !this.MainPaneElement
					this.MainPaneElement := this.BrowserElement
				if !(this.TabBarElement := this.CreateTreeWalker(this.TabControlCondition).GetPreviousSiblingElement(this.NavigationBarElement))
					this.TabBarElement := this.MainPaneElement
				Loop 2 {
					try {
						this.ReloadButton := this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetFirstChildElement(this.NavigationBarElement)))
						this.ReloadButtonFullDescription := this.ReloadButton.CurrentFullDescription
						this.ReloadButtonName := this.ReloadButton.CurrentName
					}
					if (this.ReloadButtonFullDescription || this.ReloadButtonName)
						break
					Sleep 200
				}
				return this.MainPaneElement
			} catch {
				WinActivate, % "ahk_id " this.BrowserId
				WinWaitActive, % "ahk_id " this.BrowserId,,1
			}
		}
		; If all goes well, this part is not reached
	}
}

class UIA_Mozilla extends UIA_Browser {
	__New(wTitle:="A", customNames:="", maxVersion:="", javascriptFromBookmark:=False) {
		this.BrowserType := "Mozilla"
		this.JavascriptFromBookmark := javascriptFromBookmark
		this.InitiateUIA(wTitle, customNames, maxVersion)
	}
	; Refreshes UIA_Browser.MainPaneElement and returns it
	GetCurrentMainPaneElement() { 
		this.BrowserElement.WaitElementExist("AutomationId=panel",2,2)
		Loop, 2 
		{
			try {
				this.TabBarElement := this.ToolbarTreeWalker.GetNextSiblingElement(this.ToolbarTreeWalker.GetFirstChildElement(this.BrowserElement))
				this.NavigationBarElement := this.ToolbarTreeWalker.GetNextSiblingElement(this.TabBarElement)
				this.URLEditElement := this.NavigationBarElement.FindFirst(this.EditControlCondition)
				this.MainPaneElement := this.TWT.GetParentElement(this.NavigationBarElement)
				if !this.NavigationBarElement
					this.NavigationBarElement := this.BrowserElement
				if !this.MainPaneElement
					this.MainPaneElement := this.BrowserElement
				Loop 2 {
					try {
						this.ReloadButton := this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetFirstChildElement(this.NavigationBarElement)))
						this.ReloadButtonFullDescription := this.ReloadButton.CurrentFullDescription
						this.ReloadButtonName := this.ReloadButton.CurrentName
					}
					if (this.ReloadButtonFullDescription || this.ReloadButtonName)
						break
					Sleep 200
				}	
				return this.MainPaneElement
			} catch {
				WinActivate, % "ahk_id " this.BrowserId
				WinWaitActive, % "ahk_id " this.BrowserId,,1
			}
		}
		; If all goes well, this part is not reached
	}

	; Returns the current document/content element of the browser
	GetCurrentDocumentElement() {
		local
		this.DocumentPanelElement := this.BrowserElement.FindFirstBy("ControlType=Custom AND IsOffscreen=0",2)
		return this.TWT.GetFirstChildElement(this.TWT.GetFirstChildElement(this.DocumentPanelElement))
	}

	; Presses the New tab button. 
	NewTab() { 
		this.TabBarElement.FindFirst(this.ButtonControlCondition,4).Click()
	}

	; Sets the URL bar to newUrl, optionally also navigates to it if navigateToNewUrl=True
	SetURL(newUrl, navigateToNewUrl := False) { 
		this.URLEditElement.SetFocus()
		valuePattern := this.URLEditElement.GetCurrentPatternAs("Value")
		valuePattern.SetValue(newUrl " ")
		if (navigateToNewUrl&&InStr(this.URLEditElement.CurrentValue, newUrl)) {
			ControlFocus, ahk_parent, % "ahk_id" this.BrowserId
			ControlSend, ahk_parent, {LCtrl up}{LAlt up}{LShift up}{RCtrl up}{RAlt up}{RShift up}{Enter}, % "ahk_id" this.BrowserId
		}
	}

	JSExecute(js) {
		local
		if (this.JavascriptFromBookmark) {
			this.SetURL("javascript " js, True)
			return
		}
		ControlFocus, ahk_parent, % "ahk_id" this.BrowserId
		ControlSend, ahk_parent, {LCtrl up}{LAlt up}{LShift up}{RCtrl up}{RAlt up}{RShift up}, % "ahk_id" this.BrowserId
		ControlSend, ahk_parent, {ctrl down}{shift down}k{ctrl up}{shift up}, % "ahk_id" this.BrowserId
		this.GetCurrentDocumentElement()
		this.DocumentPanelElement.WaitElementExistByNameAndType("Switch to multi-line editor mode (Ctrl + B)", "Button")	
		ClipSave := ClipboardAll
		Clipboard := js
		WinActivate, % "ahk_id" this.BrowserId
		WinWaitActive, % "ahk_id" this.BrowserId
		Send, {ctrl down}v{ctrl up}{enter down}{enter up}
		sleep 40
		Send, {ctrl down}{shift down}i{ctrl up}{shift up}
		Clipboard := ClipSave
		Clipsave=
	}

	; Gets text from an alert-box
	GetAlertText(closeAlert:=True, timeOut:=3000) {
		local
		this.GetCurrentDocumentElement()
		startTime := A_TickCount
		alertEl := this.TWT.GetNextSiblingElement(this.TWT.GetFirstChildElement(this.DocumentPanelElement))
		while (!(IsObject(dialogEl := alertEl.FindFirst("AutomationId=commonDialogWindow")) && IsObject(OKBut := dialogEl.FindFirst(this.ButtonControlCondition))) && ((A_tickCount - startTime) < timeOut))
			Sleep, 100
		try text := dialogEl.FindFirst(this.TextControlCondition).CurrentName
		if closeAlert
			try OKBut.Click()
		return text
	}

	CloseAlert() {
		this.GetCurrentDocumentElement()
		try this.TWT.GetNextSiblingElement(this.TWT.GetFirstChildElement(this.DocumentPanelElement)).FindFirst("AutomationId=commonDialogWindow").FindFirst(this.ButtonControlCondition).Click()
	}

	; Close tab by either providing the tab element or the name of the tab. If tabElementOrName is left empty, the current tab will be closed.
	CloseTab(tabElementOrName:="", matchMode:=3, caseSensitive:=True) { 
		if (tabElementOrName != "") {
			if IsObject(tabElementOrName) {
				if (tabElementOrName.CurrentControlType == this.UIA.TabItemControlTypeId)
					tabElementOrName.Click()
			} else {
				try this.TabBarElement.FindFirstByNameAndType(tabElementOrName, "TabItem",, matchMode, caseSensitive).Click()
			}
		}
		ControlSend, ahk_parent, {LCtrl up}{LAlt up}{LShift up}{RCtrl up}{RAlt up}{RShift up}, % "ahk_id " this.BrowserId
		ControlSend, ahk_parent, {Ctrl down}w{Ctrl up}, % "ahk_id " this.BrowserId
	}
}

class UIA_Browser {
	InitiateUIA(wTitle:="A", customNames:="", maxVersion:="") {
		this.BrowserId := WinExist(wTitle)
		if !this.BrowserId
			throw Exception("UIA_Browser: failed to find the browser!", -1)
		this.UIA := UIA_Interface(maxVersion)
		this.TWT := this.UIA.TreeWalkerTrue
		this.CustomNames := (customNames == "") ? {} : customNames
		this.TextControlCondition := this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.TextControlTypeId)
		this.ButtonControlCondition := this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.ButtonControlTypeId)
		this.EditControlCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.EditControlTypeId)
		this.ToolbarControlCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.ToolBarControlTypeId)
		this.TabControlCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.TabControlTypeId)
		this.ToolbarTreeWalker := this.UIA.CreateTreeWalker(this.ToolbarControlCondition)
		this.BrowserElement := this.UIA.ElementFromHandle(this.BrowserId)
		this.GetCurrentMainPaneElement()
	}
	; Initiates UIA and hooks to the browser window specified with wTitle. customNames can be an object that defines custom CurrentName values for locale-specific elements (such as the name of the URL bar): {URLEditName:"My URL Edit name", TabBarName:"Tab bar name", HomeButtonName:"Home button name", StopButtonName:"Stop button", NewTabButtonName:"New tab button name"}. maxVersion specifies the highest UIA version that will be used (default is up to version 7).
	__New(wTitle:="A", customNames:="", maxVersion:="") { 
		local bt
		this.BrowserId := WinExist(wTitle)
		if !this.BrowserId
			throw Exception("UIA_Browser: failed to find the browser!", -1)
		WinGet, wExe, ProcessName, % "ahk_id" this.BrowserId
		WinGetClass, wClass, % "ahk_id" this.BrowserId
		this.BrowserType := (wExe == "chrome.exe") ? "Chrome" : (wExe == "msedge.exe") ? "Edge" : InStr(wClass, "Mozilla") ? "Mozilla" : "Unknown"
		bt := this.BrowserType
		if (bt != "Unknown") {
			this.base := UIA_%bt%
			this.__New(wTitle, customNames, maxVersion)
		} else 
			this.InitiateUIA(wTitle, customNames, maxVersion)
	}
	
	__Get(member) {
		local
		global UIA_Enum
		if member not in base 
		{
			if RegexMatch(member, "PatternId|EventId|PropertyId|AttributeId|ControlTypeId|AnnotationType|StyleId|LandmarkTypeId|HeadingLevel|ChangeId|MetadataId", match) 
				return IsFunc("UIA_Enum.UIA_" match) ? UIA_Enum["UIA_" match](member) : UIA_Enum[match](member)
			else if (SubStr(member,1,1) != "_") {
				try return this.UIA[member]
				try return this.BrowserElement[member]
			}
		}
	}

	__Set(member, value) {
		if (member != "base") {
			if ObjRawGet(this, "UIA")
				try return this.UIA[member] := value
			if ObjRawGet(this, "BrowserElement")
				try return this.BrowserElement[member] := value
		}
	}
	
	__Call(member, params*) {
		local
		if !ObjHasKey(this.base, member) && !ObjHasKey(this.base.base, member) {
			try
				return this.UIA[member].Call(this.UIA, params*)
			catch e {
				if !InStr(e.Message, "Property not supported by the")
					throw Exception(e.Message, -1, e.What)
			}
			try
				return this.BrowserElement[member].Call(this.BrowserElement, params*)
			catch e {
				if !InStr(e.Message, "Property not supported by the")
					throw Exception(e.Message, -1, e.What)
			}
			throw Exception("Method call not supported by " this.__Class " nor UIA_Interface or UIA_Element class or an error was encountered.",-1,member)
		}
	}
	
	; Refreshes UIA_Browser.MainPaneElement and returns it
	GetCurrentMainPaneElement() { 
		this.BrowserElement.WaitElementExist("ControlType=Document")
		; Finding the correct Toolbar ends up to be quite tricky. 
		; In Chrome the toolbar element is located in the tree after the content element, 
		; so if the content contains a toolbar then that will be returned. 
		; Two workarounds I can think of: either look for the Toolbar by name ("Address and search bar" 
		; both in Chrome and edge), or by location (it must be the topmost toolbar). I opted for a 
		; combination of two, so if finding by name fails, all toolbar elements are evaluated.
		Loop, 2 
		{
			try this.URLEditElement := (this.BrowserType = "Chrome") ? this.BrowserElement.FindFirstWithOptions(4, this.EditControlCondition, 2) : this.BrowserElement.FindFirst(this.EditControlCondition)
			try {
				if (this.BrowserType = "Chrome") && !this.URLEditElement
					this.URLEditElement := this.UIA.CreateTreeWalker(this.EditControlCondition).GetLastChildElement(this.BrowserElement)
				this.NavigationBarElement := this.UIA.CreateTreeWalker(this.ToolbarControlCondition).GetParentElement(this.URLEditElement)
				this.MainPaneElement := this.TWT.GetParentElement(this.NavigationBarElement)
				if !this.NavigationBarElement
					this.NavigationBarElement := this.BrowserElement
				if !this.MainPaneElement
					this.MainPaneElement := this.BrowserElement
				;if !(this.TabBarElement := this.BrowserElement.FindFirstByNameAndType(this.CustomNames.TabBarName ? this.CustomNames.TabBarName : "Tab bar", "Tab"))
				if !(this.TabBarElement := this.CreateTreeWalker(this.TabControlCondition).GetPreviousSiblingElement(this.NavigationBarElement))
					this.TabBarElement := this.MainPaneElement
				Loop 2 {
					try {
						this.GetCurrentReloadButton()
						this.ReloadButtonFullDescription := this.ReloadButton.FullDescription
						this.ReloadButtonDescription := this.ReloadButton.GetCurrentPatternAs("LegacyIAccessible").CurrentDescription
						this.ReloadButtonName := this.ReloadButton.CurrentName
					}
					if (this.ReloadButtonFullDescription || this.ReloadButtonName || this.ReloadButtonDescription)
						break
					Sleep 200
				}
				return this.MainPaneElement
			} catch {
				WinActivate, % "ahk_id " this.BrowserId
				WinWaitActive, % "ahk_id " this.BrowserId,,1
			}
		}
		; If all goes well, this part is not reached
	}
	
	; Returns the current document/content element of the browser
	GetCurrentDocumentElement() { 
		if !this.DocumentControlType
			this.DocumentControlType := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.DocumentControlTypeId)
		if (this.BrowserType = "Mozilla")
			return (this.CurrentDocumentElement := this.BrowserElement.FindFirstByNameAndType(this.GetTab().CurrentName, "Document"))
		return (this.CurrentDocumentElement := this.BrowserElement.FindFirst(this.DocumentControlType))
	}

	GetCurrentReloadButton() {
		try CurrentName := this.ReloadButton.CurrentName
		try {
			if this.ReloadButton && CurrentName
				return this.ReloadButton
		}
		ButtonWalker := this.UIA.CreateTreeWalker(this.ButtonControlCondition)
		this.ReloadButton := ButtonWalker.GetNextSiblingElement(ButtonWalker.GetNextSiblingElement(ButtonWalker.GetFirstChildElement(this.NavigationBarElement)))
		return this.ReloadButton
	}
	
	; Uses Javascript to set the title of the browser.
	JSSetTitle(newTitle) {
		this.JSExecute("document.title=""" newTitle """; void(0);")
	}
	
	JSExecute(js) {
		this.SetURL("javascript:" js, True)
	}
	
	JSAlert(js, closeAlert:=True, timeOut:=3000) {
		this.JSExecute("alert(" js ");")
		return this.GetAlertText(closeAlert, timeOut)
	}
	
	; Executes Javascript code through the address bar and returns the return value through the clipboard.
	JSReturnThroughClipboard(js) {
		local
		saveClip := ClipboardAll
		Clipboard=
		this.JSExecute("copyToClipboard(" js ");function copyToClipboard(text) {const elem = document.createElement('textarea');elem.value = text;document.body.appendChild(elem);elem.select();document.execCommand('copy');document.body.removeChild(elem);}")
		ClipWait,2
		returnText := Clipboard
		Clipboard := saveClip
		saveClip=
		return returnText
	}
	
	; Executes Javascript code through the address bar and returns the return value through the browser windows title.
	JSReturnThroughTitle(js, timeOut:=500) {
		local
		WinGetTitle, origTitle, % "ahk_id " this.BrowserId
		this.JSExecute("origTitle=document.title;document.title=(" js ");void(0);setTimeout(function() {document.title=origTitle;void(0);}, " timeOut ")")
		startTime := A_TickCount
		Loop {
			WinGetTitle, newTitle, % "ahk_id " this.BrowserId
			Sleep, 40
		} Until ((origTitle != newTitle) || (A_TickCount - startTime > timeOut))
		return (origTitle == newTitle) ? "" : RegexReplace(newTitle, "(?: - Personal)? - [^-]+$")
	}
	
	; Uses Javascript's querySelector to get a Javascript element and then its position. useRenderWidgetPos=True uses position of the Chrome_RenderWidgetHostHWND1 control to locate the position element relative to the window, otherwise it uses UIA_Browsers CurrentDocumentElement position.
    JSGetElementPos(selector, useRenderWidgetPos:=False) { ; based on code by AHK Forums user william_ahk
		local
        js =
        (LTrim
			(() => {
				let bounds = document.querySelector("%selector%").getBoundingClientRect().toJSON();
				let zoom = window.devicePixelRatio.toFixed(2);
				for (const key in bounds) {
					bounds[key] = bounds[key] * zoom;
				}
				return JSON.stringify(bounds);
			})()
        )
        bounds_str := this.JSReturnThroughClipboard(js)
        RegexMatch(bounds_str, """x"":(\d+).?\d*?,""y"":(\d+).?\d*?,""width"":(\d+).?\d*?,""height"":(\d+).?\d*?", size)
		if useRenderWidgetPos {
			ControlGetPos, win_x, win_y, win_w, win_h, Chrome_RenderWidgetHostHWND1, % "ahk_id " this.BrowserId
			return {x:size1+win_x,y:size2+win_y,w:size3,h:size4}
		} else {
			br := this.GetCurrentDocumentElement().GetCurrentPos("window")
			return {x:size1+br.x,y:size2+br.y,w:size3,h:size4}
		}
    }
	
	; Uses Javascript's querySelector to get and click a Javascript element. Compared with ClickJSElement method, this method has the advantage of skipping the need to wait for a return value from the clipboard, but it might be more unreliable (some elements might not support Javascript's "click()" properly).
	JSClickElement(selector) {
        this.JSExecute("document.querySelector(""" selector """).click();")
	}
    
	; Uses Javascript's querySelector to get a Javascript element and then ControlClicks that position. useRenderWidgetPos=True uses position of the Chrome_RenderWidgetHostHWND1 control to locate the position element relative to the window, otherwise it uses UIA_Browsers CurrentDocumentElement position.
    ControlClickJSElement(selector, WhichButton:="", ClickCount:="", Options:="", useRenderWidgetPos:=False) {
		local
        bounds := this.JSGetElementPos(selector, useRenderWidgetPos)
        ControlClick % "X" (bounds.x + bounds.w // 2) " Y" (bounds.y + bounds.h // 2), % "ahk_id " this.browserId,, % WhichButton, % ClickCount, % Options
    }

	; Uses Javascript's querySelector to get a Javascript element and then Clicks that position. useRenderWidgetPos=True uses position of the Chrome_RenderWidgetHostHWND1 control to locate the position element relative to the window, otherwise it uses UIA_Browsers CurrentDocumentElement position.
    ClickJSElement(selector, WhichButton:="", ClickCount:=1, DownOrUp:="", Relative:="", useRenderWidgetPos:=False) {
		local
        bounds := this.JSGetElementPos(selector, useRenderWidgetPos)
        Click % (bounds.x + bounds.w / 2) " " (bounds.y + bounds.h / 2)" " WhichButton (ClickCount ? " " ClickCount : "") (DownOrUp ? " " DownOrUp : "") (Relative ? " " Relative : "")
    }
	
	; Gets text from an alert-box created with for example javascript:alert('message')
	GetAlertText(closeAlert:=True, timeOut:=3000) {
		local
		if !this.DialogTreeWalker
			this.DialogTreeWalker := this.UIA.CreateTreeWalker(this.CreateOrCondition(this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.CustomControlTypeId), this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.WindowControlTypeId)))
		startTime := A_TickCount
		while (!(IsObject(dialogEl := this.DialogTreeWalker.GetLastChildElement(this.BrowserElement)) && IsObject(OKBut := dialogEl.FindFirst(this.ButtonControlCondition))) && ((A_tickCount - startTime) < timeOut))
			Sleep, 100
		try
			text := this.BrowserType = "Edge" ? dialogEl.FindFirstWithOptions(4, this.TextControlCondition, 2).CurrentName : dialogEl.FindFirst(this.TextControlCondition).CurrentName
		if closeAlert {
			Sleep, 500
			try OKBut.Click()
		}
		return text
	}
	
	CloseAlert() {
		local
		if !this.DialogTreeWalker
			this.DialogTreeWalker := this.UIA.CreateTreeWalker(this.CreateOrCondition(this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.CustomControlTypeId), this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.WindowControlTypeId)))
		try {
			dialogEl := this.DialogTreeWalker.GetLastChildElement(this.BrowserElement)
			OKBut := dialogEl.FindFirst(this.ButtonControlCondition)
			OKBut.Click()
		}
	}
	
	; Gets all text from the browser element (CurrentName properties for all Text elements)
	GetAllText() { 
		local
		if !this.IsBrowserVisible()
			WinActivate, % "ahk_id" this.BrowserId
			
		TextArray := this.BrowserElement.FindAll(this.TextControlCondition)
		Text := ""
		for k, v in TextArray
			Text .= v.CurrentName "`n"
		return Text
	}
	; Gets all link elements from the browser
	GetAllLinks() {
		local
		if !this.IsBrowserVisible()
			WinActivate, % "ahk_id" this.BrowserId			
		LinkCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.HyperlinkControlTypeId)
		return this.BrowserElement.FindAll(LinkCondition)
	}
	
	__CompareTitles(compareTitle, winTitle, matchMode:="", caseSensitive:=True) {
		local
		if !matchMode
			matchMode := A_TitleMatchMode
		if (matchMode == 1) {
			if (caseSensitive ? (SubStr(winTitle, 1, StrLen(compareTitle)) == compareTitle) : (SubStr(winTitle, 1, StrLen(compareTitle)) = compareTitle))
				return 1
		} else if (matchMode == 2) {
			if InStr(winTitle, compareTitle, caseSensitive)
				return 1
		} else if (matchMode == 3) {
			if (caseSensitive ? (compareTitle == winTitle) : (compareTitle = winTitle))
				return 1
		} else if (matchMode = "RegEx") {
			if RegexMatch(winTitle, compareTitle)
				return 1
		}
		return 0
	}
	
	; Waits the browser title to change to targetTitle (by default just waits for the title to change), timeOut is in milliseconds (default is indefinite waiting)
	WaitTitleChange(targetTitle:="", timeOut:=-1) { 
		local
		WinGetTitle, origTitle, % "ahk_id" this.BrowserId
		startTime := A_TickCount, newTitle := origTitle
		while ((((A_TickCount - startTime) < timeOut) || (timeOut = -1)) && (targetTitle ? !this.__CompareTitles(targetTitle, newTitle) : (origTitle == newTitle))) {
			Sleep, 200
			WinGetActiveTitle, newTitle
		}
	}
	
	; Waits the browser page to load to targetTitle, default timeOut is indefinite waiting, sleepAfter additionally sleeps for 200ms after the page has loaded. 
	WaitPageLoad(targetTitle:="", timeOut:=-1, sleepAfter:=500, titleMatchMode:="", titleCaseSensitive:=False) {
		local
		legacyPattern := "", ReloadButtonName := "", ReloadButtonDescription := "", ReloadButtonFullDescription := ""
		Sleep, 200 ; Give some time for the Reload button to change after navigating
		if this.ReloadButtonDescription
			try legacyPattern := this.ReloadButton.GetCurrentPatternAs("LegacyIAccessible")
		startTime := A_TickCount
		while ((A_TickCount - startTime) < timeOut) || (timeOut = -1) {
			if this.BrowserType = "Mozilla"
				this.GetCurrentReloadButton()
			try ReloadButtonName := this.ReloadButton.CurrentName
			try ReloadButtonDescription := legacyPattern.CurrentDescription
			try ReloadButtonFullDescription := this.ReloadButton.CurrentFullDescription
			if ((this.ReloadButtonName ? InStr(ReloadButtonName, this.ReloadButtonName) : 1) 
			   && (this.ReloadButtonDescription ? InStr(ReloadButtonDescription, this.ReloadButtonDescription) : 1)
			   && (this.ReloadButtonFullDescription ? InStr(ReloadButtonFullDescription, this.ReloadButtonFullDescription) : 1)) {
				if targetTitle {
					WinGetTitle, wTitle, % "ahk_id" this.BrowserId
					if this.__CompareTitles(targetTitle, wTitle, titleMatchMode, titleCaseSensitive)
						break
				} else
					break
			}
			Sleep, 40
		}
		if ((A_TickCount - startTime) < timeOut) || (timeOut = -1)
			Sleep, %sleepAfter%
	}
	
	; Presses the Back button
	Back() { 
		this.TWT.GetFirstChildElement(this.NavigationBarElement).Click()
	}
	
	; Presses the Forward button
	Forward() { 
		this.TWT.GetNextSiblingElement(this.TWT.GetFirstChildElement(this.NavigationBarElement)).Click()
	}

	; Presses the Reload button
	Reload() { 
		this.GetCurrentReloadButton().Click()
	}

	; Presses the Home button if it exists.
	Home() { 
		local
		if (this.ReloadButton && (homeBut := this.TWT.GetNextSiblingElement(this.ReloadButton)))
			return homeBut.Click()
		;NameCondition := this.UIA.CreatePropertyCondition(this.UIA.NamePropertyId, this.CustomNames.HomeButtonName ? this.CustomNames.HomeButtonName : butName)
		;this.NavigationBarElement.FindFirst(this.UIA.CreateAndCondition(NameCondition, this.ButtonControlCondition)).Click()
	}
	
	; Gets the current URL. fromAddressBar=True gets it straight from the URL bar element, which is not a very good method, because the text might be changed by the user and doesn't start with "http(s)://". Default of fromAddressBar=False will cause the real URL to be fetched, but the browser must be visible for it to work (if is not visible, it will be automatically activated).
	GetCurrentURL(fromAddressBar:=False) { 
		local
		if fromAddressBar {
			URL := this.URLEditElement.CurrentValue
			return URL ? (RegexMatch(URL, "^https?:\/\/") ? URL : "https://" URL) : ""
		} else {
			; This can be used in Chrome and Edge, but works only if the window is active
			if (!this.IsBrowserVisible() && (this.BrowserType != "Mozilla"))
				WinActivate, % "ahk_id" this.BrowserId
			return this.GetCurrentDocumentElement().CurrentValue
		}
	}
	
	; Sets the URL bar to newUrl, optionally also navigates to it if navigateToNewUrl=True
	SetURL(newUrl, navigateToNewUrl := False) { 
		local
		this.URLEditElement.SetFocus()
		valuePattern := this.URLEditElement.GetCurrentPatternAs("Value")
		valuePattern.SetValue(newUrl " ")
		if !InStr(this.URLEditElement.CurrentValue, newUrl) {
			legacyPattern := this.URLEditElement.GetCurrentPatternAs("LegacyIAccessible")
			legacyPattern.SetValue(newUrl " ")
			legacyPattern.Select()
		}
		if (navigateToNewUrl&&InStr(this.URLEditElement.CurrentValue, newUrl)) {
			if (this.BrowserType = "Mozilla")
				ControlFocus, ahk_parent, % "ahk_id" this.BrowserId
			ControlSend, ahk_parent, {LCtrl up}{LAlt up}{LShift up}{RCtrl up}{RAlt up}{RShift up}{Enter}, % "ahk_id" this.BrowserId ; Or would it be better to use BlockInput instead of releasing modifier keys?
		}
	}

	; Navigates to URL and waits page to load
	Navigate(url, targetTitle:="", waitLoadTimeOut:=-1, sleepAfter:=500) {
		this.SetURL(url, True)
		this.WaitPageLoad(targetTitle,waitLoadTimeOut,sleepAfter)
	}
	
	; Presses the New tab button. The button name might differ if the browser language is not set to English and can be specified with butName
	NewTab() { 
		local
		try el := this.TabBarElement.FindFirstWithOptions(4,this.ButtonControlCondition,2)
		if el
			el.Click()
		else {
			this.UIA.CreateTreeWalker(this.ButtonControlCondition).GetLastChildElement(this.TabBarElement).Click()
		}
		;newTabBut := this.TabBarElement.FindFirstByNameAndType(this.CustomNames.NewTabButtonName ? this.CustomNames.NewTabButtonName : butName, UIA_Enum.UIA_ButtonControlTypeId,,matchMode,caseSensitive)
		;newTabBut.Click()
	}
	
	GetAllTabs() { 
		return this.TabBarElement.FindAll(this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, UIA_Enum.UIA_ControlTypeId("TabItem")))
	}
	; Gets all tab elements matching searchPhrase, matchMode and caseSensitive
	; If searchPhrase is omitted then all tabs will be returned
	GetTabs(searchPhrase:="", matchMode:=3, caseSensitive:=True) {
		return (searchPhrase == "") ? this.TabBarElement.FindAll(this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, UIA_Enum.UIA_ControlTypeId("TabItem"))) : this.TabBarElement.FindAllByNameAndType(searchPhrase, "TabItem",, matchMode, caseSensitive)
	}

	; Gets all the titles of tabs
	GetAllTabNames() { 
		local
		names := []
		for k, v in this.GetTabs() {
			names.Push(v.CurrentName)
		}
		return names
	}
	
	; Returns a tab element with text of searchPhrase, or if empty then the currently selected tab. matchMode follows SetTitleMatchMode scheme: 1=tab name must must start with tabName; 2=can contain anywhere; 3=exact match; RegEx
	GetTab(searchPhrase:="", matchMode:=3, caseSensitive:=True) { 
		return (searchPhrase == "") ? this.TabBarElement.FindFirstBy("ControlType=TabItem AND SelectionItemIsSelected=1") : this.TabBarElement.FindFirstByNameAndType(searchPhrase, "TabItem",, matchMode, caseSensitive)
	}
	
	; Selects a tab with the text of tabName. matchMode follows SetTitleMatchMode scheme: 1=tab name must must start with tabName; 2=can contain anywhere; 3=exact match; RegEx
	SelectTab(tabName, matchMode:=3, caseSensitive:=True) { 
		local
		(selectedTab := this.TabBarElement.FindFirstByNameAndType(tabName, "TabItem",, matchMode, caseSensitive)).Click()
		return selectedTab
	}
	
	; Close tab by either providing the tab element or the name of the tab. If tabElementOrName is left empty, the current tab will be closed.
	CloseTab(tabElementOrName:="", matchMode:=3, caseSensitive:=True) { 
		if IsObject(tabElementOrName) {
			if (tabElementOrName.CurrentControlType == this.UIA.TabItemControlTypeId)
				try this.TWT.GetLastChildElement(tabElementOrName).Click()
		} else {
			if (tabElementOrName == "") {
				try this.TWT.GetLastChildElement(this.GetTab()).Click()
			} else
				try this.TWT.GetLastChildElement(this.TabBarElement.FindFirstByNameAndType(tabElementOrName, "TabItem",, matchMode, caseSensitive)).Click()
		}
	}
	
	; Returns True if any of window 4 corners are visible
	IsBrowserVisible() { 
		local
		WinGetPos, X, Y, W, H, % "ahk_id" this.BrowserId
		if ((this.BrowserId == this.WindowFromPoint(X, Y)) || (this.BrowserId == this.WindowFromPoint(X, Y+H-1)) || (this.BrowserId == this.WindowFromPoint(X+W-1, Y)) || (this.BrowserId == this.WindowFromPoint(X+W-1, Y+H-1)))
			return True
		return False
	}

	Send(text) {
		if (this.BrowserType = "Mozilla")
			ControlFocus, ahk_parent, % "ahk_id" this.BrowserId
		ControlSend, ahk_parent, {LCtrl up}{LAlt up}{LShift up}{RCtrl up}{RAlt up}{RShift up}{Enter}, % "ahk_id" this.BrowserId
		ControlSend, ahk_parent, % text, % "ahk_id" this.BrowserId
	}
	
	WindowFromPoint(X, Y) { ; by SKAN and Linear Spoon
		return DllCall( "GetAncestor", "UInt"
			   , DllCall( "WindowFromPoint", "UInt64", X | (Y << 32))
			   , "UInt", 2 ) ; GA_ROOT
	}

	PrintArray(arr) {
		local
		global UIA_Browser
		ret := ""
		for k, v in arr
			ret .= "Key: " k " Value: " (IsFunc(v)? v.name:IsObject(v)?UIA_Browser.PrintArray(v):v) "`n"
		return ret
	}
}