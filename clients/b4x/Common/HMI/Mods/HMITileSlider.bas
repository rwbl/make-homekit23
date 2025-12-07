B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	HMITileSlider.bas
' Brief:	HMITile to select RGB values (0..255), using seekbar with live color preview.
' Hints: 	HMITile can not be resized after form loaded.
' Layout:	Horizontal sliders are preferred For routine setpoint adjustments. 
'			This Is the ISA-101-aligned default
'			Use horizontal when:
'			- The operator adjusts values frequently
'			- The value scales left→right (normal expectation)
'			- Space Is limited vertically
'			- The HMITile-based UI grid flows horizontally (your Case)
'			Why?
'			Operators naturally map “increase” To → right.
'			ISA-101 emphasizes natural mapping And operator expectation.
'
'			+----------------------------------+
'			|  Title (e.g.: Setpoint)          |
'			|  Current: 42 %                   |
'			|                                  |
'			|  [=====●------------]            |
'			|                                  |
'			|  Min   0%     Max  100%          |
'			+----------------------------------+
' ================================================================
#End Region

' Properties
#DesignerProperty: Key: TitleText, DisplayName: Title, FieldType: String, DefaultValue: Title
#DesignerProperty: Key: Value, DisplayName: Value, FieldType: Int, DefaultValue: 0
#DesignerProperty: Key: ValueMin, DisplayName: Min Value, FieldType: Int, DefaultValue: 0
#DesignerProperty: Key: ValueMax, DisplayName: Max Value, FieldType: Int, DefaultValue: 100
#DesignerProperty: Key: UnitText, DisplayName: Unit, FieldType: String, DefaultValue: Title
#DesignerProperty: Key: TouchStateChanged, DisplayName: Use TouchState, FieldType: Boolean, DefaultValue: False, Description: Use touchstate released to trigger event instead every value change.

' Events
#Event: ValueChanged (value As Int)

Sub Class_Globals
	' Events
	Private mEventName As String
	Private mCallBack As Object

	' Base
	Public mBase As B4XView
	Public mLbl As B4XView
	Public Tag As Object

	' UI
	Private xui As XUI
	Private LabelTitle As B4XView
	Private LabelValue As B4XView
	Public BarValue As B4XSeekBarEx
	Private LabelUnit As B4XView

	' Designer properties
	Private mValue As Int
	Private mValueMin As Int
	Private mValueMax As Int
	Private mTouchStateChanged As Boolean
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mCallBack = Callback
	mEventName = EventName
End Sub

Public Sub DesignerCreateView (Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	mLbl = Lbl
	Tag = mBase.Tag
	mBase.Tag = Me
	CallSubDelayed2(Me, "AfterLoadLayout", Props)
End Sub

Sub AfterLoadLayout(Props As Map)	'ignore
	mBase.LoadLayout("HMITileSlider")

	' Set local class vars
	mValue 			= Props.Get("Value")
	mValueMin 		= Props.Get("ValueMin")
	mValueMax 		= Props.Get("ValueMax")
	mTouchStateChanged = Props.Get("TouchStateChanged")

	' Default values
	BarValue.Value = mValue
	BarValue.MinValue = mValueMin
	BarValue.MaxValue = mValueMax

	' Set Labels
	LabelTitle.Text = Props.Get("TitleText")
	LabelValue.Text = mValue
	LabelUnit.Text	= Props.Get("UnitText")

	ApplyStyle
	Base_Resize(mBase.Width, mBase.Height)
End Sub

Private Sub Base_Resize (Width As Double, Height As Double)
	HorizontalBaseResize (Width, Height)
End Sub

#Region HorizontalBaseResize
Private Sub HorizontalBaseResize(Width As Double, Height As Double)
	If Not(BarValue.IsInitialized) Then Return

	Dim pad As Int = HMITileUtils.BORDER_WIDTH + 4dip
	Dim l As Int = pad
	Dim y As Int = pad
	Dim w As Int = Width - pad * 2

	' --- compute heights proportionally ---
	Dim availHeight As Double = Height - pad * 2
	Dim titleH As Double	= HMITileUtils.TILE_DEFAULT_SIZE * 0.25
	Dim valueH As Double 	= HMITileUtils.TILE_DEFAULT_SIZE * 0.15
	Dim unitH As Double 	= HMITileUtils.TILE_DEFAULT_SIZE* 0.10
	Dim sliderH As Double 	= availHeight - titleH - valueH - unitH

	' --- Title ---
	LabelTitle.SetLayoutAnimated(0, l, y, w, titleH)
	y = y + titleH

	' --- Value ---
	LabelValue.SetLayoutAnimated(0, l, y, w, valueH)
	y = y + valueH

	' --- Slider ---
	BarValue.mBase.SetLayoutAnimated(0, l, y, w, sliderH)
	y = y + sliderH

	' --- Unit ---
	LabelUnit.SetLayoutAnimated(0, l, y - pad, w, unitH)
    
	UpdateUI
End Sub
#End Region

Private Sub UpdateUI
	mValue = BarValue.Value
	LabelValue.Text	= mValue
	If Not(mTouchStateChanged) Then
		ValueChanged(mValue)
	End If
End Sub

' ================================================================
' PROPERTIES
' ================================================================
Public Sub setTitle(text As String)
	LabelTitle.Text = text
End Sub
Public Sub getTitle As String
	Return LabelTitle.Text
End Sub

Public Sub setValue(value As Int)
	BarValue.Value = value
	mValue = value
	LabelValue.Text = value
End Sub
Public Sub getValue As Int
	Return LabelValue.Text
End Sub

Public Sub setUnit(text As String)
	LabelUnit.Text = text
End Sub
Public Sub getUnit As String
	Return LabelUnit.Text
End Sub

Public Sub setEnabled(enabled As Boolean)
	mBase.Enabled = enabled
	mBase.Alpha = HMITileUtils.SetAlpha(mBase.Enabled)
End Sub
Public Sub getEnabled As Boolean
	Return mBase.Enabled
End Sub

' ================================================================
' HMITile STYLING
' ================================================================
Private Sub ApplyStyle
	mBase.Color = HMITileUtils.COLOR_TILE_NORMAL_BACKGROUND
	' Border styling - All non-buttons clean, borderless tile with border-radius.
	mBase.SetColorAndBorder(mBase.Color, 0, 0, HMITileUtils.BORDER_RADIUS)

	HMITileUtils.ApplyTitleStyle(LabelTitle)
	HMITileUtils.ApplyValueStyle(LabelValue)
	HMITileUtils.ApplyUnitStyle(LabelUnit)
	
	BarValue.ColorBarFill = HMITileUtils.COLOR_SLIDER_TRACK
	BarValue.ColorBar = HMITileUtils.COLOR_SLIDER_ACTIVE
	BarValue.ThumbColor = HMITileUtils.COLOR_SLIDER_KNOB
	BarValue.TickValueColor = HMITileUtils.COLOR_SLIDER_LABEL_TEXT
End Sub

#Region Events
' Seekbar value changes
' Update UI and trigger event.
Private Sub BarValue_ValueChanged (Value As Int)
	UpdateUI
End Sub

' Event triggered by seekbar value changes
Private Sub ValueChanged(value As Int)
	mValue = value
	If SubExists(mCallBack, mEventName & "_ValueChanged") Then
		CallSub2(mCallBack, mEventName & "_ValueChanged", value)
	End If
End Sub

Private Sub BarValue_TouchStateChanged (Pressed As Boolean)
	If mTouchStateChanged Then
		If Not(Pressed) Then
			ValueChanged(mValue)
		End If
	End If
End Sub
#End Region

