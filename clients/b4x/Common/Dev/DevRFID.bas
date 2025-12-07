B4J=true
Group=Default Group
ModulesStructureVersion=1
Type=Class
Version=10.3
@EndOfDesignText@
#Region Class Header
' ================================================================
' File: 	DevRFID.bas
' Brief:	Parser for the RFID device.
' Author:		Robert W.B. Linn (c) 2025 MIT
' BLE Format:	See BLE_NOTES.md
'#### RFID (0x0E)
'| Command    | Name          | Payload                 | Example             | Description      |
'| ---------- | ------------- | ----------------------- | ------------------- | ---------------- |
'| 0x04       | GET_VALUE     | none                    | `0E 04`             | Request last tag |
'| Not USED
'| -> Response|               | 4–16 bytes (UID)        | `0E 04 01 02 03 04` | Tag UID          |
'| 0x05       | CUSTOM_ACTION | 1 byte (0=reset buffer) | `0E 05 00`          | Clear last tag   |
' ================================================================
#End Region

Sub Class_Globals
	#if B4A
	Private mBLEMgr As BleManager2	'ignore
	#End If
	#if B4J
	Private mBLEMgr As BLEManager	'ignore
	#End If
End Sub

' Initialize
' Parameters:
'	blemgr BLEManager - Instance of the BLE manager (B4J) or BLE manager2 (B4A)
#if B4A
Public Sub Initialize(blemgr As BleManager2)
#End If
#if B4J
Public Sub Initialize(blemgr As BLEManager)
#End If
	mBLEMgr = blemgr
End Sub

' Parses a N-byte BLE payload.
' The payload has structure:
'	<devid><commandid><uidlength><uid><payloadlength><payload>
' deviceid:	0x0E
' command:	0x04
' payload:	N bytes
' 	0E04048C4B71C11202040000000000000000000000000000BF75
'	Byte N (Index N-1)
' 	Byte 1 (0): 	Device ID - 0E
'	Byte 2 (1): 	Command ID - 04
'	Byte 3 (2):		UID Length - 04
'	Byte 4-7 (3): 	UID 8C 4B 71 C1 
'	Byte 8 (7):		Payload Length - 12
'	Byte 9-NN (8):	Payload 02040000000000000000000000000000BF75
'	Payload:
'	Byte 9 (8): 	Group - 02
'	Byte 10 (9):	Command - 04
'	Remaining bytes not used
' Parameters:
'	data - Byte Array
Public Sub Parse(data() As Byte) As Map
	Log($"[DevRFID.Parse] data=${HMITileUtils.ByteConv.HexFromBytes(data)}"$)
	Dim result As Map
	
	result.Initialize
	If data.Length < 3 Then
		Log("[DevRFID.Parse] Error: data too short")
		Return result
	End If
	
'	Log($"[DevRFID.Parse] deviceid=${data(0)}"$)
'	Log($"[DevRFID.Parse] command=${data(1)}"$)
	Dim uidlength As Byte = data(2)
'	Log($"[DevRFID.Parse] uid length=${uidlength}"$)
	Dim payloadindex As Byte = 3 + uidlength
'	Dim payloadlength As Byte = data(payloadindex)
'	Log($"[DevRFID.Parse] payload length=${payloadlength}"$)
'	Log($"[DevRFID.Parse] payload group=${data(index + 1)}"$)
'	Log($"[DevRFID.Parse] payload command=${data(index + 2)}"$)

	result.Put("group", data(payloadindex + 1))
	result.Put("command",data(payloadindex + 2))

	Return result
End Sub

