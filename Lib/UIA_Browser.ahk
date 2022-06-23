
class UIA_Browser {
	__New(wTitle="A", maxVersion="") {
		this.UIA := UIA_Interface(maxVersion)
		this.TWT := this.UIA.TreeWalkerTrue
		this.ControlCache := this.UIA.CreateCacheRequest()
		this.ControlCache.SetTreeScope(0x4)
		this.ControlCache.AddProperty(this.UIA.ControlTypePropertyId)
		
		this.TextCondition := this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.TextControlTypeId)
		this.ButtonCondition := this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.ButtonControlTypeId)
		
		this.BrowserElement := this.UIA.ElementFromHandle(this.BrowserId := WinExist(wTitle), True)
		if this.BrowserId {
			WinGet, wExe, ProcessName, % "ahk_id" this.BrowserId
			this.BrowserType := (wExe == "chrome.exe") ? "Chrome" : (wExe == "msedge.exe") ? "Edge" : "Unknown"
			this.GetCurrentMainPaneElement()
		}
	}
	
	__Get(member) {
		if member not in base 
		{
			if RegexMatch(member, "PatternId|EventId|PropertyId|AttributeId|ControlTypeId|AnnotationType|StyleId|LandmarkTypeId|HeadingLevel|ChangeId|MetadataId", match) 
				return IsFunc("UIA_Enum.UIA_" match) ? UIA_Enum["UIA_" match](member) : UIA_Enum[match](member)
			else if (SubStr(member,1,1) != "_") {
				try
					return this.UIA[member]
				try
					return this.BrowserElement[member]
			}
		}
	}
	
	__Call(member, params*) {
		if !ObjHasKey(this.base, member) {
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
	
	GetCurrentMainPaneElement() { ; Refreshes UIA_Browser.MainPaneElement and also returns it
		static EditControlCondition, EditNameCondition, EditAndCondition, ToolbarControlCondition
		if !EditControlCondition
			EditControlCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.EditControlTypeId), EditNameCondition := this.UIA.CreateOrCondition(this.UIA.CreatePropertyCondition(this.UIA.NamePropertyId, "Address and search bar"), this.UIA.CreatePropertyCondition(this.UIA.NamePropertyId, "Search or enter an address")), EditAndCondition := this.UIA.CreateAndCondition(EditControlCondition, EditNameCondition), ToolbarControlCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.ToolBarControlTypeId)
		; Finding the correct Toolbar ends up to be quite tricky. In Chrome the toolbar element is located in the tree after the content element, so if the content contains a toolbar then that will be returned. Two workarounds I can think of: either look for the Toolbar by name ("Address and search bar" both in Chrome and edge), or by location (it must be the topmost toolbar). I opted for a combination of two, so if finding by name fails, all toolbar elements are evaluated.
		if !(this.URLEditElement := this.BrowserElement.FindFirst(EditAndCondition)) {	
			this.ToolbarElements := this.BrowserElement.FindAll(ToolbarControlCondition), topCoord := 10000000
			for k, v in this.ToolbarElements {
				if ((bT := v.CurrentBoundingRectangle.t) && (bt < topCoord))
					topCoord := bT, this.NavigationBarElement := v
			}
			this.URLEditElement := this.NavigationBarElement.FindFirst(EditControlCondition)
		} Else {
			this.NavigationBarElement := this.UIA.CreateTreeWalker(ToolbarControlCondition).GetParentElement(this.URLEditElement)
		}
		
		return this.MainPaneElement := this.TWT.GetParentElement(this.NavigationBarElement)
	}
	
	GetCurrentDocumentElement() { ; Returns the current document/content element of the browser
		static docType
		if !docType
			docType := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.DocumentControlTypeId)
		return this.BrowserElement.FindFirst(docType)
	}
	
	JSSetTitle(newTitle) {
		this.SetURL("javascriptdocument.title=""" js """; void(0);", True)
	}
	
	JSExecute(js) {
		this.SetURL("javascript:" js, True)
	}
	
	JSAlert(js, closeAlert=True, timeOut=3000) {
		this.SetURL("javascript:alert(" js ");", True)
		return this.GetAlertText(closeAlert, timeOut)
	}
	
	JSReturnThroughClipboard(js) {
		saveClip := ClipboardAll
		Clipboard=
		this.SetURL("javascript:copyToClipboard(" js ");function copyToClipboard(text) {const elem = document.createElement('textarea');elem.value = text;document.body.appendChild(elem);elem.select();document.execCommand('copy');document.body.removeChild(elem);}", True)
		ClipWait,2
		returnText := Clipboard
		Clipboard := saveClip
		saveClip=
		return returnText
	}
	
	JSReturnThroughTitle(js, timeOut=500) {
		WinGetTitle, origTitle, % "ahk_id " this.BrowserId
		this.SetURL("javascript:origTitle=document.title;document.title=(" js ");void(0);setTimeout(function() {document.title=origTitle;void(0);}, " timeOut ")", True)
		startTime := A_TickCount
		Loop {
			WinGetTitle, newTitle, % "ahk_id " this.BrowserId
			Sleep, 40
		} Until ((origTitle != newTitle) || (A_TickCount - startTime > timeOut))
		return (origTitle == newTitle) ? "" : RegexReplace(newTitle, "(?: - Personal)? - [^-]+$")
	}
	
	GetAlertText(closeAlert=True, timeOut=3000) {
		static DialogCondition, DialogTW
		if !IsObject(DialogCondition)
			DialogCondition := this.CreateOrCondition(this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.CustomControlTypeId), this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.WindowControlTypeId)), DialogTW := this.UIA.CreateTreeWalker(DialogCondition)
		startTime := A_TickCount
		while (!(IsObject(dialogEl := DialogTW.GetLastChildElement(this.BrowserElement)) && IsObject(OKBut := dialogEl.FindFirst(this.ButtonCondition))) && ((A_tickCount - startTime) < timeOut))
			Sleep, 100

		try
			text := dialogEl.FindFirst(this.TextCondition).CurrentName
		if closeAlert {
			Sleep, 500
			try OKBut.Click()
		}
		return text
	}
	
	CloseAlert() {
		static DialogCondition, DialogTW
		if !IsObject(DialogCondition)
			DialogCondition := this.CreateOrCondition(this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.CustomControlTypeId), this.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.WindowControlTypeId)), DialogTW := this.UIA.CreateTreeWalker(DialogCondition)
		try {
			dialogEl := DialogTW.GetLastChildElement(this.BrowserElement)
			OKBut := dialogEl.FindFirst(this.ButtonCondition)
			OKBut.Click()
		}
	}
	
	GetAllText() { ; Gets all text from the browser element (CurrentName properties for all child elements)
		if !this.IsBrowserVisible()
			WinActivate, % "ahk_id" this.BrowserId
			
		TextArray := this.BrowserElement.FindAll(this.TextCondition)
		Text := ""
		for k, v in TextArray
			Text .= v.CurrentName "`n"
		return Text
	}

	GetAllLinks() { ; Gets all link elements from the browser
		if !this.IsBrowserVisible()
			WinActivate, % "ahk_id" this.BrowserId			
		LinkCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, this.UIA.HyperlinkControlTypeId)
		return this.BrowserElement.FindAll(LinkCondition)

	}
	
	__CompareTitles(compareTitle, winTitle) {
		if (A_TitleMatchMode == 1) {
			if (SubStr(winTitle, 1, StrLen(compareTitle)) == compareTitle)
				return 1
		} else if (A_TitleMatchMode == 2) {
			if InStr(winTitle, compareTitle)
				return 1
		} else if (A_TitleMatchMode == 3) {
			if compareTitle == winTitle
				return 1
		} else if (A_TitleMatchMode == "RegEx") {
			if RegexMatch(winTitle, compareTitle)
				return 1
		}
		return 0
	}
	
	WaitTitleChange(targetTitle="", timeOut=10000) { ; Waits the browser title to change to targetTitle (by default just waits for the title to change), timeOut is in milliseconds (default is 10 seconds)
		WinGetTitle, origTitle, % "ahk_id" this.BrowserId
		startTime := A_TickCount, newTitle := origTitle
		while (((A_TickCount - startTime) < timeOut) && (targetTitle ? !this.__CompareTitles(targetTitle, newTitle) : (origTitle == newTitle))) {
			Sleep, 200
			WinGetActiveTitle, newTitle
		}
	}
	
	WaitPageLoad(targetTitle="", timeOut=10000, sleepAfter=500) { ; Waits the browser page to load to targetTitle, default timeOut is 10 seconds, sleepAfter additionally sleeps for 500ms after the page has loaded. In Edge browser this just waits for the title to change, so its better to use the WaitElementExist function.
		if (this.BrowserType != "Chrome") {
			this.WaitTitleChange(targetTitle, timeOut)
			Sleep, %sleepAfter%
			if (this.BrowserType == "Edge")
				this.BrowserElement.FindFirstBuildCache(this.UIA.TrueCondition, this.UIA.TreeScope_Descendants, this.ControlCache)
			return
		}
		reloadBut := this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetFirstChildElement(this.NavigationBarElement)))
		legacyPattern := reloadBut.GetCurrentPatternAs("LegacyIAccessible")
		startTime := A_TickCount
		while ((A_TickCount - startTime) < timeOut) {

			if !InStr(legacyPattern.CurrentDescription, "Stop") {
				if targetTitle {
					WinGetTitle, wTitle, % "ahk_id" this.BrowserId
					if this.__CompareTitles(targetTitle, wTitle)
						break
				} else
					break
			}

			Sleep, 200
			reloadBut := this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetNextSiblingElement(this.UIA.TreeWalkerTrue.GetFirstChildElement(this.NavigationBarElement)))
			legacyPattern := reloadBut.GetCurrentPatternAs("LegacyIAccessible")
		}
		if ((A_TickCount - startTime) < timeOut)
			Sleep, %sleepAfter%
	}
	
	Back() { ; Presses the Back button
		this.TWT.GetFirstChildElement(this.NavigationBarElement).Click()
	}
	
	Forward() { ; Presses the Forward button
		this.TWT.GetNextSiblingElement(this.TWT.GetFirstChildElement(this.NavigationBarElement)).Click()
	}

	Reload() { ; Presses the Reload button
		this.TWT.GetNextSiblingElement(this.TWT.GetNextSiblingElement(this.TWT.GetFirstChildElement(this.NavigationBarElement))).Click()
		/*
		this.MainPaneElement
		ReloadCondition := this.UIA.CreatePropertyCondition(this.UIA.NamePropertyId, "Reload", VT_BSTR := 8) ; for Chrome
		RefreshCondition := this.UIA.CreatePropertyCondition(this.UIA.NamePropertyId, "Refresh", VT_BSTR := 8) ; for Edge
		OrCondition := this.UIA.CreateOrCondition(ReloadCondition, RefreshCondition)
		this.MainPaneElement.FindFirst(OrCondition).Click()
		*/
	}

	Home(butName="Home") { ; Presses the Home button if it exists. If the browser language is not set to English, the correct butName can be specified.
		NameCondition := this.UIA.CreatePropertyCondition(this.UIA.NamePropertyId, butName)
		ButtonCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, UIA_Enum.UIA_ControlTypeId("Button"))
		this.NavigationBarElement.FindFirst(this.UIA.CreateAndCondition(NameCondition, ButtonCondition)).Click()
	}
	
	GetCurrentURL(fromAddressBar=False) { ; Gets the current URL. fromAddressBar=True gets it straight from the URL bar element, which is not a very good method, because the text might be changed by the user and doesn't start with "http(s)://". Default of fromAddressBar=False will cause the real URL to be fetched, but the browser must be visible for it to work (if is not visible, it will be automatically activated).
		if fromAddressBar {
			URL := this.URLEditElement.CurrentValue
			return URL ? (RegexMatch(URL, "^https?:\/\/") ? URL : "https://" URL) : ""
		} else {
			; This can be used in Chrome and Edge, but works only if the window is active
			if !this.IsBrowserVisible()
				WinActivate, % "ahk_id" this.BrowserId

			return this.GetCurrentDocumentElement().CurrentValue
		}
	}
	
	SetURL(newUrl, navigateToNewUrl = False) { ; Sets the URL bar to newUrl, optionally also navigates to it if navigateToNewUrl=True
		this.URLEditElement.SetFocus()
		valuePattern := this.URLEditElement.GetCurrentPatternAs("Value")
		valuePattern.SetValue(newUrl " ")
		if !InStr(this.URLEditElement.CurrentValue, newUrl) {
			legacyPattern := this.URLEditElement.GetCurrentPatternAs("LegacyIAccessible")
			legacyPattern.SetValue(newUrl " ")
			legacyPattern.Select()
		}
		if (navigateToNewUrl&&InStr(this.URLEditElement.CurrentValue, newUrl))
			ControlSend,, {Enter}, % "ahk_id" this.BrowserId
	}
	
	NewTab(butName="New Tab") { ; Presses the New tab button. The button name might differ if the browser language is not set to English and can be specified with butName
		newTabBut := this.MainPaneElement.FindFirstByNameAndType(butName, UIA_Enum.UIA_ButtonControlTypeId)
		newTabBut.Click()
	}
	
	GetAllTabs() { ; Gets all tab elements
		TabItemControlCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, UIA_Enum.UIA_ControlTypeId("TabItem"))
		return this.MainPaneElement.FindAll(TabItemControlCondition)
	}

	GetAllTabNames() { ; Gets all the titles of tabs
		names := []
		for k, v in this.GetAllTabs() {
			names.Push(v.CurrentName)
		}
		return names
	}
	
	FindTabByName(searchPhrase, matchMode=3, caseSensitive=False) { ; Returns a tab element text of searchPhrase. matchMode follows SetTitleMatchMode scheme: 1=tab name must must start with tabName; 2=can contain anywhere; 3=exact match; RegEx
		return this.MainPaneElement.FindFirstByNameAndType(searchPhrase, "TabItem",, matchMode, caseSensitive)
	}
	
	SelectTab(tabName, matchMode=3) { ; Selects a tab with the text of tabName. matchMode follows SetTitleMatchMode scheme: 1=tab name must must start with tabName; 2=can contain anywhere; 3=exact match; RegEx
		if (matchMode==3) {
			TabItemControlCondition := this.UIA.CreatePropertyCondition(this.UIA.ControlTypePropertyId, UIA_Enum.UIA_ControlTypeId("TabItem"))
			TabNameCondition := this.UIA.CreatePropertyCondition(this.UIA.NamePropertyId, tabName)
			AndCondition := this.UIA.CreateAndCondition(TabItemControlCondition, TabNameCondition)
			return this.MainPaneElement.FindFirst(AndCondition).Click()
		}
		for k, v in this.GetAllTabs() {
			curName := v.CurrentName
			if (((matchMode == 1) && (SubStr(curName, 1, StrLen(tabName)) == tabName)) || ((matchMode == 2) && InStr(curName, tabName)) || ((matchMode == "RegEx") && RegExMatch(curName, tabName)))
				return v.Click()
		}
	}
	
	CloseTab(tabElementOrName, matchMode=3, caseSensitive=False) { ; Close tab by either providing the tab element or the name of the tab
		if IsObject(tabElementOrName)
			if (tabElementOrName.CurrentControlType == this.UIA.TabItemControlType)
				try tabElementOrName.FindFirst(this.ButtonCondition).Click()
		else {
			try this.MainPaneElement.FindFirstByNameAndType(searchPhrase, "TabItem",, matchMode, caseSensitive).FindFirst(this.ButtonCondition).Click()
		}
	}
	
	IsBrowserVisible() { ; Returns True if any of window 4 corners are visible
		WinGetPos, X, Y, W, H, % "ahk_id" this.BrowserId
		if ((this.BrowserId == this.WindowFromPoint(X, Y)) || (this.BrowserId == this.WindowFromPoint(X, Y+H-1)) || (this.BrowserId == this.WindowFromPoint(X+W-1, Y)) || (this.BrowserId == this.WindowFromPoint(X+W-1, Y+H-1)))
			return True
		return False
	}
	
	WindowFromPoint(X, Y) { ; by SKAN and Linear Spoon
		return DllCall( "GetAncestor", "UInt"
			   , DllCall( "WindowFromPoint", "UInt64", X | (Y << 32))
			   , "UInt", GA_ROOT := 2 )
	}

	PrintArray(arr) {
		ret := ""
		for k, v in arr
			ret .= "Key: " k " Value: " (IsFunc(v)? v.name:IsObject(v)?UIA_Browser.PrintArray(v):v) "`n"
		return ret
	}
}