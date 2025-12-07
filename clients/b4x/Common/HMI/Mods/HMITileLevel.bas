B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	HMITileLevel.bas
' Brief:	HMITile with a level bar 0-100%.
'			Style can be set to Normal, Warning, Alarm or Dimmed.
' Layout:
'+------------------+
'|       Title      |  	<< 25 % (top-aligned Or centered)
'|       Level      |	<< 50% (midlle centered)
'|        bar       |  
'| 	   Value Unit   |	<< 25% (center Or bottom)
'+------------------+
' ================================================================
#End Region

' Designer properties
#DesignerProperty: Key: TitleText, DisplayName: Title, FieldType: String, DefaultValue: Level
#DesignerProperty: Key: Value, DisplayName: Value, FieldType: Float, DefaultValue: 0
#DesignerProperty: Key: UnitText,  DisplayName: Unit,  FieldType: String, DefaultValue: 
#DesignerProperty: Key: TypeStyle, DisplayName: HMITile Style, FieldType: String, List: Normal|Warning|Alarm|Dimmed, DefaultValue: Normal

' Events
#Event: Click(EventData As MouseEvent)

Sub Class_Globals
	Private mEventName As String
	Private mCallBack As Object

	Public mBase As B4XView
	Public mLbl As B4XView

	Private xui As XUI
	Public Tag As Object

	' Views inside HMITileSensor.bjl
	Private LabelTitle As B4XView
	Private PaneBar As B4XView
	Private PaneFill As B4XView
	Private LabelValue As B4XView

	' Designer values
	Private mValue As Float
	Private mUnitText As String
	Private mTypeStyle As String
End Sub

