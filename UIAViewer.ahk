#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%
SetBatchLines -1
CoordMode, Mouse, Screen

#include <UIA_Interface>

global UIA := UIA_Interface(), IsCapturing := False, Stored := {}
Stored.TreeView := {}

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

Gui Add, GroupBox, x%_xoffsetfirst% y180 w302 h265, UIAutomation Element Info
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

Gui Main:Add, TreeView, x320 y8 w300 h435 hwndhMainTreeView vMainTreeView gMainTreeView

Gui Show,, UIAViewer
Return

MainGuiEscape:
MainGuiClose:
	IsCapturing := False
    ExitApp

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
		
		While (IsCapturing) {
			MouseGetPos, mX, mY, mHwnd, mCtrl
			mEl := UIA.ElementFromPoint(mX, mY)
			
			if (mHwnd != Stored.Hwnd) {
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
	return

MainTreeView:
	if (A_GuiEvent == "S") {
		UpdateElementFields(Stored.Treeview[A_EventInfo])
	}
	return

UpdateElementFields(mEl) {
	if !IsObject(mEl)
		return
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
					return
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

RemoveToolTip:
	ToolTip
	return

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

Esc::
	if IsCapturing {
		gosub ButCapture
	}
	return
