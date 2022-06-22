#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
CoordMode, Mouse, Screen

global UIA := UIA_Interface(), IsCapturing := False, Stored := {}, Acc, EnableAccTree := False
Stored.TreeView := {}
Acc_Init()
Acc_Error(1)

_xoffsetfirst := 8
_xoffset := 5
_yoffset := 20
_ysoffset := 2

Gui Main: New, AlwaysOnTop, UIAViewer
Gui Main: Default

Gui Add, GroupBox, x8 y10 w302 h160, Window/Control Info
Gui Add, Text, xm+%_xoffsetfirst% yp+%_yoffset% w30 Section, WinTitle:
Gui Add, Text,, Text:
Gui Add, Edit, ys-%_ysoffset% w235 vEditWinTitle, 
Gui Add, Edit, w235 vEditWinText, 
Gui Add, Text, x18 yp+30 Section, Hwnd:
Gui Add, Text,, Position:
Gui Add, Text,, Size:
Gui Add, Edit, ys-%_ysoffset% w80 vEditWinHwnd, 
Gui Add, Edit, w80 vEditWinPosition,
Gui Add, Edit, w80 vEditWinSize,
Gui Add, Text, ys, ClassNN:
Gui Add, Text,, Process:
Gui Add, Text,, Process ID:
Gui Add, Edit, ys-%_ysoffset% w80 vEditWinClass,
Gui Add, Edit, w80 vEditWinProcess,
Gui Add, Edit, w80 vEditWinProcessID,

Gui Add, GroupBox, x%_xoffsetfirst% y180 w302 h295, UIAutomation Element Info
Gui Add, Text, xm+%_xoffsetfirst% yp+%_yoffset%, ControlType:
Gui Add, Edit, x+%_xoffset% yp-%_ysoffset% w216 vEditControlType,

Gui Add, Text, xm+%_xoffsetfirst% yp+30 Section, Name:
Gui Add, Text,, Value:

Gui Add, Text,, Patterns:
Gui Add, Edit, ys-%_ysoffset% w228 vEditName,
Gui Add, Edit, w228 vEditValue,
Gui Add, Edit, w228 vEditPatterns,

Gui Add, Text, xm+%_xoffsetfirst% yp+30, AutomationId:
Gui Add, Edit, x+%_xoffset% yp-%_ysoffset% w208 vEditAutomationId,

Gui Add, Text, xm+%_xoffsetfirst% yp+30 Section, BoundingRectangle:
Gui Add, Edit, ys-%_ysoffset% w174 vEditBoundingRectangle,

Gui Add, Text, xm+%_xoffsetfirst% yp+30, ClassName:
Gui Add, Edit, x+3 yp-%_ysoffset% w68 vEditClassName,
Gui Add, Text, x+%_xoffset% yp+%_ysoffset%, HelpText:
Gui Add, Edit, x+%_xoffset% yp-%_ysoffset% w97 vEditHelpText,

Gui Add, Text, xm+%_xoffsetfirst% yp+30, AccessKey:
Gui Add, Edit, x+%_xoffset% yp-%_ysoffset% w68 vEditAccessKey,
Gui Add, Text, x+%_xoffset% yp+%_ysoffset%, AcceleratorKey:
Gui Add, Edit, x+%_xoffset% yp-%_ysoffset% w68 vEditAcceleratorKey,

Gui Add, CheckBox, x18 yp+30 Section +Disabled vCBIsKeyboardFocusable, IsKeyboardFocusable
Gui Add, CheckBox, ys +Disabled vCBIsEnabled, IsEnabled

Gui Add, Button, xm+60 yp+30 w150 gButCapture vButCapture, Start capturing
Gui Add, Button, xp+300 yp w192 vButRefreshTreeView gButRefreshTreeView +Disabled, Start capturing to show tree

Gui Add, TreeView, x320 y8 w300 h435 hwndhMainTreeView vMainTreeView gMainTreeView
Gui, Font, Bold
Gui, Add, StatusBar, gMainSB vMainSB
SB_SetText("`tClick here to enable Acc path capturing (can't be used with UIA!)")
Gui, Font
SB_SetParts(380)
SB_SetText("`tCurrent UIA Interface version: " UIA.__Version,2)

Gui Show,, UIAViewer
Return

MainGuiEscape:
MainGuiClose:
	IsCapturing := False
    ExitApp

