#pragma once
#include "B4RDefines.h"
#include "MFRC522_I2C.h"

/**
 * @file rMFRC522Mifare.h
 * @brief B4R C++ wrapper for MFRC522 I2C reader specialized for MIFARE Classic cards.
 *
 * ## Overview
 * This library provides a simplified interface for interacting with MIFARE Classic 1K and compatible cards
 * using the MFRC522 RFID reader over the I2C bus. It is designed for use with **B4R (BASIC for Arduino)**.
 *
 * ## MIFARE Classic Card Structure
 * A MIFARE Classic 1K card is divided into **16 sectors**, each containing **4 blocks** (block numbers 0–63 in total).
 * Each block consists of **16 bytes** of data.
 *
 * - **Sector trailer (last block of each sector):**  
 *   Contains two 6-byte keys (Key A and Key B) and 4 bytes of access conditions.  
 *   Example: Sector 0 trailer = Block 3, Sector 1 trailer = Block 7, etc.  
 *   ! Never overwrite trailer blocks unless you intend to change authentication keys.
 *
 * - **Data blocks (non-trailer):**  
 *   Can safely store user data. For most applications, **block 4** (sector 1, first data block)
 *   is recommended for user storage.
 *
 * ## Authentication
 * Each sector requires authentication before any read or write operation.
 * Authentication can use either:
 * - **Key A (default = FF FF FF FF FF FF)**
 * - **Key B**
 *
 * Once authenticated, you can read or write any data block within that sector until the card is halted.
 *
 * ## Usage Notes
 * - Always call `MifareHalt()` after finishing communication with a card.
 *   This releases the crypto session and selection state.
 * - Writing to a card immediately after reading within the same session may fail unless the card is reselected.
 *   Best practice: separate read and write operations into independent sessions.
 *
 * ## Example
 * ```basic
 * ' Initialize
 * RFID.Initialize(RFID.I2C_DEFAULT_ADDRESS, "RFID_CardPresent")
 *
 * ' Authenticate + write block 4
 * If RFID.MifareAuthenticate(4) Then
 *     Dim data(16) As Byte
 *     data(0) = 0x03
 *     data(1) = 0x04
 *     RFID.MifareWrite(4, data)
 *     RFID.MifareHalt
 * End If
 * ```
 *
 * @note This library is tailored for MIFARE Classic tags and does not cover MIFARE DESFire, Ultralight, or NTAG.
 *
 * @version 1.0
 * @date 2025
 * @author
 *   Robert W. B. Linn (c) 2025 — MIT License
 *
 * @event CardPresent (UID() As Byte, CardType As Byte)
 */

namespace B4R {
	typedef void (*SubVoidArrayByte)(Array* barray, Byte type);

    //~version: 1.0
	//~shortname: MFRC522Mifare_I2C
	class B4RMFRC522 {
		private:
			byte beMFRC522[sizeof(MFRC522)];
			MFRC522* rfid;
			SubVoidArrayByte CardPresentSub;
			static void looper(void* b);

		public:
			/**
			 * @brief Initializes the MFRC522 reader.
			 * @param chipAddress I2C address of the MFRC522 (default: 0x28).
			 * @param CardPresentSub Callback for the `CardPresent` event.
			 * @note Use an I2C scanner if unsure of the address.
			 */
			void Initialize(Byte chipAddress, SubVoidArrayByte CardPresentSub);

			/** @brief Initializes the reader hardware. */
			void PCD_Init();

			/** @brief Checks if a new card is present. */
			bool PICC_IsNewCardPresent();

			/** @brief Reads the card serial number. */
			bool PICC_ReadCardSerial();

			/** @brief Reads a register from the MFRC522 chip. */
			byte PCD_ReadRegister(byte reg);

			/** @brief Logs the firmware version of the MFRC522 chip. */
			void LogVersion();

			//==================================================
			// MIFARE FUNCTIONS
			//==================================================

			/**
			 * @brief Returns true if the detected card is a MIFARE Classic type.
			 */
			bool IsMifare();

			/**
			 * @brief Authenticates access to the specified block using the default Key A.
			 * @param BlockAddress The block index (0–63).
			 * @return True if authentication succeeded.
			 */
			bool MifareAuthenticate(Byte BlockAddress);

			/**
			 * @brief Authenticates access to a block using a specific key.
			 * @param BlockAddress The block index.
			 * @param Key Pointer to an array of 6 bytes representing the key.
			 * @param KeyA If true, uses Key A; if false, uses Key B.
			 * @return True if authentication succeeded.
			 */
			bool MifareAuthenticate2(Byte BlockAddress, ArrayByte* Key, bool KeyA);

			/**
			 * @brief Reads data from the specified block.
			 * @param BlockAddress Block index to read from.
			 * @param Buffer Output buffer; must be at least 18 bytes.
			 * @return Number of bytes read (should be 18).
			 * @note Always call `MifareAuthenticate()` before reading.
			 */
			Byte MifareRead(Byte BlockAddress, ArrayByte* Buffer);

			/**
			 * @brief Writes data to the specified block.
			 * @param BlockAddress Block index to write to.
			 * @param Buffer Data buffer (must contain at least 16 bytes).
			 * @return True if writing succeeded.
			 * @note Always call `MifareAuthenticate()` before writing.
			 */
			bool MifareWrite(Byte BlockAddress, ArrayByte* Buffer);

			/**
			 * @brief Safely halts the current card communication.
			 * @details
			 * After authenticating and reading/writing a MIFARE card,
			 * the reader retains its cryptographic session and selection state.
			 * Failing to halt may cause future authentication to fail or hang.
			 * Always call `MifareHalt()` after completing operations.
			 */
			void MifareHalt();

			//==================================================
			// CONSTANTS
			//==================================================

			/** @brief Firmware version register. */
			static const int VERSIONREG = 0x37;

			/** @brief Default I2C address for MFRC522 on SDA. */
			static const int I2C_DEFAULT_ADDRESS = 0x28;

			// PICC Type identifiers
			
			// PICC Unknown type (0)
			static const byte PICC_TYPE_UNKNOWN			= 0;
			// PICC compliant with ISO/IEC 14443-4 (1)
			static const byte PICC_TYPE_ISO_14443_4		= 1;	
			// PICC compliant with ISO/IEC 18092 (NFC) (2)
			static const byte PICC_TYPE_ISO_18092		= 2; 	
			// MIFARE Classic protocol, 320 bytes (3)
			static const byte PICC_TYPE_MIFARE_MINI		= 3;	
			// MIFARE Classic protocol, 1KB (4)
			static const byte PICC_TYPE_MIFARE_1K		= 4;	
			// MIFARE Classic protocol, 4KB (5)
			static const byte PICC_TYPE_MIFARE_4K		= 5;	
			// MIFARE Ultralight or Ultralight C (6)
			static const byte PICC_TYPE_MIFARE_UL		= 6;	
			// MIFARE Plus (7)
			static const byte PICC_TYPE_MIFARE_PLUS		= 7;	
			// Only mentioned in NXP AN 10833 MIFARE Type Identification Procedure (8)
			static const byte PICC_TYPE_TNP3XXX			= 8;	
			// SAK indicates UID is not complete (255)
			static const byte PICC_TYPE_NOT_COMPLETE	= 255;

	};
}