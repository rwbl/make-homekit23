#pragma once
#include "B4RDefines.h"
#include "DHTesp.h"

/**
 * @file rESP32DHT.h
 * @brief B4R C++ wrapper for the DHT11 & DHT22 sensors connected to ESP32.
 * @note This B4R Library is partly wrapped from project https://github.com/beegee-tokyo/arduino-DHTesp. Thanks to the author.
 * @note Tested with the Keyestudio DHT11.
 * @version 1.0
 * @date 2025-11-20
 * @author Robert W. B. Linn (c) 2025 — MIT License
 */

namespace B4R {
	//~Version: 1.00
	//~Shortname: ESP32DHT
	//~Event: StateChanged (Temperature As Float, Humidity As Float)
	class B4RESP32DHT {
		/** @brief Type definition for the sensor values used for the event. */
		typedef void (*SubVoidFloatFloat)(float tempval, float humval);

		private:
			/** @brief Declare object from DHTesp.h. */
			DHTesp dht;
			
			/** @brief Store the prev value.*/
			float tempprev;
			float humprev;

			/** @brief Event-enabled flag (instance specific). */
			bool eventenabled;

			/** @brief Per-instance event timer. */
			UInt lastEvent = 0;

			/** @brief Callback event state changed. */
			SubVoidFloatFloat StateChangedSub;
			static void looper(void* b);

		public:

			/**
			 * @brief Initializes the DHT11 sensor.
			 * @param Mode - DHT11 or DHT22 sensor.
			 * @param Pin - Input pin number.
			 * @param StateChangedSub - Callback for the `StateChanged` event.
			 */
			void Initialize(Byte Mode, Byte Pin, SubVoidFloatFloat StateChangedSub);

			/**
			 * @brief Read temperature from DHT (Celsius).
			 * @note Returns nan if there was a failure.
			 */
			float Temperature();	

			/**
			 * @brief Read Humidity as Percentage from DHT.
			 * @note Returns nan if there was a failure.
			 */
			float Humidity();

			/**
			 * @brief Set/Get enabled state change event.
			 */
			void setEventEnabled(bool state);
			bool getEventEnabled(void);

			/**
			 * CONSTANTS
			 */
			 /** @brief DHT11 mode. */
			const Byte DHT11 = 0;
			 /** @brief DHT22 mode. */
			const Byte DHT22 = 1;

	};
}