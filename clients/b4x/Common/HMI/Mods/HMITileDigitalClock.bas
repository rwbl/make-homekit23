B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File:     HMITileDigitalClock.bas
' Brief:    A digital clock HMITile (HH:MM or HH:MM:SS)
' Notes:    Very similar to HMITileLabel, but automatically updates
' ================================================================
#End Region

#DesignerProperty: Key: ShowSeconds, DisplayName: Show Seconds, FieldType: Boolean, DefaultValue: False
#DesignerProperty: Key: BlinkColon, DisplayName: Blink Colon, FieldType: Boolean, DefaultValue: False

#Event: Click

Sub Class_Globals
	Private xui As XUI

	Public mBase As B4XView
	Private mLbl As B4XView
	Public Tag As Object

	Private mEventName As String
	Private mCallBack As Object

	Private LabelText As B4XView

	Private mClockTimer As Timer
	Private mClockBlink As Boolean
	Private mShowSec As Boolean
	Private mDoBlink As Boolean
End Sub

Public Sub Initialize(Callback As Object, EventName As String)
	mEventName = EventName
	mCallBack = Callback
	mClockTimer.Initialize("TimerClock", 1000)
End Sub

Public Sub DesignerCreateView(Base As Object, Lbl As Label, Props As Map)
	mBase = Base
	mLbl = Lbl
	Tag = mBase.Tag
	mBase.Tag = Me

	' Load the customview layout(s) via CallSubDelayed.
	CallSubDelayed2(Me, "AfterLoadLayout", Props)
End Sub

Sub AfterLoadLayout(Props As Map)
	mBase.LoadLayout("HMITileLabel")

	' Get the designer properties
	mShowSec = Props.Get("ShowSeconds")
	mDoBlink = Props.Get("BlinkColon")

	ApplyStyle

	' Resize to get the sizing right
	Base_Resize(mBase.Width, mBase.Height)
	
	StartClock
End Sub

Public Sub Base_Resize (Width As Double, Height As Double)
	If Not(LabelText.IsInitialized) Then Return
	mLbl.SetLayoutAnimated(0, 0, 0, Width, Height)
End Sub

' ================================================================
' Tile STYLING
' ================================================================
#Region Tile Styling
' ApplyStyleLabel
' For all HMITiles the title style are consistent
' Parameters:
'	view B4XView - label
Public Sub ApplyStyle
	HMITileUtils.ApplyValueStyle(LabelText)
	mBase.Color = HMITileUtils.COLOR_TILE_NORMAL_BACKGROUND
	' Border styling - All non-buttons clean, borderless tile with border-radius.
	mBase.SetColorAndBorder(mBase.Color, 0, 0, HMITileUtils.BORDER_RADIUS)
End Sub
#End Region

#Region Properties
Public Sub setEnabled(enabled As Boolean)
	mBase.Enabled = enabled
	HMITileUtils.SetAlpha(mBase.enabled)
End Sub
Public Sub getEnabled As Boolean
	Return mBase.Enabled
End Sub
#End Region

#Region Clock
Public Sub StartClock
	mClockTimer.Enabled = True
End Sub
Public Sub StopClock
	mClockTimer.Enabled = False
End Sub

Private Sub TimerClock_Tick
	UpdateClock
End Sub

Private Sub UpdateClock
	Dim now As Long = DateTime.Now
	Dim h As Int = DateTime.GetHour(now)
	Dim m As Int = DateTime.GetMinute(now)
	Dim s As Int = DateTime.GetSecond(now)

	Dim colon As String = ":"
	If mDoBlink Then
		If mClockBlink = False Then colon = " "
		mClockBlink = Not(mClockBlink)
	End If

	Dim txt As String
	If mShowSec Then
		txt = NumberFormat2(h, 2, 0, 0, False) & colon & NumberFormat2(m, 2, 0, 0, False) & colon & NumberFormat2(s, 2, 0, 0, False)
	Else
		txt = NumberFormat2(h, 2, 0, 0, False) & colon & NumberFormat2(m, 2, 0, 0, False)
	End If

	' mLbl.Text = txt
	LabelText.Text = txt
End Sub
#End Region

#Region Events
#if B4J
Private Sub LabelText_MouseClicked (EventData As MouseEvent)
	LabelText_Click
End Sub
#End If

' ================================================================
' B4X - use click only
' ================================================================

Private Sub LabelText_Click
	If SubExists(mCallBack, mEventName & "_Click") Then
		CallSub(mCallBack, mEventName & "_Click")
	End If
End Sub
#End Region