MainSB:
	GuiControlGet, SBText,, MainSB
	if (SBText == "`tClick here to enable Acc path capturing (can't be used with UIA!)") {
		EnableAccTree := True
		SB_SetText("",1)
		SB_SetText("`tClick on path to copy to Clipboard",2)
	} else if SBText {
		Clipboard := SubStr(SBText, 8)
		ToolTip, % "Successfully copied """ SubStr(SBText, 8) """ to Clipboard!"
		SetTimer, RemoveToolTip, -2000
	}
	return

ButCapture:
	if IsCapturing {
		RangeTip()
		IsCapturing := False
		GuiControl, Main:, ButCapture, Start capturing
		GuiControl, Main: Enable, ButCapture
		GuiControl, Main: Enable, ButRefreshTreeView
		GuiControl, Main:, ButRefreshTreeView, Construct tree for whole Window
	} else {
		IsCapturing := True
		GuiControl, Main:, ButCapture, Press Esc to stop capturing
		GuiControl, Main: Disable, ButCapture
		GuiControl, Main: Disable, ButRefreshTreeView
		GuiControl, Main:, ButRefreshTreeView, Hold cursor still to construct tree
		Stored := {}
		
		While (IsCapturing) {
			MouseGetPos, mX, mY, mHwnd, mCtrl
					
			try {
				mEl := UIA.ElementFromPoint(mX, mY)

				; Sometimes ElementFromPoint doesn't get the deepest child node, so iterate all the child nodes and find the smallest one under the cursor
				bound := mEl.CurrentBoundingRectangle, mElSize := (bound.r-bound.l)*(bound.b-bound.t)
				for k, v in mEl.FindAll(UIA.TrueCondition) {
					bound := v.CurrentBoundingRectangle
					if ((mX >= bound.l) && (mX <= bound.r) && (mY >= bound.t) && (mY <= bound.b) && ((newSize := (bound.r-bound.l)*(bound.b-bound.t)) < mElSize))
						mEl := v, mElSize := newSize
				}
			} catch e {
				UpdateElementFields()
				GuiControl, Main:, EditName, % "ERROR: " e.Message
				if InStr(e.Message, "0x80070005")
					GuiControl, Main:, EditValue, Try running UIAViewer with Admin privileges
			}
		
			if (mHwnd != Stored.Hwnd) {
				; In some setups Chromium-based renderers don't react to UIA calls by enabling accessibility, so we need to send the WM_GETOBJECT message to the first renderer control for the application to enable accessibility. Thanks to users malcev and rommmcek for this tip. Explanation why this works: https://www.chromium.org/developers/design-documents/accessibility/#TOC-How-Chrome-detects-the-presence-of-Assistive-Technology 
				WinGet, cList, ControlList, ahk_id %mHwnd%
				if InStr(cList, "Chrome_RenderWidgetHostHWND1")
					SendMessage, WM_GETOBJECT := 0x003D, 0, 1, Chrome_RenderWidgetHostHWND1, ahk_id %mHwnd%
				WinGetTitle, wTitle, ahk_id %mHwnd%
				WinGetPos, wX, wY, wW, wH, ahk_id %mHwnd%
				WinGetClass, wClass, ahk_id %mHwnd%
				WinGetText, wText, ahk_id %mHwnd%
				WinGet, wProc, ProcessName, ahk_id %mHwnd%
				WinGet, wProcID, PID, ahk_id %mHwnd%
			
				GuiControl, Main:, EditWinTitle, %wTitle%
				GuiControl, Main:, EditWinText, %wText%
				GuiControl, Main:, EditWinHwnd, ahk_id %mHwnd%
				GuiControl, Main:, EditWinPosition, X: %wX% Y: %wY%
				GuiControl, Main:, EditWinSize, W: %wW% H: %wH%
				GuiControl, Main:, EditWinClass, %wClass%
				GuiControl, Main:, EditWinProcess, %wProc%
				GuiControl, Main:, EditWinProcessID, %wProcID%
			}

			if IsObject(Stored.Element) {
				try {
					if !UIA.CompareElements(mEl, Stored.Element) {
						UpdateElementFields(mEl)
						Stored.TickCount := A_TickCount
						if EnableAccTree {
							oAcc := Acc_ObjectFromPoint(childId, mX, mY), Acc_Location(oAcc,childId,vAccLoc)
							SB_SetText(" Path: " GetAccPathTopDown(mHwnd, vAccLoc), 1)
						}
					} else if (Stored.TickCount && (A_TickCount - Stored.TickCount > 1000)) { ; Wait for mouse to be stable for a second
						Stored.TickCount := 0
						RedrawTreeView(mEl, False)
						for k,v in Stored.TreeView {
							if (v == mEl)
								TV_Modify(k)
						}
					}
				} 
			}

			Stored.Hwnd := mHwnd, Stored.Element := mEl
			Sleep, 200
		}
		
	}
	return

ButRefreshTreeView:
	if (Stored.Hwnd && WinExist("ahk_id" Stored.Hwnd))
		RedrawTreeView(UIA.ElementFromHandle(Stored.Hwnd), True)
	if IsObject(Stored.Element) {
		for k,v in Stored.TreeView
			if UIA.CompareElements(v, Stored.Element)
				TV_Modify(k)
		if EnableAccTree {
			br := Stored.Element.CurrentBoundingRectangle
			GetAccPathTopDown(Stored.Hwnd, "x" br.l " y" br.t " w" (br.r-br.l) " h" (br.b-br.t), True)
		}
	}
	return

MainTreeView:
	if (A_GuiEvent == "S") {
		UpdateElementFields(Stored.Treeview[A_EventInfo])
		if EnableAccTree {
			br := Stored.Treeview[A_EventInfo].CurrentBoundingRectangle
			SB_SetText(" Path: " GetAccPathTopDown(Stored.Hwnd, "x" br.l " y" br.t " w" (br.r-br.l) " h" (br.b-br.t)), 1)
		}
	}
	return

RemoveToolTip:
	ToolTip
	return

UpdateElementFields(mEl="") {
	if !IsObject(mEl) {
		GuiControl, Main:, EditControlType, 
		GuiControl, Main:, EditName,
		GuiControl, Main:, EditValue,
		GuiControl, Main:, EditPatterns,
		GuiControl, Main:, EditAutomationId,
		GuiControl, Main:, EditBoundingRectangle,
		GuiControl, Main:, EditAccessKey,
		GuiControl, Main:, EditAcceleratorKey,
		GuiControl, Main:, EditClassName,
		GuiControl, Main:, EditHelpText,
		GuiControl, Main:, CBIsKeyboardFocusable,
		GuiControl, Main:, CBIsEnabled,
		return
	}
	try {
		mElPos := mEl.CurrentBoundingRectangle
		RangeTip(mElPos.l, mElPos.t, mElPos.r-mElPos.l, mElPos.b-mElPos.t, "Blue", 4)
		GuiControl, Main:, EditControlType, % (ctrlType := mEl.CurrentControlType) " (" UIA_ControlTypeId(ctrlType) ")`t[Localized: " mEl.CurrentLocalizedControlType "]"
		GuiControl, Main:, EditName, % mEl.CurrentName
		GuiControl, Main:, EditValue, % mEl.GetCurrentPropertyValue(UIA_ValueValuePropertyId := 30045)
		patterns := ""
		for k, v in UIA.PollForPotentialSupportedPatterns(mEl)
			patterns .= ", " RegexReplace(k, "Pattern$")
		GuiControl, Main:, EditPatterns, % SubStr(patterns, 3)
		GuiControl, Main:, EditAutomationId, % mEl.CurrentAutomationId
		GuiControl, Main:, EditBoundingRectangle, % "l: " mElPos.l " t: " mElPos.t " r: " mElPos.r " b: " mElPos.b
		GuiControl, Main:, EditAccessKey, % mEl.CurrentAccessKey
		GuiControl, Main:, EditAcceleratorKey, % mEl.CurrentAcceleratorKey
		GuiControl, Main:, EditClassName, % mEl.CurrentClassName
		GuiControl, Main:, EditHelpText, % mEl.CurrentHelpText
		GuiControl, Main:, CBIsKeyboardFocusable, % mEl.CurrentIsKeyboardFocusable
		GuiControl, Main:, CBIsEnabled, % mEl.CurrentIsEnabled
	}
	return
}

RedrawTreeView(el, noAncestors=True) {
	global MainTreeView, hMainTreeView
	TV_Delete()
	TV_Add("Constructing TreeView, do not move the mouse...")
	GuiControl, Main: -Redraw, MainTreeView
	Gui, TreeView, MainTreeView
	TV_Delete()
	Stored.TreeView := {}
	if noAncestors {
		ConstructTreeView(el)
	} else {
		; Get all ancestors
		ancestors := [], parent := el
		while IsObject(parent) {
			try {
				ancestors.Push(parent := UIA.TreeWalkerTrue.GetParentElement(parent))
			} catch {
				break
			}
		}
		
		; Loop backwards through ancestors to create the TreeView
		maxInd := ancestors.MaxIndex(), parent := ""
		while (--maxInd) {
			if !IsObject(ancestors[maxInd])
				return
			try {
				elDesc := ancestors[maxInd].CurrentLocalizedControlType " """ ancestors[maxInd].CurrentName """"
				if (elDesc == " """"")
					break
				Stored.TreeView[parent := TV_Add(elDesc, parent)] := ancestors[maxInd]
			}
		}
		; Add child elements to TreeView also
		ConstructTreeView(el, parent)
	}
	for k,v in Stored.TreeView
		TV_Modify(k, "Expand")
	
	SendMessage, 0x115, 6, 0,, ahk_id %hMainTreeView% ; scroll to top
	GuiControl, Main: +Redraw, MainTreeView
}

