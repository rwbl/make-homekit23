B4R=true
Group=Default Group
ModulesStructureVersion=1
Type=StaticCode
Version=4
@EndOfDesignText@
#Region Module Header
' ================================================================
' File:         DevRFID.bas
' Project:      make-homekit32
' Brief:        Handles RFID card scanning and reporting.
' Date:         2025-11-13
' Author:       Robert W.W. Linn (c) 2025 MIT
' Dependencies: rGlobalStoreEx, rMFRC522Mifare_I2C
' Description:	Reads card UID and sector/block data.
'				The last read tag data is stored in the global store slot 4.
'				This is a special slot.
' Hardware: 	https://wiki.keyestudio.com/Ks0067_keyestudio_RC522_RFID_Module_for_Arduino
' RFID Card Type Mifare:
'| UID Type                   | Length   | Also called            | Used by                                             |
'| -------------------------- | -------- | ---------------------- | --------------------------------------------------- |
'| **Single Size (4 bytes)**  | 4 bytes  | *NUID*, *Single UID*   | MIFARE Classic 1K/4K, some Ultralight               |
'| **Double Size (7 bytes)**  | 7 bytes  | *Cascaded UID*, *UID2* | Newer MIFARE Classic, Ultralight C, NTAG213/215/216 |
'| **Triple Size (10 bytes)** | 10 bytes | *Triple UID*, *UID3*   | High-security DESFire EV1/EV2                       |
' ================================================================
#End Region

Sub Process_Globals
	Public Rfid As MFRC522Mifare_I2C				
	Public RFID_I2C_ADDRESS As Byte					' 0x28
	Public RFID_DEFAULT_BLOCK_TO_READ As Byte = 4
End Sub

' Initialize
' Initializes the module.
' Parameters:
'   address - I2C address of the device
Public Sub Initialize(address As Byte)
	' ---------- RFID Mifare handled via I2C bus with default address.
	Rfid.Initialize(address, "RFID_CardPresent")
	Log("[DevRFID.Initialize][I] OK, address=", Convert.OneByteToHex(address))
End Sub

' ------------------------------------------------
' Core hardware control (always compiled)
' ------------------------------------------------
#Region Device Control
' RFID_CardPresent (Event)
' Handle RFID card detection event
' Parameters:
'	UID - Unique device UID as HEX
'	CardType - Expect card type 4 Mifare
Sub RFID_CardPresent(UID() As Byte, CardType As Byte)
	Log("[DevRFID.RFID_CardPresent] UID=", Convert.ByteConv.HexFromBytes(UID))
	' [Main.rfid_CardPresent] UID: AB1A8832
	
	Log("[DevRFID.RFID_CardPresent] CardType=", CardType)
	' [Main.rfid_CardPresent] CardType: 4
	' This is a Mifare card

	If CardType = Rfid.PICC_TYPE_MIFARE_1K Then
		Log("[DevRFID.RFID_CardPresent] CardTypeName=Mifare 1K")
		RFID_MifareRead(UID)
	End If
End Sub

' Handle card reading block 4
Sub RFID_MifareRead(UID() As Byte)
	If Rfid.IsMifare Then
		If Rfid.MifareAuthenticate(RFID_DEFAULT_BLOCK_TO_READ) Then
			Dim data(18) As Byte
			Dim len As Byte = Rfid.MifareRead(4, data)
			If len > 0 Then
				Log("[DevRFID.RFID_MifareRead][I] Block 4 HEX=", Convert.ByteConv.HexFromBytes(data))
				' [Main.rfid_CardPresent][I] Block 4 HEX=02040000000000000000000000000000BF75
				Log("[DevRFID.RFID_MifareRead][I] Block 4 byte 1=", data(0))	'2
				Log("[DevRFID.RFID_MifareRead][I] Block 4 byte 2=", data(1))	'4

				#If MQTT
				PublishToMQTT(UID, data)
				#End If
				
				#If BLE
				WriteToBLE(UID, data)
				#End If
			End If
			' Important to clean up
			Rfid.MifareHalt
		Else
			Log("[DevRFID.RFID_MifareRead][E] Mifare Authenticate failed.")
		End If
	Else
		Log("[DevRFID.RFID_MifareRead][W] Not a Mifare card")
	End If
End Sub
#End Region

