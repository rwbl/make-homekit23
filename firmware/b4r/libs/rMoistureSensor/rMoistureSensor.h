#pragma once
#include "B4RDefines.h"

/**
 * @file rMoistureSensor.h
 * @brief B4R C++ wrapper for the Moisture Sensor Module.
 * @note Tested with the Keyestudio Steam Sensor, Working Temperature: －10-70C, Interface Type: Analog Signal Output.
 * @note This is an analog (digital) input module, also called rain, rain sensor. 
 *       The output is converted into a digital signal (DO) and an analog signal (AO) output.
 * @version 1.0
 * @date 2025-11-29
 * @author Robert W. B. Linn (c) 2025 — MIT License
 */

namespace B4R {
    //~version: 1.0
	//~shortname: MoistureSensor
	//~Event: MoistureDetected (Value As Int)
	class B4RMOISTURESENSOR {
		/** @brief Type definition for the moisture value used for the event. */
		typedef void (*SubVoidInt)(Int val);
		private:
		
			/** @brief Instance holding the steam sensor. */
			static B4RMOISTURESENSOR* instance;

			/** @brief Sensor analog pin number. */
			Byte sensorPin;

			/** @brief Store previous value. */
			int moistureprev;

			/** @brief Event-enabled flag (instance specific). */
			bool eventenabled;

			/** @brief Per-instance event timer. */
			UInt lastEvent = 0;

			/** @brief Event using call in B4R program */
			SubVoidInt MoistureDetectedSub;
			static void looper(void* b);

		public:
			/**
			 * @brief Initializes the sensor.
			 * @param pin - Input pin number.
			 * @param MoistureDetectedSub - Callback for the `MoistureDetected` event.
			 */
			void Initialize(Byte pin, SubVoidInt MoistureDetectedSub);

			/**
			 * @brief Read the sensor value 0-4095..
			 * @return int Sensor value.
			 */
			int Read();

			/**
			 * @brief Get the ADC value 0-4095.
			 * @return int ADC value.
			 */
			int ADC();

			/**
			 * @brief Get the DAC value 0-255 (8-bit precision).
			 * @return int DAC value.
			 */
			int DAC();

			/**
			 * @brief Get the voltage 0-3.3V.
			 * @return double Voltage value.
			 */
			double Voltage();

			/**
			 * @brief Set/Get enabled state change event.
			 */
			void setEventEnabled(bool state);
			bool getEventEnabled(void);

			//==================================================
			// CONSTANTS
			//==================================================

			/** @brief No moisture detected (ADC analog value 0). */
			static const int MIN_VALUE = 0;
			/** @brief No moisture detected alias. */
			static const int DRY = 0;

			/** @brief Moisture detected (ADC max analog value 4095). */
			static const int MAX_VALUE = 4095;
	};
}