#include "B4RDefines.h"

namespace B4R {
	void B4RESP32DHT::Initialize(Byte Mode, Byte Pin, SubVoidFloatFloat StateChangedSub) {

		// Select model based on Mode flag
		if (Mode == DHT11) {
			dht.setup(Pin, DHTesp::DHT11);
		} else if (Mode == DHT22) {
			dht.setup(Pin, DHTesp::DHT22);
		} else {
			// Optional: fallback safety
			dht.setup(Pin, DHTesp::DHT11);
		}

		// Initialize internal state
		tempprev = NAN;       // Ensures first reading always fires event
		humprev  = NAN;
		eventenabled = true;
		lastEvent = 0;

		// Register event callback
		this->StateChangedSub = StateChangedSub;
		
		FunctionUnion fu;
		fu.PollerFunction = looper;
		pollers.add(fu, this);
	}

	float B4RESP32DHT::Humidity(){
		return dht.getHumidity();
	}

	float B4RESP32DHT::Temperature(){
		return dht.getTemperature();
	}

	void B4RESP32DHT::setEventEnabled(bool state) {
		eventenabled = state;
	}
	bool B4RESP32DHT::getEventEnabled() {
		return eventenabled;
	}

	// Event
	void B4RESP32DHT::looper(void* b) {
		
		B4RESP32DHT* me = (B4RESP32DHT*)b;
		
		if (me->lastEvent + 500 > millis())
			return;
		me->lastEvent = millis();

		// Check if the event is enabled
		if (me->getEventEnabled()) {
			// Read the sensor values
			float temp = me->Temperature();
			float hum = me->Humidity();

			// Call the event if temp or hum has changed
			if (temp != me->tempprev || hum != me->humprev) {
				const UInt cp = B4R::StackMemory::cp;
				
				me->StateChangedSub(temp, hum);
				B4R::StackMemory::cp = cp;
				
				me->tempprev = temp;
				me->humprev = hum;
			}
		}
	}
}