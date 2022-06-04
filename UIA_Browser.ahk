
class UIA_Browser {
	__New(wTitle="A") {
		this.UIA := UIA_Interface()
		this.TWT := this.UIA.TreeWalkerTrue
		this.ControlCache := this.UIA.CreateCacheRequest()
		this.ControlCache.SetTreeScope(0x4)
		this.ControlCache.AddProperty(UIA_ControlTypePropertyId)
		
		this.BrowserElement := this.UIA.ElementFromHandle(this.BrowserId := WinExist(wTitle))
		if this.BrowserId {
			WinGet, wExe, ProcessName, % "ahk_id" this.BrowserId
			this.BrowserType := (wExe == "chrome.exe") ? "Chrome" : (wExe == "msedge.exe") ? "Edge" : "Unknown"
			;if (this.BrowserType == "Edge")
			;	this.BrowserElement.FindFirstBuildCache(this.UIA.TrueCondition, UIA_TreeScope_Descendants, this.ControlCache)
			this.GetCurrentMainPaneElement()
		}
	}
	
	__Call(member, params*) {
		if !ObjHasKey(this.base, member) {
			;ClipBoard := PrintArray(this.BrowserElement)
			
			if ObjHasKey(this.UIA.base, member)
				return this.UIA[member].Call(this.UIA, params*)
			else if ObjHasKey(this.BrowserElement.base, member)
				return this.BrowserElement[member].Call(this.BrowserElement, params*)
			else
				throw Exception("Method call not supported by " this.__Class " nor UIA_Interface or UIA_Element class.",-1,member)
		}
	}
	
