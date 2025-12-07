B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:        	GlobalStoreHandler.bas
' Project:     	make-homekit32
' Brief:       	Global store handler for MQTT payload buffering.
' Date:        	2025-11-09
' Author:      	Robert W.B. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx.b4x
'
' Description:
'   Handles a simple circular buffer (round-robin) of byte arrays.
'   Each slot stores the latest MQTT payloads for inspection or reuse.
'	Three slots are used with index 0,1,2.
'
' Usage:
'   Call SetIndex to advance the slot index.
'   Call GetSlot(index) to retrieve a specific slot.
'	Call Put to set data into a slot.
'
' ================================================================
#End Region

#Region Declarations
Private Sub Process_Globals
	' Global store index control
	Public Index As Byte = 0
	
	' Number of slots used = 3 with index 0,1,2
	Private Const MIN_INDEX As Byte = 0
	Private Const MAX_INDEX As Byte = 2
End Sub
#End Region

#Region GlobalStore
' Initialize
' Initialize the global store handler. Set debug flag.
Public Sub Initialize
	GlobalStoreEx.Debug = False
End Sub

' SetIndex
' Advances Index in a circular fashion (minindex → maxindex → minindex).
Public Sub SetIndex
	Index = Index + 1
	If Index > MAX_INDEX Then
		Index = MIN_INDEX
	End If
End Sub

' GetSlot
' Returns a reference to the requested slot (as byte array).
' Parameters:
' 	idx - Index range: 0–4
' Returns:
'	Null if index is invalid.
Public Sub GetSlot(idx As Byte) As Byte()
	Select idx
		Case 0
			Return GlobalStoreEx.Slot0
		Case 1
			Return GlobalStoreEx.Slot1
		Case 2
			Return GlobalStoreEx.Slot2
		Case 3
			Return GlobalStoreEx.Slot3
		Case 4
			Return GlobalStoreEx.Slot4
		Case Else
			Return Null
	End Select
End Sub

' Put
' Put data into the next slot (round-robin)
' Parameters:
' 	data - Byte array
Public Sub Put(data() As Byte)
	' Set the next global store index (slot to use)
	SetIndex
	
	' Put the data into the slot
	GlobalStoreEx.Put(Index, data)

	Log("[GlobalStoreHandler.Put][I] ", _
	    "slot=", Index, ", bufferlength=", GlobalStoreEx.BufferLength, ", Max=", GlobalStoreEx.BUFFER_SIZE, _
		", data size=", data.Length, ", hex=", Convert.BytesToHex(data))

'	Log("[GlobalStoreHandler.Put][I] ", _
'	    "slot=", Index, ", bufferlength=", GlobalStoreEx.BufferLength, ", Max=", GlobalStoreEx.BUFFER_SIZE, _
'		", data size=", data.Length, ", hex=", Convert.BytesToHex(data), ", string=", Convert.BytesToString(data))
End Sub

' PutSlot4
' Put data into the slot 4.
' This is a special slot that can be used for RFID.
' Use GetSlot(4) to get the data.
' Parameters:
' 	data - Byte array
Public Sub PutSlot4(data() As Byte)
	Dim idx As Byte = 4
	GlobalStoreEx.Put(idx, data)

	Log("[GlobalStoreHandler.Put][I] ", _
	    "slot=", idx, ", bufferlength=", GlobalStoreEx.BufferLength, ", Max=", GlobalStoreEx.BUFFER_SIZE, _
		", data size=", data.Length, ", hex=", Convert.BytesToHex(data))
End Sub
#End Region
