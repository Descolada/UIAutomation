#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
CoordMode, Mouse, Screen

#include <UIA_Interface>

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
Gui Add, Edit, x+%_xoffset% yp-%_ysoffset% w40 vEditControlType,
Gui Add, Text, x+%_xoffset% yp+%_ysoffset%, LocalizedControlType:
Gui Add, Edit, x+%_xoffset% yp-%_ysoffset% w62 vEditLocalizedControlType,

Gui Add, Text, xm+%_xoffsetfirst% yp+30 Section, Name:
Gui Add, Text,, Value:
Gui Add, Text,, Patterns:
Gui Add, Edit, ys-%_ysoffset% w228 vEditName,
Gui Add, Edit, w228 vEditValue,
Gui Add, Edit, w228 vEditPatterns,

Gui Add, Text, xm+%_xoffsetfirst% yp+30 Section, BoundingRectangle:
Gui Add, Text,, ClassName:
Gui Add, Text,, HelpText:

Gui Add, Edit, ys-%_ysoffset% w174 vEditBoundingRectangle,
Gui Add, Edit, w174 vEditClassName,
Gui Add, Edit, w174 vEditHelpText,

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
SB_SetParts(370)

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
		GuiControl, Main:, EditLocalizedControlType,
		GuiControl, Main:, EditName,
		GuiControl, Main:, EditValue,
		GuiControl, Main:, EditPatterns,
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
		GuiControl, Main:, EditControlType, % mEl.CurrentControlType
		GuiControl, Main:, EditLocalizedControlType, % mEl.CurrentLocalizedControlType
		GuiControl, Main:, EditName, % mEl.CurrentName
		GuiControl, Main:, EditValue, % mEl.GetCurrentValue()
		patterns := ""
		for k, v in mEl.GetSupportedPatterns()
			patterns .= ", " v
		GuiControl, Main:, EditPatterns, % SubStr(patterns, 3)
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
		if !(children := el.GetChildren())
			return
		for k, v in children
			ConstructTreeView(v, TWEl)
	}
}

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