' ------------------------------------------------
' MQTT integration 
' ------------------------------------------------
#If MQTT
#Region MQTT Control
' PublishToMQTT
' Write, publish, to MQTT the UID, group and command
' Parameters
'	UID - Unique device UID as HEX
'	data - data containing 2 bytes for group and command
Private Sub PublishToMQTT(uid() As Byte, data() As Byte)
	' MQTT Publish
	Dim payload() As Byte = MQTTTopics.PAYLOAD_RFID_STATUS
	payload = Convert.ReplaceString(payload, "#U", Convert.ByteConv.HexFromBytes(uid).GetBytes)
	Dim group As String = data(0)
	payload = Convert.ReplaceString(payload, "#G", group.GetBytes)
	Dim command As String = data(1)
	payload = Convert.ReplaceString(payload, "#C", command.GetBytes)
	MQTTClient.Publish(Array As String(MQTTTopics. TOPIC_RFID_STATUS), _
								   Array As String(Convert.ByteConv.StringFromBytes(payload)))
	Log("[DevRFID.PublishToMQTT][I] json=", payload)
	' [DevRFID.PublishToMQTT][I] json={"u":"8C4B71C1","g":2,"c":4}
				
	' Depending command, an action can be taken to do something in the house.

End Sub
#End Region
#End If

' ------------------------------------------------
' BLE integration 
' ------------------------------------------------
#If BLE
#Region BLE Control
' ProcessBLE
' DeviceID: 0x0E
' Get the value (Command 0x04)
' 	Length: 2 Bytes
' 	Byte 0 Device:	0x0E
' 	Byte 1 Command:	0x04 > Get
'	Returns last tag read
'	Example Get Value  = 0E04
'
' Parameters:
'   storeindex - Index of the global store buffer.
Public Sub ProcessBLE(storeindex As Byte)
	Dim payload() As Byte = GlobalStoreHandler.GetSlot(storeindex)
	Log("[DevRFID.ProcessBLE] storeindex=", storeindex, ", payload=", Convert.BytesToHex(payload))
	' [DevRFID.ProcessBLE] storeindex=1, payload=0E04

	Dim command As Byte = payload(1)
	Select command
		Case CommBLE.CMD_GET_VALUE
			Dim data() As Byte = GlobalStoreHandler.GetSlot(4)
			WriteToBLE(Null, data)
	End Select
End Sub

' WriteToBLE
' Write DeviceID + Command + UID + Data to BLE client in compact format.
' Format:
'   [ID][CMD][UL][UID bytes...][DL][DATA bytes...]
'	UL = Length UID byte array
'	DL = Length Data byte array
' Example:
'	[CommBLE.BLEServer_Write] data=0E04048C4B71C11202040000000000000000000000000000BF75
'	Payload has 26 bytes.
'	ID		= 0E
'	CMD 	= 04
'	UL		= 04
'	UID		= 8C 4B 71 C1
'	DL 		= 12
'	Data	= 02040000000000000000000000000000BF75
'			  02 04 00 00 00 00 00 00 00 00 00 00 00 00 00 00 BF75
Public Sub WriteToBLE(uid() As Byte, data() As Byte)
	Dim uidLength As Byte = uid.Length
	Dim dataLength As Byte = data.Length
	Dim totalLength As UInt = 1 + 1 + 1 + uidLength + 1 + dataLength   ' ID + CMD + UL + UID + DL + DATA

	Dim carddata(totalLength) As Byte
	Dim idx As UInt = 0

'	Log("[DevRFID.WriteToBLE] UID=", Convert.BytesToHex(uid), _
'        ", length=", uid.Length, "=", Convert.OneByteToHex(uidLength))
'	Log("[DevRFID.WriteToBLE] Data=", Convert.BytesToHex(data), _
'        ", length=", data.Length, "=", Convert.OneByteToHex(dataLength))
'	Log("[DevRFID.WriteToBLE] Total Length=", totalLength)

	'--------------------------------------------------------
	' 1) ID + CMD
	'--------------------------------------------------------
	carddata(idx) = CommBLE.DEV_RFID
	idx = idx + 1
	carddata(idx) = CommBLE.CMD_GET_VALUE
	idx = idx + 1

	'--------------------------------------------------------
	' 2) UL (UID length)
	'--------------------------------------------------------
	carddata(idx) = uidLength
	idx = idx + 1

	'--------------------------------------------------------
	' 3) UID bytes
	'--------------------------------------------------------
	For i = 0 To uidLength - 1
		carddata(idx) = uid(i)
		idx = idx + 1
	Next

	'--------------------------------------------------------
	' 4) DL (data length)
	'--------------------------------------------------------
	carddata(idx) = dataLength
	idx = idx + 1

	'--------------------------------------------------------
	' 5) Data bytes
	'--------------------------------------------------------
	For i = 0 To dataLength - 1
		carddata(idx) = data(i)
		idx = idx + 1
	Next

	Log("[DevRFID.WriteToBLE] Final idx=", idx, ", ArrayLen=", carddata.Length)
	Log("[DevRFID.WriteToBLE] Payload=", Convert.BytesToHex(carddata))

	'--------------------------------------------------------
	' 6) Send to BLE client
	'--------------------------------------------------------
	CommBLE.BLEServer_Write(carddata)

	'--------------------------------------------------------
	' 7) Store data into the globalstore special slot 4
	'--------------------------------------------------------
	GlobalStoreHandler.PutSlot4(carddata)
End Sub
#End Region
#End If
