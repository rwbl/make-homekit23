#pragma once
#include "B4RDefines.h"
#include <Arduino.h>
#include "esp_timer.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

/**
 * @file 	rESP32Buzzer.h
 * @brief	B4R C++ wrapper for a simple ESP32 buzzer/tone generator.
 * @note 	Implementation uses esp_timer (high-resolution software timers) to
 *       	toggle the buzzer pin (square wave) with automatic duration handling.
 * @version 1.0
 * @date 	2025-11-10
 * @author	Robert W. B. Linn (c) 2025 — MIT License
 *
 * Remarks:
 *			- AttachToTimer() is a no-op for hardware-timer allocation in this implementation.
 *    			The library uses `esp_timer` to avoid hardware-timer conflicts with other libraries
 *    			(e.g. servo timers). Keeping the method allows compatibility with calling code.
 *			- Melody backgroud noise
 *				A small bit of background noise during rapid tone changes is normal when using timers + GPIO toggling on the ESP32:
 * 		 		The timer interrupt toggles the pin with perfect square waves.
 *       		Melodies with very fast frequency changes (like siren effects) cause:
 *       		harmonics, small timing jitter because of interrupt latency, slight DAC-like stepping if the speaker is small or piezo.
 *       		This results in faint "whistle/noise" between tone shifts.
 */

namespace B4R {
    //~version: 1.0
	//~shortname: ESP32Buzzer
	class B4RESP32BUZZER {
		
		private:
			// instance data
			uint8_t _pin;
			Byte timbre;

			// esp_timer handles
			esp_timer_handle_t _tone_timer;     // periodic timer toggling the pin
			esp_timer_handle_t _stop_timer;     // one-shot timer to stop after duration

			volatile bool _playing;
			volatile bool _pin_state;

			// For debug/attach compatibility (not used by esp_timer method)
			Byte _attachedTimerSlot;

			// helper to create/destroy timers
			void _createToneTimer(uint64_t period_us);
			void _startToneTimer();
			void _stopToneTimer();
			static void _toneTimerCallback(void* arg);
			static void _stopTimerCallback(void* arg);

		public:
			/**
			 * @brief Initializes the buzzer wrapper and configures the pin.
			 * @param pin GPIO pin number used for the passive buzzer.
			 */
			void Initialize(Byte pin);

			/**
			 * @brief Play a tone at given frequency (Hz) for duration (ms).
			 *        If duration_ms == 0, plays indefinitely until Stop() is called.
			 * @param freq Frequency in Hz (0 = stop)
			 * @param duration_ms Duration in milliseconds (0 = infinite)
			 */
			void PlayTone(ULong freq, ULong duration_ms = 0);

			/** Stop any currently playing tone immediately. */
			void Stop();

			/** Alias to stop */
			void Off();

			/** Set/Get timbre (unused for passive buzzer but kept for API compatibility). */
			void setTimbre(Byte duty_percent);
			Byte getTimbre();

			/**
			 * @brief Attach to a "timer slot" (0..3). This implementation uses esp_timer
			 *        and does not reserve a hardware timer; method kept for API compatibility.
			 */
			void AttachToTimer(Byte slot);

			/**
			 * Convenience melodies (blocking while playing).
			 * Alarm Modes: POLICE_SIREN 1, FIRE_ALARM 2, WAIL_SWEEP 3, INTRUDER_ALARM 4, DANGER_ALARM 5
			 */
			void PlayRing(UInt repeats = 1);
			void PlayBirthday();
			void PlayAlarm(Byte mode, Byte repeats = 1);

			//==================================================
			// CONSTANTS
			//==================================================
			static const ULong NOTE_NONE	= 0;
			static const ULong NOTE_A3		= 220;
			static const ULong NOTE_A4		= 440;
			static const ULong NOTE_B3		= 247;
			static const ULong NOTE_B4		= 494;
			static const ULong NOTE_C4		= 262;
			static const ULong NOTE_D4		= 294;
			static const ULong NOTE_E4		= 330;
			static const ULong NOTE_F4		= 349;
			static const ULong NOTE_G3		= 196;
			static const ULong NOTE_G4		= 392;

			/** Alarm modes used for the function PlayAlarm */
			static const Byte ALARM_MODE_NONE 			= 0;	
			static const Byte ALARM_MODE_MAX 			= 5;	// must match highest alarm mode
			static const Byte ALARM_MODE_POLICE_SIREN 	= 1;
			static const Byte ALARM_MODE_FIRE_ALARM 	= 2;
			static const Byte ALARM_MODE_WAIL_SWEEP 	= 3;
			static const Byte ALARM_MODE_INTRUDER_ALARM	= 4;
			static const Byte ALARM_MODE_DANGER_ALARM 	= 5;
	};
}
