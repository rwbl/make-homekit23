B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File:     	HMITileButton.bas
' Brief:    	HMITile that behaves like a button (clickable).
'           	Supports Normal, Warning, Error, Dimmed styles.
' Properties:	All ISA-101 style properties are defined in HMITileUtils.
'				The designer properties are not used.
'				TitleText - Base properties set from Label property.
'							Text set from designer property TitleText.
'				StateText - Base properties set from Label property.
'							Text set from designer property Text (Label)
'
' Modes:		This HMITileButton is a single CustomView with multiple behaviors:
'				Normal Button - Set text As normal Label
'					HMITileButton1.Text = "Start"
'				Toggle Button - Using FA toggle icons
'					HMITileButton1.Text = IIf(newState, Chr(0xF205), Chr(0xF204))
'				Switch - Use “ON / OFF”
'					HMITileButton1.Text = IIf(newState, "ON", "OFF")
'				Light Bulb Control
'					HMITileButton1.Text = IIf(newState, Chr(0xF0EB), Chr(0xF111))
'				Lock/Unlock
'					HMITileButton1.Text = IIf(locked, Chr(0xF023), Chr(0xF09C)) 
'				Open/Close
'					HMITileButton1.Text = IIf(isOpen, Chr(0xF2C2), Chr(0xF2C1))
'
' Example Toggle Button with FontAwesome font
'	Private HMITileButtonToggle As HMITileButton
'	' Set LabelState font, state False And click To set the initial icon off
'	HMITileButtonToggle.SetStateFontFontAwesome
'	HMITileButtonToggle.State = False
'	HMITileButtonToggle_Click
'
'	' Button Click Event
'	' Button with fontawesome looks like a toggle switch.
'	' Important to set state
'	Private Sub HMITileButtonToggle_Click
'		HMITileButtonToggle.SetState(HMITileButtonToggle.State)
'		HMITileButtonToggle.StateText = IIf(HMITileButtonToggle.State, Chr(0xF205), Chr(0xF204)) ' FA toggle-on / toggle-off
'		HMITileEventViewer1.Insert($"[HMITileButtonToggle] state=${HMITileButtonToggle.State}"$, HMITileUtils.EVENT_LEVEL_INFO)
'	End Sub
'
' Example Callback: UI follows actual device state
' 	' Button with text change
' 	Private Sub HMITileButton1_Click
' 		Dim state As Boolean = Not(DevYellowLed.Get)
'		DevYellowLed.Set(state)
'		HMITileButton1.Text = IIf(state, "ON", "OFF")
'		HMITileButton1.SetStateColor(state)
' 	End Sub
' ================================================================
#End Region

' Designer Properties
#DesignerProperty: Key: TitleText, DisplayName: Title, FieldType: String, DefaultValue: Title
#DesignerProperty: Key: StateText, DisplayName: State, FieldType: String, DefaultValue: Button, Description: Use designer property Label
#DesignerProperty: Key: TypeStyle, DisplayName: Button Style, FieldType: String, List: Normal|Warning|Alarm|Dimmed, DefaultValue: Normal

' Events
#Event: Click

Sub Class_Globals
	' Base
	Public mBase As B4XView
	Public mLbl As B4XView
	Public Tag As Object

	' Events
	Private mEventName As String	'ignore
	Private mCallBack As Object		'ignore

	' UI
	Private xui As XUI
	Private LabelTitle As B4XView
	Private LabelState As B4XView

	' Fixed properties
	Private mTypeStyle As String
	Private mIsPressed As Boolean = False			'ignore
	Private mState As Boolean = False
End Sub