	GetCurrentMainPaneElement() {
		ToolbarControlCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_ToolBarControlTypeId, VT_I4 := 3)
		return this.MainPaneElement := this.TWT.GetParentElement(this.NavigationBarElement := this.BrowserElement.FindFirst(ToolbarControlCondition))
		;PaneControlCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_PaneControlTypeId, VT_I4 := 3)
		;PaneNameCondition := this.UIA.CreatePropertyCondition(UIA_NamePropertyId, "Google Chrome", VT_BSTR := 8)
		;AndCondition := this.UIA.CreateAndCondition(PaneControlCondition,PaneNameCondition)
		;this.MainPaneElement := this.BrowserElement.FindFirst(AndCondition)
	}
	
	GetCurrentDocumentElement() {
		docType := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_DocumentControlTypeId, VT_I4 := 3)
		if (this.BrowserType == "Edge")
			this.BrowserElement.FindFirstBuildCache(this.UIA.TrueCondition, UIA_TreeScope_Descendants, this.ControlCache)
		return IsObject(ff := this.BrowserElement.FindFirst(docType)) ? ff : this.BrowserElement.FindFirst(docType)
	}
	
	GetAllText() { ; Gets all the text from the webpage (CurrentName properties for all elements)
		if !this.IsBrowserVisible()
			WinActivate, % "ahk_id" this.BrowserId
		if (this.BrowserType == "Edge")
			this.BrowserElement.FindFirstBuildCache(this.UIA.TrueCondition, UIA_TreeScope_Descendants, this.ControlCache)
			
		TextCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_TextControlTypeId, VT_I4 := 3)
		TextArray := this.BrowserElement.FindAll(TextCondition)
		Text := ""
		for k, v in TextArray
			Text .= v.CurrentName "`n"
		return Text
	}

	GetAllLinks() { ; Returns all link elements in the current webpage
		if !this.IsBrowserVisible()
			WinActivate, % "ahk_id" this.BrowserId
		if (this.BrowserType == "Edge")
			this.BrowserElement.FindFirstBuildCache(this.UIA.TrueCondition, UIA_TreeScope_Descendants, this.ControlCache)
			
		LinkCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_HyperlinkControlTypeId, VT_I4 := 3)
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
	
	WaitTitleChange(targetTitle="", timeOut=10000) {
		WinGetTitle, origTitle, % "ahk_id" this.BrowserId
		startTime := A_TickCount, newTitle := origTitle
		while (((A_TickCount - startTime) < timeOut) && (targetTitle ? !this.__CompareTitles(targetTitle, newTitle) : (origTitle == newTitle))) {
			Sleep, 200
			WinGetActiveTitle, newTitle
		}
	}
	
	WaitPageLoad(targetTitle="", timeOut=10000, sleepAfter=500) {
		if (this.BrowserType != "Chrome") {
			this.WaitTitleChange(targetTitle, timeOut)
			Sleep, %sleepAfter%
			if (this.BrowserType == "Edge")
				this.BrowserElement.FindFirstBuildCache(this.UIA.TrueCondition, UIA_TreeScope_Descendants, this.ControlCache)
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
	
	Back() {
		this.TWT.GetFirstChildElement(this.NavigationBarElement).Click()
	}
	
	Forward() {
		this.TWT.GetNextSiblingElement(this.TWT.GetFirstChildElement(this.NavigationBarElement)).Click()
	}

	Reload() {
		this.TWT.GetNextSiblingElement(this.TWT.GetNextSiblingElement(this.TWT.GetFirstChildElement(this.NavigationBarElement))).Click()
		/*
		this.MainPaneElement
		ReloadCondition := this.UIA.CreatePropertyCondition(UIA_NamePropertyId, "Reload", VT_BSTR := 8) ; for Chrome
		RefreshCondition := this.UIA.CreatePropertyCondition(UIA_NamePropertyId, "Refresh", VT_BSTR := 8) ; for Edge
		OrCondition := this.UIA.CreateOrCondition(ReloadCondition, RefreshCondition)
		this.MainPaneElement.FindFirst(OrCondition).Click()
		*/
	}

	Home(butName="Home") {
		this.MainPaneElement
		ButtonCondition := this.UIA.CreatePropertyCondition(UIA_NamePropertyId, butName, VT_BSTR := 8)
		this.NavigationBarElement.FindFirst(ButtonCondition).Click()
	}
	
	GetCurrentURL(fromAddressBar=False) { ; Getting the current URL with fromAddressBar=True is not a very good method, because it gets the text straight from the URL edit element, which might be changed by the user and doesn't start with "http(s)://". Setting it to false will cause the real URL to be fetched, but the browser must be visible for it to work (if is not visible, it will be automatically activated).
		if fromAddressBar {
			EditControlCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_EditControlTypeId, VT_I4 := 3)
			URLEdit := this.MainPaneElement.FindFirst(EditControlCondition)
			URL := URLEdit.GetCurrentPropertyValue(UIA_ValueValuePropertyId := 30045)
			return URL ? (RegexMatch(URL, "^https?:\/\/") ? URL : "https://" URL) : ""
		} else {
			; This can be used in Chrome and Edge, but works only if the window is active
			if !this.IsBrowserVisible()
				WinActivate, % "ahk_id" this.BrowserId

			return this.GetCurrentDocumentElement().GetCurrentValue()
		}
	}
	
	SetURL(newUrl, navigateToNewUrl = False) {
		EditControlCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_EditControlTypeId, VT_I4 := 3)
		URLEdit := this.MainPaneElement.FindFirst(EditControlCondition)
		try {
			legacyPattern := URLEdit.GetCurrentPatternAs("LegacyIAccessible")
			legacyPattern.SetValue(newUrl)
			legacyPattern.Select()
		}
		if navigateToNewUrl
			ControlSend,, {Enter}, % "ahk_id" this.BrowserId
	}
	
	NewTab(butName="New Tab") { ; The button name might differ if the browser locale is not set to English
		newTabBut := this.MainPaneElement.FindFirstByNameAndType(butName, UIA_ButtonControlTypeId)
		newTabBut.Click()
	}
	
	GetAllTabs() {
		TabItemControlCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_TabItemControlTypeId, VT_I4 := 3)
		return this.MainPaneElement.FindAll(TabItemControlCondition)
	}

	GetAllTabNames() {
		names := []
		for k, v in this.GetAllTabs()
			names.Push(v.CurrentName)
		return names
	}
	
	SelectTab(tabName, matchMode=3) { ; matchMode follows SetTitleMatchMode scheme: 1=must start with; 2=can contain anywhere; 3=exact match; RegEx
		if (matchMode==3) {
			TabItemControlCondition := this.UIA.CreatePropertyCondition(UIA_ControlTypePropertyId, UIA_TabItemControlTypeId, VT_I4 := 3)
			TabNameCondition := this.UIA.CreatePropertyCondition(UIA_NamePropertyId, tabName, VT_BSTR := 8)
			AndCondition := this.UIA.CreateAndCondition(TabItemControlCondition,TabNameCondition)
			return this.BrowserElement.FindFirst(AndCondition).Click()
		}
		for k, v in this.GetAllTabs() {
			curName := v.CurrentName
			if (((matchMode == 1) && (SubStr(curName, 1, StrLen(name)) == name)) || ((matchMode == 2) && InStr(curName, name)) || ((matchMode == "RegEx") && RegExMatch(curName, name)))
				return v.Click()
		}
	}
	
	IsBrowserVisible() { ; returns True if any of window 4 corners are visible
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
			ret .= "Key: " k " Value: " (IsFunc(v)? v.name:v) "`n"
		return ret
	}
}