Public Sub Initialize(Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
End Sub

Public Sub DesignerCreateView(Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	mLbl = Lbl
	Tag = mBase.Tag
	mBase.Tag = Me
	CallSubDelayed2(Me, "AfterLoadLayout", Props)
End Sub

Private Sub AfterLoadLayout(Props As Map)	'ignore
	mBase.LoadLayout("HMITileLevel")

	' Store designer properties
	LabelTitle.Text = Props.Get("TitleText")
	LabelValue.Text = Props.Get("Value")
	mValue			= Props.Get("Value")
	mUnitText		= Props.Get("UnitText")
	setValue(mValue)
	mTypeStyle		= Props.Get("TypeStyle")

	' Ensure the font is set to FA
	ApplyStyle(mTypeStyle)
	Base_Resize(mBase.Width, mBase.Height)
End Sub

Private Sub Base_Resize(Width As Double, Height As Double)
	If Not(LabelValue.IsInitialized) Then Return

	Dim pad As Int = HMITileUtils.BORDER_WIDTH + 4dip

	LabelTitle.SetLayoutAnimated(0, pad, pad, Width - pad*2, Height * 0.25)

	UpdateLevel
				
	LabelValue.SetLayoutAnimated(0, pad, (Height*0.75) - pad, Width - pad*2, Height*0.25)
End Sub

' Update level bar with level 0 check.
Private Sub UpdateLevel

	Dim pad As Int = HMITileUtils.BORDER_WIDTH + 4dip
	Dim l As Int = mBase.width / 4
	Dim t As Int = LabelTitle.Top + LabelTitle.Height + pad
	Dim w As Int = mBase.width / 2
	Dim h As Int = (mBase.height * 0.50) - (pad * 2)
	
	Dim pct As Float = 0
	If mValue > 0 Then
		pct = mValue / 100
	End If
	Dim fillheight As Float = h * pct

	' Bar
	PaneBar.SetLayoutAnimated(0, l, t, w, h)

	' Level
	pad = HMITileUtils.BORDER_WIDTH
	l = l + pad
	t = t + h - fillheight
	w = w - pad * 2
	h = IIf(fillheight > 0, fillheight, 0)
	If pct == 1 Then 
		t = t + (pad)
		h = h - pad * 2
	End If
	PaneFill.SetLayoutAnimated(0, l, t, w, h)
End Sub

' ===================================================================
' Public API
' ===================================================================
' Title
Public Sub setTitle(title As String)
	LabelTitle.Text = title
End Sub
Public Sub getTitle As String
	Return LabelTitle.Text
End Sub

' Value
Public Sub setValue(value As Float)
	mValue = value
	UpdateLevel
	Dim v As String = mValue
	If v.Contains(".") Then
		LabelValue.Text = $"${mValue}${IIf(mUnitText.Length > 0, $" ${mUnitText}"$, "")}"$
	Else
		LabelValue.Text = $"${NumberFormat(mValue,0,0)}${IIf(mUnitText.Length > 0, $" ${mUnitText}"$, "")}"$
	End If
End Sub
Public Sub getValue As Float
	Return mValue
End Sub

Public Sub setUnit(unit As String)
	mUnitText = unit
	LabelValue.Text = $"${mValue}${IIf(mUnitText.Length > 0, $" ${mUnitText}"$, "")}"$
End Sub
Public Sub getUnit As String
	Return LabelValue.Text
End Sub

Public Sub setEnabled(enabled As Boolean)
	mBase.Enabled = enabled
	mBase.Alpha = HMITileUtils.SetAlpha(mBase.Enabled)
End Sub
Public Sub getEnabled As Boolean
	Return mBase.Enabled
End Sub

Public Sub SetTileStyleNormal
	ApplyTileStyle(HMITileUtils.TYPESTYLE_NORMAL)
	ApplyBarStyle(HMITileUtils.TYPESTYLE_NORMAL)
End Sub

Public Sub SetTileStyleWarning
	ApplyTileStyle(HMITileUtils.TYPESTYLE_WARNING)
End Sub

Public Sub SetTileStyleAlarm
	ApplyBarStyle(HMITileUtils.TYPESTYLE_NORMAL)
	ApplyTileStyle(HMITileUtils.TYPESTYLE_ALARM)
End Sub

Public Sub setTypeStyle(value As String)
	mTypeStyle = value
	ApplyStyle(mTypeStyle)
End Sub
Public Sub getTypeStyle As String
	Return mTypeStyle
End Sub

' ================================================================
' HMITile STYLING ISA-101
' ================================================================
#Region HMITile Styling
Public Sub ApplyStyle(tilestate As String)
	HMITileUtils.ApplyTitleStyle(LabelTitle)
	HMITileUtils.ApplyValueStyle(LabelValue)

	Dim state As Int = HMITileUtils.StateStyleToState(tilestate)
	' Select the state to set the PaneFillColor
	Select state
		Case HMITileUtils.STATE_NORMAL
			PaneFill.Color = HMITileUtils.COLOR_TILE_ENABLED_BACKGROUND
		Case HMITileUtils.STATE_WARNING
			PaneFill.Color = HMITileUtils.COLOR_TILE_WARNING_BACKGROUND
		Case HMITileUtils.STATE_ALARM
			PaneFill.Color = HMITileUtils.COLOR_TILE_ALARM_BACKGROUND
		Case HMITileUtils.STATE_DISABLED
			PaneFill.Color = HMITileUtils.COLOR_TILE_DISABLED_BACKGROUND
	End Select

	' --- Tile ---
	mBase.Color = HMITileUtils.COLOR_TILE_NORMAL_BACKGROUND
	' Border styling - All non-buttons clean, borderless tile with border-radius.
	mBase.SetColorAndBorder(mBase.Color, 0, 0, HMITileUtils.BORDER_RADIUS)

	' --- Bar (thin fixed) ---
	PaneBar.SetColorAndBorder( _
        mBase.Color, _ 	' HMITileUtils.COLOR_BACKGROUND_HMITile_DEFAULT, _
        1dip, _
        HMITileUtils.COLOR_TEXT_SECONDARY, _
        0dip)
End Sub

Public Sub ApplyTileStyle(tilestate As String)
	Dim state As Int = HMITileUtils.StateStyleToState(tilestate)
	Select state
		Case HMITileUtils.STATE_NORMAL
			mBase.Color = HMITileUtils.COLOR_TILE_NORMAL_BACKGROUND
			LabelTitle.TextColor = HMITileUtils.COLOR_TEXT_SECONDARY
			LabelValue.TextColor = HMITileUtils.COLOR_TEXT_SECONDARY
		Case HMITileUtils.STATE_WARNING
			mBase.Color = HMITileUtils.COLOR_TILE_WARNING_BACKGROUND
			LabelTitle.TextColor = HMITileUtils.COLOR_TEXT_WARNING
			LabelValue.TextColor = HMITileUtils.COLOR_TEXT_WARNING
		Case HMITileUtils.STATE_ALARM
			mBase.Color = HMITileUtils.COLOR_TILE_ALARM_BACKGROUND
			LabelTitle.TextColor = HMITileUtils.COLOR_TEXT_ALARM
			LabelValue.TextColor = HMITileUtils.COLOR_TEXT_ALARM
		Case HMITileUtils.STATE_DISABLED
			mBase.Color = HMITileUtils.COLOR_TILE_DISABLED_BACKGROUND
			LabelTitle.TextColor = HMITileUtils.COLOR_TEXT_DISABLED
			LabelValue.TextColor = HMITileUtils.COLOR_TEXT_DISABLED
	End Select
	' --- Tile ---
	mBase.SetColorAndBorder( _
        mBase.Color, _
        HMITileUtils.BORDER_WIDTH, _
        HMITileUtils.COLOR_BORDER_DEFAULT, _
        HMITileUtils.BORDER_RADIUS)

	' --- Bar (thin fixed) ---
	PaneBar.SetColorAndBorder( _
        mBase.Color, _ 	' HMITileUtils.COLOR_BACKGROUND_HMITile_DEFAULT, _
        1dip, _
        HMITileUtils.COLOR_TEXT_SECONDARY, _
        0dip)
End Sub

Public Sub ApplyBarStyle(tilestate As String)
	Dim state As Int = HMITileUtils.StateStyleToState(tilestate)
	Select state
		Case HMITileUtils.STATE_NORMAL
			PaneFill.Color = HMITileUtils.COLOR_TILE_ENABLED_BACKGROUND
		Case HMITileUtils.STATE_WARNING
			PaneFill.Color = HMITileUtils.COLOR_TILE_WARNING_BACKGROUND
		Case HMITileUtils.STATE_ALARM
			PaneFill.Color = HMITileUtils.COLOR_TILE_ALARM_BACKGROUND
		Case HMITileUtils.STATE_DISABLED
			PaneFill.Color = HMITileUtils.COLOR_TILE_DISABLED_BACKGROUND
	End Select

	' --- Bar (thin fixed) ---
	PaneBar.SetColorAndBorder( _
        mBase.Color, _ 	' HMITileUtils.COLOR_BACKGROUND_HMITile_DEFAULT, _
        1dip, _
        HMITileUtils.COLOR_TEXT_SECONDARY, _
        0dip)
End Sub

#End Region

#Region Events
#if B4J
Private Sub LabelIcon_MouseClicked(EventData As MouseEvent)
	LabelIcon_Click
End Sub
#End If

' ================================================================
' B4X - use click only
' ================================================================

Private Sub LabelIcon_Click
	If SubExists(mCallBack, mEventName & "_Click") Then
		CallSub(mCallBack, mEventName & "_Click")
	End If
End Sub
#End Region