ConstructTreeView(el, parent="") {
	if !IsObject(el)
		return
	try {
		elDesc := el.CurrentLocalizedControlType " """ el.CurrentName """"
		if (elDesc == " """"")
			return
		Stored.TreeView[TWEl := TV_Add(elDesc, parent)] := el
		if !(children := el.FindAll(UIA.TrueCondition, 0x2))
			return
		for k, v in children
			ConstructTreeView(v, TWEl)
	}
}

; UIA FUNCTIONS
class UIA_Base {
	__New(p="", flag=1, ver=1) {
		ObjInsert(this,"__Type","IUIAutomation" SubStr(thisClass,5))
		,ObjInsert(this,"__Value",p)
		,ObjInsert(this,"__Flag",flag)
		,ObjInsert(this,"__Version",ver)
	}
	__Get(member) {
		if member not in base,__UIA,TreeWalkerTrue,TrueCondition ; base & __UIA should act as normal
		{	if raw:=SubStr(member,0)="*" ; return raw data - user should know what they are doing
				member:=SubStr(member,1,-1)
			if RegExMatch(this.__properties, "im)^" member ",(\d+),(\w+)", m) { ; if the member is in the properties. if not - give error message
				if (m2="VARIANT")	; return VARIANT data - DllCall output param different
					return UIA_Hr(DllCall(this.__Vt(m1), "ptr",this.__Value, "ptr",UIA_Variant(out)))? (raw?out:UIA_VariantData(out)):
				else if (m2="RECT") ; return RECT struct - DllCall output param different
					return UIA_Hr(DllCall(this.__Vt(m1), "ptr",this.__Value, "ptr",&(rect,VarSetCapacity(rect,16))))? (raw?out:UIA_RectToObject(rect)):
				else if UIA_Hr(DllCall(this.__Vt(m1), "ptr",this.__Value, "ptr*",out))
					return raw?out:m2="BSTR"?StrGet(out):RegExMatch(m2,"i)IUIAutomation\K\w+",n)?new UIA_%n%(out):out ; Bool, int, DWORD, HWND, CONTROLTYPEID, OrientationType?
			}
			else throw Exception("Property not supported by the " this.__Class " Class.",-1,member)
		}
	}
	__Delete() {
		this.__Flag ? ObjRelease(this.__Value):
	}
	__Vt(n) {
		return NumGet(NumGet(this.__Value+0,"ptr")+n*A_PtrSize,"ptr")
	}
}

