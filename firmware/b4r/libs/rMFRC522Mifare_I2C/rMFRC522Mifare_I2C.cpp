/**
 * rMFRC522Mifare_I2C.cpp
 * Source for the B4R library rMFRC522Mifare_I2C
 */
 
#include "B4RDefines.h"
namespace B4R {

	void B4RMFRC522::Initialize(Byte chipAddress, SubVoidArrayByte CardPresentSub) {
		// ::Serial.println("[B4RMFRC522::Initialize] Start");
		
		// Initialize I2C
		Wire.begin();

		// Initialize new MFRC522 instance
		rfid = new(beMFRC522) MFRC522(chipAddress);

		// Initialize MFRC522
		rfid->PCD_Init();
		// ::Serial.println("[B4RMFRC522::Initialize] PCD_Init");
		
		// Registare callback event for handling card reading
		this->CardPresentSub = CardPresentSub;
		FunctionUnion fu;
		fu.PollerFunction = looper;
		pollers.add(fu, this);
		
		// ::Serial.println("[B4RMFRC522::Initialize] OK");
	}

	void B4RMFRC522::PCD_Init(){
		rfid->PCD_Init();
	}
	bool B4RMFRC522::PICC_IsNewCardPresent(){
		rfid->PICC_IsNewCardPresent();
	}
	bool B4RMFRC522::PICC_ReadCardSerial(){
		rfid->PICC_ReadCardSerial();
	}
	byte B4RMFRC522::PCD_ReadRegister(byte reg){
		rfid->PCD_ReadRegister(reg);
	}

	static UInt lastEvent = 0;
	void B4RMFRC522::looper(void* b) {
		B4RMFRC522* me = (B4RMFRC522*)b;
		if ( ! me->rfid->PICC_IsNewCardPresent())
			return;
		if ( ! me->rfid->PICC_ReadCardSerial())
			return;
		if (lastEvent + 500 > millis())
			return;
		lastEvent = millis();
		const UInt cp = B4R::StackMemory::cp;
		ArrayByte* arr = CreateStackMemoryObject(ArrayByte);
		arr->data = me->rfid->uid.uidByte;
		arr->length = me->rfid->uid.size;
		me->CardPresentSub (arr, me->rfid->PICC_GetType(me->rfid->uid.sak));
		me->rfid->PICC_HaltA();
		me->rfid->PCD_StopCrypto1();
		B4R::StackMemory::cp = cp;
	}

	void B4RMFRC522::LogVersion() {
	  ::Serial.print("[B4RMFRC522::LogVersion]");
	  //  attain the MFRC522 software
	  byte v = rfid->PCD_ReadRegister(rfid->VersionReg);
	  ::Serial.print(F("MFRC522 Software Version: 0x"));
	  ::Serial.print(v, HEX);
	  if (v == 0x91)
		::Serial.print(F(" = v1.0"));
	  else if (v == 0x92)
		::Serial.print(F(" = v2.0"));
	  else
		::Serial.print(F(" (unknown)"));
	  ::Serial.println("");
	  // when returning to 0x00 or 0xFF, may fail to transmit communication signals
	  if ((v == 0x00) || (v == 0xFF)) {
		::Serial.println(F("WARNING: Communication failure, is the MFRC522 properly connected?"));
	  }
	}

	//=====================================================
	//MIFARE
	//=====================================================
	bool B4RMFRC522::IsMifare() {
		Byte piccType = rfid->PICC_GetType(rfid->uid.sak);
		return !(piccType != MFRC522::PICC_TYPE_MIFARE_MINI
				&&  piccType != MFRC522::PICC_TYPE_MIFARE_1K
				&&  piccType != MFRC522::PICC_TYPE_MIFARE_4K);
	}

	bool B4RMFRC522::MifareAuthenticate(Byte BlockAddress) {
		ArrayByte ab;
		// MFRC522 key is always 6 bytes.
		Byte b[] = {0xff, 0xff, 0xff, 0xff, 0xff, 0xff};
		ab.data = b;
		ab.length = 6;
		return MifareAuthenticate2(BlockAddress, &ab, true);
	}
			
	bool B4RMFRC522::MifareAuthenticate2(Byte BlockAddress, ArrayByte* Key, bool KeyA) {
		Byte status = rfid->PCD_Authenticate (
			KeyA ? MFRC522::PICC_CMD_MF_AUTH_KEY_A : MFRC522::PICC_CMD_MF_AUTH_KEY_B, 
			BlockAddress,
			(MFRC522::MIFARE_Key*)Key->data, &(rfid->uid));
		return status == MFRC522::STATUS_OK;
	}

	// MIFARE_Read always reads 16 data bytes + 2 CRC bytes, so the buffer must be at least 18 bytes.
	Byte B4RMFRC522::MifareRead(Byte BlockAddress, ArrayByte* Buffer) {
		Byte length = Common_Min(Buffer->length, 18);
		Byte status = rfid->MIFARE_Read(BlockAddress, (Byte*)Buffer->data, &length);
		if (status != MFRC522::STATUS_OK)
			return 0;
		return Common_Min((Byte)16, length);  // typical data length
	}

	bool B4RMFRC522::MifareWrite (Byte BlockAddress, ArrayByte* Buffer) {
		return (
				rfid->MIFARE_Write(BlockAddress, 
				(Byte*)Buffer->data, Common_Min(16, Buffer->length))) == MFRC522::STATUS_OK;
	}

	void B4RMFRC522::MifareHalt() {
		rfid->PICC_HaltA();
		rfid->PCD_StopCrypto1();
	}

}	

