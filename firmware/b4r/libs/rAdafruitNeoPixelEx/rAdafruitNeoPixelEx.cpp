/**
 * rAdafruitNeoPixelEx.cpp
 * Source for the B4R rAdafruitNeoPixelEx library.
 */
 
#include "B4RDefines.h"

namespace B4R {
	void B4RAdafruitNeoPixelEx::Initialize(UInt numberOfPixels, Byte pinNumber, UInt pixelType) {
			
		pixel = new(be) Adafruit_NeoPixel(numberOfPixels, pinNumber, pixelType);
		pixel->begin();
		
	}

	uint B4RAdafruitNeoPixelEx::NumberOfPixels() {
		return pixel->numPixels();
	}

	void B4RAdafruitNeoPixelEx::SetColor(Byte R, Byte G, Byte B) {
		pixel->clear();
		int n = NumberOfPixels();
		for (int i = 0; i < n; i++) {
			pixel->setPixelColor(i, R, G, B);
		}
	}

	void B4RAdafruitNeoPixelEx::SetPixelColor(UInt index, Byte R, Byte G, Byte B) {
		pixel->setPixelColor(index, R, G, B);
	}

    void B4RAdafruitNeoPixelEx::SetPixelColor3(UInt index,ULong packedColor) {
        pixel->setPixelColor(index, packedColor);
    }

	void B4RAdafruitNeoPixelEx::SetPixelColor2(UInt index, Byte R, Byte G, Byte B, Byte W) {
		pixel->setPixelColor(index, R, G, B, W);
	
	}

	void B4RAdafruitNeoPixelEx::setBrightness (Byte level) {
		pixel->setBrightness(level);
	}

    Byte B4RAdafruitNeoPixelEx::getBrightness(){
        return pixel->getBrightness();
    }     

	void B4RAdafruitNeoPixelEx::Show() {
		pixel->show();
	}

	void B4RAdafruitNeoPixelEx::Clear() {
		pixel->clear();
	}

  	ULong B4RAdafruitNeoPixelEx::ColorHSV(UInt hue) {
		return pixel->ColorHSV(hue);
    }

	ULong B4RAdafruitNeoPixelEx::ColorHSV2(UInt hue, Byte sat, byte val) {
		return pixel->ColorHSV(hue, sat, val);
    }

    ULong B4RAdafruitNeoPixelEx::Gamma32(ULong packedColor){
        return pixel->gamma32(packedColor);
    }

    void  B4RAdafruitNeoPixelEx::Fill(ULong color, Byte first, Byte count){
        pixel->fill(color, first, count);
    }

    ULong B4RAdafruitNeoPixelEx::GetPixelColor(UInt index){
        return pixel->getPixelColor(index);
    }

}