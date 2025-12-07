/**
 * rESP32Buzzer.cpp
 * ESP32 buzzer wrapper using esp_timer for square-wave generation and auto-stop.
 */

#include "B4RDefines.h"

namespace B4R {

	// Helper: create an esp_timer with a callback (periodic or one-shot)
	static esp_timer_handle_t create_esp_timer(esp_timer_cb_t cb, void* arg, bool periodic, uint64_t period_us) {
		esp_timer_create_args_t cfg;
		memset(&cfg, 0, sizeof(cfg));
		cfg.callback = cb;
		cfg.arg = arg;
		cfg.dispatch_method = ESP_TIMER_TASK; // use timer task, safe for gpio_set_level
		cfg.name = "buzzer_timer";
		esp_timer_handle_t handle = nullptr;
		if (esp_timer_create(&cfg, &handle) != ESP_OK) return nullptr;
		if (periodic) {
			esp_timer_start_periodic(handle, period_us);
		} else {
			esp_timer_start_once(handle, period_us);
		}
		return handle;
	}

	// ========================
	// Internal helpers
	// ========================
	void B4RESP32BUZZER::_toneTimerCallback(void* arg) {
		B4RESP32BUZZER* self = (B4RESP32BUZZER*)arg;
		// Toggle pin
		self->_pin_state = !self->_pin_state;
		gpio_set_level((gpio_num_t)self->_pin, self->_pin_state ? 1 : 0);
	}

	void B4RESP32BUZZER::_stopTimerCallback(void* arg) {
		B4RESP32BUZZER* self = (B4RESP32BUZZER*)arg;
		// Stop timers and ensure pin low
		self->Stop();
	}

	void B4RESP32BUZZER::_createToneTimer(uint64_t period_us) {
		// Destroy existing if present
		if (_tone_timer) {
			esp_timer_stop(_tone_timer);
			esp_timer_delete(_tone_timer);
			_tone_timer = nullptr;
		}
		// Create periodic timer (we won't start it here)
		esp_timer_create_args_t cfg;
		memset(&cfg, 0, sizeof(cfg));
		cfg.callback = [](void* arg){ B4RESP32BUZZER::_toneTimerCallback(arg); };
		cfg.arg = this;
		cfg.dispatch_method = ESP_TIMER_TASK;
		cfg.name = "buzzer_tone";
		if (esp_timer_create(&cfg, &_tone_timer) != ESP_OK) {
			_tone_timer = nullptr;
			return;
		}
		// Start periodic
		esp_timer_start_periodic(_tone_timer, period_us);
	}

	void B4RESP32BUZZER::_startToneTimer() {
		// no-op here because _createToneTimer already starts it.
	}

	void B4RESP32BUZZER::_stopToneTimer() {
		if (_tone_timer) {
			esp_timer_stop(_tone_timer);
			esp_timer_delete(_tone_timer);
			_tone_timer = nullptr;
		}
	}

	// ========================
	// Public API
	// ========================
	void B4RESP32BUZZER::Initialize(Byte pin) {
		_pin = (uint8_t)pin;
		timbre = 50;
		_playing = false;
		_pin_state = 0;
		_tone_timer = nullptr;
		_stop_timer = nullptr;
		_attachedTimerSlot = 0xFF; // unused

		// configure pin
		gpio_set_direction((gpio_num_t)_pin, GPIO_MODE_OUTPUT);
		gpio_set_level((gpio_num_t)_pin, 0);
	}

	void B4RESP32BUZZER::PlayTone(ULong freq, ULong duration_ms) {
		// stop any existing tone
		Stop();

		// check freq and duration
		if (freq <= 0) return;
		if (duration_ms < 0) duration_ms = 0;

		// half period in microseconds
		double half_us_d = 500000.0 / (double)freq;
		if (half_us_d < 1.0) half_us_d = 1.0;
		uint64_t half_us = (uint64_t) (half_us_d + 0.5);

		// create periodic tone timer (period = half period)
		// We create a timer, then start it periodic
		esp_timer_create_args_t cfg;
		memset(&cfg, 0, sizeof(cfg));
		cfg.callback = [](void* arg){ B4RESP32BUZZER::_toneTimerCallback(arg); };
		cfg.arg = this;
		cfg.dispatch_method = ESP_TIMER_TASK;
		cfg.name = "buzzer_tone";
		if (esp_timer_create(&cfg, &_tone_timer) != ESP_OK) {
			_tone_timer = nullptr;
			return;
		}
		// start periodic: period = half_us microseconds
		esp_timer_start_periodic(_tone_timer, half_us);

		_playing = true;
		_pin_state = 0;
		gpio_set_level((gpio_num_t)_pin, 0);

		// If duration given, schedule a one-shot to stop the tone after duration_ms
		if (duration_ms > 0) {
			// create or reuse stop timer
			if (_stop_timer) {
				esp_timer_stop(_stop_timer);
				esp_timer_delete(_stop_timer);
				_stop_timer = nullptr;
			}
			esp_timer_create_args_t scfg;
			memset(&scfg, 0, sizeof(scfg));
			scfg.callback = [](void* arg){ B4RESP32BUZZER::_stopTimerCallback(arg); };
			scfg.arg = this;
			scfg.dispatch_method = ESP_TIMER_TASK;
			scfg.name = "buzzer_stop";
			if (esp_timer_create(&scfg, &_stop_timer) == ESP_OK) {
				// start one-shot: convert ms->us
				esp_timer_start_once(_stop_timer, (uint64_t)duration_ms * 1000ULL);
			} else {
				_stop_timer = nullptr;
			}
		}
	}