class UIA_Interface extends UIA_Base {
	;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee671406(v=vs.85).aspx
	static __IID := "{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}"
		,  __properties := ""
	CompareElements(e1,e2) {
		return UIA_Hr(DllCall(this.__Vt(3), "ptr",this.__Value, "ptr",e1.__Value, "ptr",e2.__Value, "int*",out))? out:
	}
	ElementFromHandle(hwnd) {
		return UIA_Hr(DllCall(this.__Vt(6), "ptr",this.__Value, "ptr",hwnd, "ptr*",out))? new UIA_Element(out):
	}
	ElementFromPoint(x="", y="", activateChromiumAccessibility=False) {
		return UIA_Hr(DllCall(this.__Vt(7), "ptr",this.__Value, "UInt64",x==""||y==""?DllCall("GetCursorPos","Int64*",pt)*0+pt:x&0xFFFFFFFF|(y&0xFFFFFFFF)<<32, "ptr*",out))? new UIA_Element(out):
	}	
	CreateTreeWalker(condition) {
		return UIA_Hr(DllCall(this.__Vt(13), "ptr",this.__Value, "ptr",Condition.__Value, "ptr*",out))? new UIA_TreeWalker(out):
	}
	CreateTrueCondition() {
		return UIA_Hr(DllCall(this.__Vt(21), "ptr",this.__Value, "ptr*",out))? new UIA_BoolCondition(out):
	}
	CreatePropertyCondition(propertyId, var, type="Variant") {
		if (type!="Variant")
			UIA_Variant(var,type,var)
		return UIA_Hr((A_PtrSize == 4) ? DllCall(this.__Vt(23), "ptr",this.__Value, "int",propertyId, "int64", NumGet(var, 0, "int64"), "int64", NumGet(var, 8, "int64"), "ptr*",out) : DllCall(this.__Vt(23), "ptr",this.__Value, "int",propertyId, "ptr",&var, "ptr*",out))? new UIA_PropertyCondition(out):
	}
	PollForPotentialSupportedPatterns(e, Byref Ids="", Byref Names="") { ; Returns an object where keys are the names and values are the Ids
		return UIA_Hr(DllCall(this.__Vt(51), "ptr",this.__Value, "ptr",e.__Value, "ptr*",Ids, "ptr*",Names))? UIA_SafeArraysToObject(Names:=ComObj(0x2008,Names,1),Ids:=ComObj(0x2003,Ids,1)):
	}
}
class UIA_Element extends UIA_Base {
	;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee671425(v=vs.85).aspx
	static __IID := "{d22108aa-8ac5-49a5-837b-37bbb3d7591e}"
		,  __properties := "CurrentProcessId,20,int`r`nCurrentControlType,21,CONTROLTYPEID`r`nCurrentLocalizedControlType,22,BSTR`r`nCurrentName,23,BSTR`r`nCurrentAcceleratorKey,24,BSTR`r`nCurrentAccessKey,25,BSTR`r`nCurrentHasKeyboardFocus,26,BOOL`r`nCurrentIsKeyboardFocusable,27,BOOL`r`nCurrentIsEnabled,28,BOOL`r`nCurrentAutomationId,29,BSTR`r`nCurrentClassName,30,BSTR`r`nCurrentHelpText,31,BSTR`r`nCurrentCulture,32,int`r`nCurrentIsControlElement,33,BOOL`r`nCurrentIsContentElement,34,BOOL`r`nCurrentIsPassword,35,BOOL`r`nCurrentNativeWindowHandle,36,UIA_HWND`r`nCurrentItemType,37,BSTR`r`nCurrentIsOffscreen,38,BOOL`r`nCurrentOrientation,39,OrientationType`r`nCurrentFrameworkId,40,BSTR`r`nCurrentIsRequiredForForm,41,BOOL`r`nCurrentItemStatus,42,BSTR`r`nCurrentBoundingRectangle,43,RECT`r`nCurrentLabeledBy,44,IUIAutomationElement`r`nCurrentAriaRole,45,BSTR`r`nCurrentAriaProperties,46,BSTR`r`nCurrentIsDataValidForForm,47,BOOL`r`nCurrentControllerFor,48,IUIAutomationElementArray`r`nCurrentDescribedBy,49,IUIAutomationElementArray`r`nCurrentFlowsTo,50,IUIAutomationElementArray`r`nCurrentProviderDescription,51,BSTR"
	FindAll(c="", scope=0x4) {
		return UIA_Hr(DllCall(this.__Vt(6), "ptr",this.__Value, "uint",scope, "ptr",(c=""?this.TrueCondition:c).__Value, "ptr*",out))&&out? UIA_ElementArray(out):
	}
	GetCurrentPropertyValue(propertyId, ByRef out="") {
		return UIA_Hr(DllCall(this.__Vt(10), "ptr",this.__Value, "uint", propertyId, "ptr",UIA_Variant(out)))? UIA_VariantData(out):
		
	}
	GetSupportedPatterns() { ; Get all available patterns for the element. Use of this should be avoided, since it calls GetCurrentPatternAs for every possible pattern.
		result := []
		patterns := "Invoke,Selection,Value,RangeValue,Scroll,ExpandCollapse,Grid,GridItem,MultipleView,Window,SelectionItem,Dock,Table,TableItem,Text,Toggle,Transform,ScrollItem,ItemContainer,VirtualizedItem,SyncronizedInput,LegacyIAccessible"

		Loop, Parse, patterns, `,
		{
			try {
				if this.GetCurrentPropertyValue(UIA_PropertyId("Is" A_LoopField "PatternAvailable")) {
					result.Push(A_LoopField)
				}
			}
		}
		return result
	}
}
class UIA_ElementArray extends UIA_Base {
	static __IID := "{14314595-b4bc-4055-95f2-58f2e42c9855}"
		,  __properties := "Length,3,int"
	
	GetElement(i) {
		return UIA_Hr(DllCall(this.__Vt(4), "ptr",this.__Value, "int",i, "ptr*",out))? new UIA_Element(out):
	}
}

class UIA_TreeWalker extends UIA_Base {
	;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee671470(v=vs.85).aspx
	static __IID := "{4042c624-389c-4afc-a630-9df854a541fc}"
		,  __properties := "Condition,15,IUIAutomationCondition"
	
	GetParentElement(e) {
		return UIA_Hr(DllCall(this.__Vt(3), "ptr",this.__Value, "ptr",e.__Value, "ptr*",out))? new UIA_Element(out):
	}
	GetFirstChildElement(e) {
		return UIA_Hr(DllCall(this.__Vt(4), "ptr",this.__Value, "ptr",e.__Value, "ptr*",out))&&out? new UIA_Element(out):
	}
	GetLastChildElement(e) {
		return UIA_Hr(DllCall(this.__Vt(5), "ptr",this.__Value, "ptr",e.__Value, "ptr*",out))&&out? new UIA_Element(out):
	}
	GetNextSiblingElement(e) {
		return UIA_Hr(DllCall(this.__Vt(6), "ptr",this.__Value, "ptr",e.__Value, "ptr*",out))&&out? new UIA_Element(out):
	}
}

class UIA_Condition extends UIA_Base {
	;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee671420(v=vs.85).aspx
	static __IID := "{352ffba8-0973-437c-a61f-f64cafd81df9}"
		,  __properties := ""
}
class UIA_PropertyCondition extends UIA_Condition {
	;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee696121(v=vs.85).aspx
	static __IID := "{99ebf2cb-5578-4267-9ad4-afd6ea77e94b}"
		,  __properties := "PropertyId,3,PROPERTYID`r`nPropertyValue,4,VARIANT`r`nPropertyConditionFlags,5,PropertyConditionFlags"
}
class UIA_BoolCondition extends UIA_Condition {
	;~ http://msdn.microsoft.com/en-us/library/windows/desktop/ee671411(v=vs.85).aspx
	static __IID := "{1B4E1F2E-75EB-4D0B-8952-5A69988E2307}"
		,  __properties := "BooleanValue,3,boolVal"
}
UIA_Interface() {
	max := 7+1
	for k, v in ["{29de312e-83c6-4309-8808-e8dfcb46c3c2}","{aae072da-29e3-413d-87a7-192dbf81ed10}","{25f700c8-d816-4057-a9dc-3cbdee77e256}","{1189c02a-05f8-4319-8e21-e817e3db2860}","{73d768da-9b51-4b89-936e-c209290973e7}","{34723aff-0c9d-49d0-9896-7ab52df8cd8a}"] {
		try {
			if uia:=ComObjCreate("{e22ad333-b25f-460c-83d0-0581107395c9}",v)
				return uia:=new UIA_Interface(uia, 1, max-k), uia.base.base.__UIA:=uia, uia.base.base.TrueCondition:=uia.CreateTrueCondition(), uia.base.base.TreeWalkerTrue := uia.CreateTreeWalker(uia.base.base.TrueCondition)
		}
	}
	; If all else fails, try the first UIAutomation version
	try {
		if uia:=ComObjCreate("{ff48dba4-60ef-4201-aa87-54103eef594e}","{30cbe57d-d9d0-452a-ab13-7ac5ac4825ee}")
			return uia:=new UIA_Interface(uia, 1), uia.base.base.__UIA:=uia, uia.base.base.TrueCondition:=uia.CreateTrueCondition(), uia.base.base.TreeWalkerTrue := uia.CreateTreeWalker(uia.base.base.TrueCondition)
		throw "UIAutomation Interface failed to initialize."
	} catch e
		MsgBox, 262160, UIA Startup Error, % IsObject(e)?"IUIAutomation Interface is not registered.":e.Message
	return
}
UIA_Hr(hr) {
	;~ http://blogs.msdn.com/b/eldar/archive/2007/04/03/a-lot-of-hresult-codes.aspx
	static err:={0x8000FFFF:"Catastrophic failure.",0x80004001:"Not implemented.",0x8007000E:"Out of memory.",0x80070057:"One or more arguments are not valid.",0x80004002:"Interface not supported.",0x80004003:"Pointer not valid.",0x80070006:"Handle not valid.",0x80004004:"Operation aborted.",0x80004005:"Unspecified error.",0x80070005:"General access denied.",0x800401E5:"The object identified by this moniker could not be found.",0x80040201:"UIA_E_ELEMENTNOTAVAILABLE",0x80040200:"UIA_E_ELEMENTNOTENABLED",0x80131509:"UIA_E_INVALIDOPERATION",0x80040202:"UIA_E_NOCLICKABLEPOINT",0x80040204:"UIA_E_NOTSUPPORTED",0x80040203:"UIA_E_PROXYASSEMBLYNOTLOADED"} ; //not completed
	if hr&&(hr&=0xFFFFFFFF) {
		RegExMatch(Exception("",-2).what,"(\w+).(\w+)",i)
		throw Exception(UIA_Hex(hr) " - " err[hr], -2, i2 "  (" i1 ")")
	}
	return !hr
}
UIA_Hex(p) {
	setting:=A_FormatInteger
	SetFormat,IntegerFast,H
	out:=p+0 ""
	SetFormat,IntegerFast,%setting%
	return out
}
UIA_GUID(ByRef GUID, sGUID) { ;~ Converts a string to a binary GUID and returns its address.
	VarSetCapacity(GUID,16,0)
	return DllCall("ole32\CLSIDFromString", "wstr",sGUID, "ptr",&GUID)>=0?&GUID:""
}
UIA_ElementArray(p, uia="") { ; should AHK Object be 0 or 1 based? /// answer: 1 based ///
	a:=new UIA_ElementArray(p),out:=[]
	Loop % a.Length
		out[A_Index]:=a.GetElement(A_Index-1)
	return out, out.base:={UIA_ElementArray:a}
}
UIA_Variant(ByRef var,type=0,val=0) {
	; Does a variant need to be cleared? If it uses SysAllocString? 
	return (VarSetCapacity(var,8+2*A_PtrSize)+NumPut(type,var,0,"short")+NumPut(type=8? DllCall("oleaut32\SysAllocString", "ptr",&val):val,var,8,"ptr"))*0+&var
}
UIA_IsVariant(ByRef vt, ByRef type="") {
	size:=VarSetCapacity(vt),type:=NumGet(vt,"UShort")
	return size>=16&&size<=24&&type>=0&&(type<=23||type|0x2000)
}
UIA_VariantData(ByRef p, flag=1) {
	return !UIA_IsVariant(p,vt)?"Invalid Variant"
			:vt=3?NumGet(p,8,"int")
			:vt=8?StrGet(NumGet(p,8))
			:vt=9||vt=13||vt&0x2000?ComObj(vt,NumGet(p,8),flag)
			:vt<0x1000&&UIA_VariantChangeType(&p,&p)=0?StrGet(NumGet(p,8)) UIA_VariantClear(&p)
			:NumGet(p,8)
}
UIA_VariantChangeType(pvarDst, pvarSrc, vt=8) { ; written by Sean
	return DllCall("oleaut32\VariantChangeTypeEx", "ptr",pvarDst, "ptr",pvarSrc, "Uint",1024, "Ushort",0, "Ushort",vt)
}
UIA_VariantClear(pvar) { ; Written by Sean
	DllCall("oleaut32\VariantClear", "ptr",pvar)
}
UIA_SafeArraysToObject(keys,values) {
;~	1 dim safearrays w/ same # of elements
	out:={}
	for key in keys
		out[key]:=values[A_Index-1]
	return out
}
UIA_RectToObject(ByRef r) { ; rect.__Value work with DllCalls?
	static b:={__Class:"object",__Type:"RECT",Struct:Func("UIA_RectStructure")}
	return {l:NumGet(r,0,"Int"),t:NumGet(r,4,"Int"),r:NumGet(r,8,"Int"),b:NumGet(r,12,"Int"),base:b}
}
UIA_RectStructure(this, ByRef r) {
	static sides:="ltrb"
	VarSetCapacity(r,16)
	Loop Parse, sides
		NumPut(this[A_LoopField],r,(A_Index-1)*4,"Int")
}
UIA_PropertyId(n="") {
	static ids:="RuntimeId:30000,BoundingRectangle:30001,ProcessId:30002,ControlType:30003,LocalizedControlType:30004,Name:30005,AcceleratorKey:30006,AccessKey:30007,HasKeyboardFocus:30008,IsKeyboardFocusable:30009,IsEnabled:30010,AutomationId:30011,ClassName:30012,HelpText:30013,ClickablePoint:30014,Culture:30015,IsControlElement:30016,IsContentElement:30017,LabeledBy:30018,IsPassword:30019,NativeWindowHandle:30020,ItemType:30021,IsOffscreen:30022,Orientation:30023,FrameworkId:30024,IsRequiredForForm:30025,ItemStatus:30026,IsDockPatternAvailable:30027,IsExpandCollapsePatternAvailable:30028,IsGridItemPatternAvailable:30029,IsGridPatternAvailable:30030,IsInvokePatternAvailable:30031,IsMultipleViewPatternAvailable:30032,IsRangeValuePatternAvailable:30033,IsScrollPatternAvailable:30034,IsScrollItemPatternAvailable:30035,IsSelectionItemPatternAvailable:30036,IsSelectionPatternAvailable:30037,IsTablePatternAvailable:30038,IsTableItemPatternAvailable:30039,IsTextPatternAvailable:30040,IsTogglePatternAvailable:30041,IsTransformPatternAvailable:30042,IsValuePatternAvailable:30043,IsWindowPatternAvailable:30044,ValueValue:30045,ValueIsReadOnly:30046,RangeValueValue:30047,RangeValueIsReadOnly:30048,RangeValueMinimum:30049,RangeValueMaximum:30050,RangeValueLargeChange:30051,RangeValueSmallChange:30052,ScrollHorizontalScrollPercent:30053,ScrollHorizontalViewSize:30054,ScrollVerticalScrollPercent:30055,ScrollVerticalViewSize:30056,ScrollHorizontallyScrollable:30057,ScrollVerticallyScrollable:30058,SelectionSelection:30059,SelectionCanSelectMultiple:30060,SelectionIsSelectionRequired:30061,GridRowCount:30062,GridColumnCount:30063,GridItemRow:30064,GridItemColumn:30065,GridItemRowSpan:30066,GridItemColumnSpan:30067,GridItemContainingGrid:30068,DockDockPosition:30069,ExpandCollapseExpandCollapseState:30070,MultipleViewCurrentView:30071,MultipleViewSupportedViews:30072,WindowCanMaximize:30073,WindowCanMinimize:30074,WindowWindowVisualState:30075,WindowWindowInteractionState:30076,WindowIsModal:30077,WindowIsTopmost:30078,SelectionItemIsSelected:30079,SelectionItemSelectionContainer:30080,TableRowHeaders:30081,TableColumnHeaders:30082,TableRowOrColumnMajor:30083,TableItemRowHeaderItems:30084,TableItemColumnHeaderItems:30085,ToggleToggleState:30086,TransformCanMove:30087,TransformCanResize:30088,TransformCanRotate:30089,IsLegacyIAccessiblePatternAvailable:30090,LegacyIAccessibleChildId:30091,LegacyIAccessibleName:30092,LegacyIAccessibleValue:30093,LegacyIAccessibleDescription:30094,LegacyIAccessibleRole:30095,LegacyIAccessibleState:30096,LegacyIAccessibleHelp:30097,LegacyIAccessibleKeyboardShortcut:30098,LegacyIAccessibleSelection:30099,LegacyIAccessibleDefaultAction:30100,AriaRole:30101,AriaProperties:30102,IsDataValidForForm:30103,ControllerFor:30104,DescribedBy:30105,FlowsTo:30106,ProviderDescription:30107,IsItemContainerPatternAvailable:30108,IsVirtualizedItemPatternAvailable:30109,IsSynchronizedInputPatternAvailable:30110,OptimizeForVisualContent:30111,IsObjectModelPatternAvailable:30112,AnnotationAnnotationTypeId:30113,AnnotationAnnotationTypeName:30114,AnnotationAuthor:30115,AnnotationDateTime:30116,AnnotationTarget:30117,IsAnnotationPatternAvailable:30118,IsTextPattern2Available:30119,StylesStyleId:30120,StylesStyleName:30121,StylesFillColor:30122,StylesFillPatternStyle:30123,StylesShape:30124,StylesFillPatternColor:30125,StylesExtendedProperties:30126,IsStylesPatternAvailable:30127,IsSpreadsheetPatternAvailable:30128,SpreadsheetItemFormula:30129,SpreadsheetItemAnnotationObjects:30130,SpreadsheetItemAnnotationTypes:30131,IsSpreadsheetItemPatternAvailable:30132,Transform2CanZoom:30133,IsTransformPattern2Available:30134,LiveSetting:30135,IsTextChildPatternAvailable:30136,IsDragPatternAvailable:30137,DragIsGrabbed:30138,DragDropEffect:30139,DragDropEffects:30140,IsDropTargetPatternAvailable:30141,DropTargetDropTargetEffect:30142,DropTargetDropTargetEffects:30143,DragGrabbedItems:30144,Transform2ZoomLevel:30145,Transform2ZoomMinimum:30146,Transform2ZoomMaximum:30147,FlowsFrom:30148,IsTextEditPatternAvailable:30149,IsPeripheral:30150,IsCustomNavigationPatternAvailable:30151,PositionInSet:30152,SizeOfSet:30153,Level:30154,AnnotationTypes:30155,AnnotationObjects:30156,LandmarkType:30157,LocalizedLandmarkType:30158,FullDescription:30159,FillColor:30160,OutlineColor:30161,FillType:30162,VisualEffects:30163,OutlineThickness:30164,CenterPoint:30165,Rotation:30166,Size:30167,IsSelectionPattern2Available:30168,Selection2FirstSelectedItem:30169,Selection2LastSelectedItem:30170,Selection2CurrentSelectedItem:30171,Selection2ItemCount:30173,IsDialog:30174"
	if !n
		return ids		
	if n is integer 
	{
		RegexMatch(ids, "([^,]+):" n, m)
		return m1
	}
	
	n := StrReplace(StrReplace(n, "UIA_"), "PropertyId")
	RegexMatch(ids, "(?:^|,)" n "(?:" n ")?(?:Id)?:(\d+)", m)
	return m1
}

UIA_ControlTypeId(n="") {
	static id:={Button:50000,Calendar:50001,CheckBox:50002,ComboBox:50003,Edit:50004,Hyperlink:50005,Image:50006,ListItem:50007,List:50008,Menu:50009,MenuBar:50010,MenuItem:50011,ProgressBar:50012,RadioButton:50013,ScrollBar:50014,Slider:50015,Spinner:50016,StatusBar:50017,Tab:50018,TabItem:50019,Text:50020,ToolBar:50021,ToolTip:50022,Tree:50023,TreeItem:50024,Custom:50025,Group:50026,Thumb:50027,DataGrid:50028,DataItem:50029,Document:50030,SplitButton:50031,Window:50032,Pane:50033,Header:50034,HeaderItem:50035,Table:50036,TitleBar:50037,Separator:50038,SemanticZoom:50039,AppBar:50040}, name:={50000:"Button",50001:"Calendar",50002:"CheckBox",50003:"ComboBox",50004:"Edit",50005:"Hyperlink",50006:"Image",50007:"ListItem",50008:"List",50009:"Menu",50010:"MenuBar",50011:"MenuItem",50012:"ProgressBar",50013:"RadioButton",50014:"ScrollBar",50015:"Slider",50016:"Spinner",50017:"StatusBar",50018:"Tab",50019:"TabItem",50020:"Text",50021:"ToolBar",50022:"ToolTip",50023:"Tree",50024:"TreeItem",50025:"Custom",50026:"Group",50027:"Thumb",50028:"DataGrid",50029:"DataItem",50030:"Document",50031:"SplitButton",50032:"Window",50033:"Pane",50034:"Header",50035:"HeaderItem",50036:"Table",50037:"TitleBar",50038:"Separator",50039:"SemanticZoom",50040:"AppBar"}
	if !n
		return id
	if n is integer
		return name[n]
	if ObjHasKey(id, n)
		return id[n]
	return id[StrReplace(StrReplace(n, "ControlTypeId"), "UIA_")]
}

; Acc functions

GetAccPathTopDown(hwnd, vAccPos, updateTree=False) {
	static accTree
	if !IsObject(accTree)
		accTree := {}
	if (!IsObject(accTree[hwnd]) || updateTree)
		accTree[hwnd] := BuildAccTreeRecursive(Acc_ObjectFromWindow(hwnd, 0), {})
	for k, v in accTree[hwnd] {
		if (v == vAccPos)
			return k
	}
}

BuildAccTreeRecursive(oAcc, tree, path="") {
	if !IsObject(oAcc)
		return tree
	try 
		oAcc.accChildCount
	catch
		return tree
	For i, oChild in Acc_Children(oAcc) {
		if IsObject(oChild)
			Acc_Location(oChild,,vChildPos)
		else
			Acc_Location(oAcc,oChild,vChildPos)
		tree[path (path?(IsObject(oChild)?".":" c"):"") i] := vChildPos
		tree := BuildAccTreeRecursive(oChild, tree, path (path?".":"") i)
	}
	return tree
}
Acc_Init()
{
	Static	h
	If Not	h
	h:=DllCall("LoadLibrary","Str","oleacc","Ptr")
}
Acc_ObjectFromEvent(ByRef _idChild_, hWnd, idObject, idChild)
{
	Acc_Init()
	If	DllCall("oleacc\AccessibleObjectFromEvent", "Ptr", hWnd, "UInt", idObject, "UInt", idChild, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild)=0
	Return	ComObjEnwrap(9,pacc,1), _idChild_:=NumGet(varChild,8,"UInt")
}

Acc_ObjectFromPoint(ByRef _idChild_ = "", x = "", y = "")
{
	Acc_Init()
	If	DllCall("oleacc\AccessibleObjectFromPoint", "Int64", x==""||y==""?0*DllCall("GetCursorPos","Int64*",pt)+pt:x&0xFFFFFFFF|y<<32, "Ptr*", pacc, "Ptr", VarSetCapacity(varChild,8+2*A_PtrSize,0)*0+&varChild)=0
	Return	ComObjEnwrap(9,pacc,1), _idChild_:=NumGet(varChild,8,"UInt")
}

Acc_ObjectFromWindow(hWnd, idObject = -4)
{
	Acc_Init()
	If	DllCall("oleacc\AccessibleObjectFromWindow", "Ptr", hWnd, "UInt", idObject&=0xFFFFFFFF, "Ptr", -VarSetCapacity(IID,16)+NumPut(idObject==0xFFFFFFF0?0x46000000000000C0:0x719B3800AA000C81,NumPut(idObject==0xFFFFFFF0?0x0000000000020400:0x11CF3C3D618736E0,IID,"Int64"),"Int64"), "Ptr*", pacc)=0
	Return	ComObjEnwrap(9,pacc,1)
}

Acc_WindowFromObject(pacc)
{
	If	DllCall("oleacc\WindowFromAccessibleObject", "Ptr", IsObject(pacc)?ComObjValue(pacc):pacc, "Ptr*", hWnd)=0
	Return	hWnd
}
Acc_Error(p="") {
	static setting:=0
	return p=""?setting:setting:=p
}
Acc_Children(Acc) {
	if ComObjType(Acc,"Name") != "IAccessible"
		ErrorLevel := "Invalid IAccessible Object"
	else {
		Acc_Init(), cChildren:=Acc.accChildCount, Children:=[]
		if DllCall("oleacc\AccessibleChildren", "Ptr",ComObjValue(Acc), "Int",0, "Int",cChildren, "Ptr",VarSetCapacity(varChildren,cChildren*(8+2*A_PtrSize),0)*0+&varChildren, "Int*",cChildren)=0 {
			Loop %cChildren%
				i:=(A_Index-1)*(A_PtrSize*2+8)+8, child:=NumGet(varChildren,i), Children.Push(NumGet(varChildren,i-8)=9?Acc_Query(child):child), NumGet(varChildren,i-8)=9?ObjRelease(child):
			return Children.MaxIndex()?Children:
		} else
			ErrorLevel := "AccessibleChildren DllCall Failed"
	}
	if Acc_Error()
		throw Exception(ErrorLevel,-1)
}
Acc_Location(Acc, ChildId=0, byref Position="") { ; adapted from Sean's code
	try Acc.accLocation(ComObj(0x4003,&x:=0), ComObj(0x4003,&y:=0), ComObj(0x4003,&w:=0), ComObj(0x4003,&h:=0), ChildId)
	catch
		return
	Position := "x" NumGet(x,0,"int") " y" NumGet(y,0,"int") " w" NumGet(w,0,"int") " h" NumGet(h,0,"int")
	return	{x:NumGet(x,0,"int"), y:NumGet(y,0,"int"), w:NumGet(w,0,"int"), h:NumGet(h,0,"int")}
}
Acc_Parent(Acc)
{
	try parent:=Acc.accParent
	return parent?Acc_Query(parent):
}
Acc_Child(Acc, ChildId=0)
{
	try child:=Acc.accChild(ChildId)
	return child?Acc_Query(child):
}
Acc_Query(Acc)
{
	try return ComObj(9, ComObjQuery(Acc,"{618736e0-3c3d-11cf-810c-00aa00389b71}"), 1)
}

RangeTip(x:="", y:="", w:="", h:="", color:="Red", d:=2) ; from the FindText library, credit goes to feiyue
{
  local
  static id:=0
  if (x="")
  {
    id:=0
    Loop 4
      Gui, Range_%A_Index%: Destroy
    return
  }
  if (!id)
  {
    Loop 4
      Gui, Range_%A_Index%: +Hwndid +AlwaysOnTop -Caption +ToolWindow
        -DPIScale +E0x08000000
  }
  x:=Floor(x), y:=Floor(y), w:=Floor(w), h:=Floor(h), d:=Floor(d)
  Loop 4
  {
    i:=A_Index
    , x1:=(i=2 ? x+w : x-d)
    , y1:=(i=3 ? y+h : y-d)
    , w1:=(i=1 or i=3 ? w+2*d : d)
    , h1:=(i=2 or i=4 ? h+2*d : d)
    Gui, Range_%i%: Color, %color%
    Gui, Range_%i%: Show, NA x%x1% y%y1% w%w1% h%h1%
  }
}

#If IsCapturing
Esc::gosub ButCapture
