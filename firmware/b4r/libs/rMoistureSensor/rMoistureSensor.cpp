/**
 * rMoistureSensor.cpp
 * Source for the B4R library rMoistureSensor.
 */
 
#include "B4RDefines.h"
namespace B4R {

	// Static instance for global callback access
	B4RMOISTURESENSOR* B4RMOISTURESENSOR::instance = nullptr;

	void B4RMOISTURESENSOR::Initialize(Byte pin, SubVoidInt MoistureDetectedSub) {
		// ::Serial.println("[B4RMOISTURESENSOR::Initialize] Start");
		
		instance = this;

		sensorPin = pin;		
		pinMode(sensorPin, INPUT);

		// Initialize internal state
		moistureprev = NAN;			// Ensures first reading always fires event
		eventenabled = true;
		lastEvent = 0;
				
		// Register callback event for handling analog reading
		this->MoistureDetectedSub = MoistureDetectedSub;
		FunctionUnion fu;
		fu.PollerFunction = looper;
		pollers.add(fu, this);
		
		// ::Serial.println("[B4RMOISTURESENSOR::Initialize] OK");
	}

	int B4RMOISTURESENSOR::Read() {
		return analogRead(sensorPin);
	}

	int B4RMOISTURESENSOR::ADC() {
		int adcVal = analogRead(sensorPin);
		return adcVal;
	}

	int B4RMOISTURESENSOR::DAC() {
		int adcVal = analogRead(sensorPin);
		// Handle noise
		if (adcVal < MIN_VALUE) {
			adcVal = MIN_VALUE;
		}
		if (adcVal > MAX_VALUE) {
			adcVal = MAX_VALUE;
		}
		int dacVal = map(adcVal, 0, MAX_VALUE, 0, 255);
		return dacVal;
	}

	double B4RMOISTURESENSOR::Voltage() {
		int adcVal = analogRead(sensorPin);
		double voltage = 0;
		if (adcVal > 0) {
			voltage = adcVal / MAX_VALUE * 3.3;
		}
		return voltage;
	}

	void B4RMOISTURESENSOR::setEventEnabled(bool state) {
		eventenabled = state;
	}
	bool B4RMOISTURESENSOR::getEventEnabled() {
		return eventenabled;
	}

	// Event
	void B4RMOISTURESENSOR::looper(void* b) {

		B4RMOISTURESENSOR* me = (B4RMOISTURESENSOR*)b;
		
		// Handle debounce
		if (me->lastEvent + 500 > millis())
			return;
		me->lastEvent = millis();

		// Read the sensor valuevalue
		int moisture = me->Read();
	
		// Check if the event is enabled
		if (me->getEventEnabled()) {
			// Call the event if the value has changed			
			if (moisture != me->moistureprev) {
				const UInt cp = B4R::StackMemory::cp;
				me->MoistureDetectedSub(moisture);
				B4R::StackMemory::cp = cp;
				
				me->moistureprev = moisture;
			}
		}
	}

}	