	void B4RESP32BUZZER::Stop() {
		// stop stop_timer if any
		if (_stop_timer) {
			esp_timer_stop(_stop_timer);
			esp_timer_delete(_stop_timer);
			_stop_timer = nullptr;
		}
		// stop tone timer
		if (_tone_timer) {
			esp_timer_stop(_tone_timer);
			esp_timer_delete(_tone_timer);
			_tone_timer = nullptr;
		}
		_playing = false;
		_pin_state = 0;
		gpio_set_level((gpio_num_t)_pin, 0);
	}

	void B4RESP32BUZZER::Off() {
		Stop();
	}

	void B4RESP32BUZZER::setTimbre(Byte duty_percent) {
		// passive buzzer doesn't use timbre, keep value for API compatibility
		timbre = duty_percent;
	}

	Byte B4RESP32BUZZER::getTimbre() {
		return timbre;
	}

	void B4RESP32BUZZER::AttachToTimer(Byte slot) {
		// No-op for esp_timer implementation. Keep the value stored for compatibility.
		_attachedTimerSlot = slot;
	}

	// ========================
	// Melodies (blocking)
	// ========================
	void B4RESP32BUZZER::PlayRing(UInt repeats) {
		static uint32_t tones[] = { B4RESP32BUZZER::NOTE_C4, B4RESP32BUZZER::NOTE_G4, B4RESP32BUZZER::NOTE_A4 };
		static uint32_t durations[] = { 400, 300, 500 };

		for (uint32_t r = 0; r < repeats; r++) {
			for (int i = 0; i < 3; i++) {
				PlayTone(tones[i], durations[i]);
				// wait slightly more than duration to ensure the one-shot stop completes
				vTaskDelay(pdMS_TO_TICKS(durations[i] + 20));
			}
		}
		Stop();
	}

	void B4RESP32BUZZER::PlayBirthday() {
		uint32_t tones[] = {294,440,392,532,494,392,440,392,587,532,392,784,659,532,494,440,698,659,532,587,532};
		uint32_t durations[] = {250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,250,500};
		int len = sizeof(durations)/sizeof(durations[0]);
		for (int i = 0; i < len; i++) {
			PlayTone(tones[i], durations[i]);
			vTaskDelay(pdMS_TO_TICKS(durations[i] + 10));
		}
		Stop();
	}

	void B4RESP32BUZZER::PlayAlarm(Byte mode, Byte repeats) {
		::Serial.print("[B4RESP32BUZZER::PlayAlarm] mode=");
		::Serial.print(mode);
		::Serial.print(", repeats=");
		::Serial.println(repeats);
		
		for (int r = 0; r < repeats; r++) {
			switch (mode) {
				case ALARM_MODE_POLICE_SIREN:
					for (int i = 0; i < 6; i++) {
						PlayTone(440, 600);
						vTaskDelay(pdMS_TO_TICKS(600 + 20));
						PlayTone(660, 600);
						vTaskDelay(pdMS_TO_TICKS(600 + 20));
					}
					break;
				case ALARM_MODE_FIRE_ALARM:
					for (int i = 0; i < 15; i++) {
						PlayTone(880, 200);
						vTaskDelay(pdMS_TO_TICKS(200 + 20));
						PlayTone(0, 200); // silence for same duration (implemented by Stop())
						vTaskDelay(pdMS_TO_TICKS(200 + 20));
					}
					break;
				case ALARM_MODE_WAIL_SWEEP:
					for (int f = 400; f <= 1000; f += 20) {
						PlayTone(f, 10);
						vTaskDelay(pdMS_TO_TICKS(10));
					}
					for (int f = 1000; f >= 400; f -= 20) {
						PlayTone(f, 10);
						vTaskDelay(pdMS_TO_TICKS(10));
					}
					break;
				case ALARM_MODE_INTRUDER_ALARM:
					for (int i = 0; i < 3; i++) {
						PlayTone(1000, 800);
						vTaskDelay(pdMS_TO_TICKS(800 + 20));
						Stop();
						vTaskDelay(pdMS_TO_TICKS(200));
					}
					break;
				case ALARM_MODE_DANGER_ALARM:
					for (int i = 0; i < 10; i++) {
						PlayTone(880, 150);
						vTaskDelay(pdMS_TO_TICKS(150 + 10));
						PlayTone(440, 150);
						vTaskDelay(pdMS_TO_TICKS(150 + 10));
					}
					break;
				default:
					Stop();
					return;
			}
			Stop();
		}
	}

} // namespace B4R