Public Sub Initialize (Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
End Sub

Public Sub DesignerCreateView (Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	mLbl = Lbl
	Tag = mBase.Tag
	mBase.Tag = Me
	CallSubDelayed2(Me, "AfterLoadLayout", Props)
End Sub

Private Sub AfterLoadLayout(Props As Map)	'ignore
	mBase.LoadLayout("HMITileButton")
	LabelTitle.Text	= Props.Get("TitleText")
	LabelState.Text	= Props.Get("StateText")
	mTypeStyle 		= Props.Get("TypeStyle")
	ApplyStyle(mTypeStyle)
	Base_Resize(mBase.Width, mBase.Height)
End Sub

Private Sub Base_Resize(Width As Double, Height As Double)
	If Not(LabelTitle.IsInitialized) Or Not(LabelState.IsInitialized) Then Return

	Dim pad As Int = HMITileUtils.BORDER_WIDTH + 4dip
	
	LabelTitle.SetLayoutAnimated(0, pad, pad, Width - pad*2, Height * 0.25)
	LabelState.SetLayoutAnimated(0, pad, Height*0.25, Width - pad*2, Height*0.50)
End Sub

' ================================================================
' Getter / Setter
' ================================================================
Public Sub setTitleText(value As String)
	LabelTitle.Text = value
End Sub
Public Sub getTitleText As String
	Return LabelTitle.Text
End Sub

Public Sub setStateText(value As String)
	LabelState.Text = value
End Sub
Public Sub getStateText As String
	Return LabelState.Text
End Sub

' Get or set the state of the button.
Public Sub setState(state As Boolean)
	mState = state
	HMITileUtils.ApplyStyleStateOnOff(mBase, LabelState, state)
End Sub
Public Sub getState As Boolean
	Return mState
End Sub

Public Sub SetStateFontFontAwesome
	LabelState.Font = xui.CreateFontAwesome(HMITileUtils.TEXT_SIZE_ICON)
End Sub

Public Sub SetStateFontDefault
	LabelState.Font = xui.CreateDefaultFont(HMITileUtils.TEXT_SIZE_STATE)
End Sub

Public Sub SetStateColor(success As Boolean)
	HMITileUtils.ApplyStyleStateOnOff(mBase, LabelState, success)
End Sub

Public Sub setEnabled(enabled As Boolean)
	mBase.Enabled = enabled
	mBase.Alpha = HMITileUtils.SetAlpha(mBase.Enabled)
End Sub
Public Sub getEnabled As Boolean
	Return mBase.Enabled
End Sub

Public Sub SetInfo(text As String)
	setStateText(text)
	setTypeStyle(HMITileUtils.TYPESTYLE_NORMAL)
End Sub

Public Sub SetWarning(text As String)
	setStateText(text)
	setTypeStyle(HMITileUtils.TYPESTYLE_WARNING)
End Sub

Public Sub SetAlarm(text As String)
	setStateText(text)
	setTypeStyle(HMITileUtils.TYPESTYLE_ALARM)
End Sub

Public Sub setTypeStyle(value As String)
	mTypeStyle = value
	ApplyStyle(mTypeStyle)
End Sub
Public Sub getTypeStyle As String
	Return mTypeStyle
End Sub

' ================================================================
' HMITile STYLING
' ================================================================
#Region HMITile Styling
Public Sub ApplyStyle(tilestate As String)
	HMITileUtils.ApplyTitleStyle(LabelTitle)
	HMITileUtils.ApplyValueStyle(LabelState)

	' Convert designer string → HMITile state constant
	Dim state As Int = HMITileUtils.StateStyleToState(tilestate)
	' --- Apply State Colors ---
	Select state

		Case HMITileUtils.STATE_NORMAL
			LabelState.TextColor = HMITileUtils.COLOR_TILE_NORMAL_TEXT
			mBase.Color = HMITileUtils.COLOR_TILE_NORMAL_BACKGROUND

		Case HMITileUtils.STATE_WARNING
			LabelState.TextColor = HMITileUtils.COLOR_TILE_WARNING_TEXT
			mBase.Color = HMITileUtils.COLOR_TILE_WARNING_BACKGROUND

		Case HMITileUtils.STATE_ALARM
			LabelState.TextColor = HMITileUtils.COLOR_TILE_ALARM_TEXT
			mBase.Color = HMITileUtils.COLOR_TILE_ALARM_BACKGROUND

		Case HMITileUtils.STATE_DISABLED
			LabelState.TextColor = HMITileUtils.COLOR_TILE_DISABLED_TEXT
			mBase.Color = HMITileUtils.COLOR_TILE_DISABLED_BACKGROUND
	End Select
	mBase.SetColorAndBorder(mBase.Color, 0, 0, HMITileUtils.BORDER_RADIUS)
'	mBase.SetColorAndBorder( _
'        mBase.Color, _
'        HMITileUtils.BORDER_WIDTH, _
'        HMITileUtils.COLOR_STATE_OFF_BORDER, _
'        HMITileUtils.BORDER_RADIUS)
End Sub
#End Region

#Region Events
' ================================================================
' B4J
' Mouse Events (Button Behavior)
' ================================================================
#if B4J
Private Sub LabelState_MouseClicked(EventData As MouseEvent)
	LabelState_Click
End Sub

' Next subs are nice-to-haves

Private Sub LabelState_MouseEntered (EventData As MouseEvent)
	If mBase.Enabled Then mBase.Alpha = 0.85
End Sub

Private Sub LabelState_MousePressed (EventData As MouseEvent)
	mIsPressed = True
	mBase.Alpha = 0.7   ' visual feedback
End Sub

Private Sub LabelState_MouseReleased (EventData As MouseEvent)
	mIsPressed = False
	mBase.Alpha = 1.0
End Sub

Private Sub LabelTitle_MouseEntered (EventData As MouseEvent)
	LabelState_MouseEntered(EventData)
End Sub

Private Sub LabelTitle_MouseClicked (EventData As MouseEvent)
	LabelState_MouseClicked(EventData)
End Sub

Private Sub LabelTitle_MousePressed (EventData As MouseEvent)
	LabelState_MousePressed(EventData)
End Sub

Private Sub LabelTitle_MouseReleased (EventData As MouseEvent)
	LabelState_MouseReleased(EventData)
End Sub
#End If

' ================================================================
' B4X - use click only
' ================================================================

Private Sub LabelState_Click
	mState = Not(mState)
	If SubExists(mCallBack, mEventName & "_Click") Then
		CallSub(mCallBack, mEventName & "_Click")
	End If
End Sub

Private Sub LabelTitle_Click
	LabelState_Click	
End Sub
#End Region
