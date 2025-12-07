#pragma once
#include "B4RDefines.h"
#include "Adafruit_NeoPixel.h"

/**
 * @file rAdafruitNeoPixelEx.h
 * @brief B4R C++ wrapper for the Adafruit NeoPixel library (v1.12.3).
 * @details This class provides access to RGB and RGBW LED strips and rings driven by single-wire protocols (e.g. WS2812, SK6812).
 * It exposes the main NeoPixel functionality to B4R including color setting, brightness control, and pixel retrieval.
 * Terminology: Pixel is used in the API and docs (e.g. NumberOfPixels, SetPixelColor, etc.)
 * Each pixel corresponds to one RGB or RGBW LED package. LED is the pin hardware itself.
 * @note Based on Adafruit NeoPixel v1.12.3 — MIT License.
 * @see https://github.com/adafruit/Adafruit_NeoPixel
 * @date 2025-11-17
 * @author Robert W.B. Linn
 * @license MIT
 */

//~version: 1.0
namespace B4R {
	//~shortname: AdafruitNeoPixelEx

	/**
	 * @class B4RAdafruitNeoPixelEx
	 * @brief B4R wrapper around the Adafruit_NeoPixel class for controlling addressable RGB and RGBW LEDs.
	 */
	class B4RAdafruitNeoPixelEx {
		private:
			/** @brief Internal storage buffer for the NeoPixel instance. */
			uint8_t be[sizeof(Adafruit_NeoPixel)];
			/** @brief Pointer to the underlying Adafruit_NeoPixel object. */
			Adafruit_NeoPixel* pixel;                
				
		public:
			/**
			 * @brief Initializes the NeoPixel object.
			 * @param numberOfPixels Total number of Pixels in the strip or ring.
			 * @param pinNumber GPIO pin connected to the NeoPixel data line.
			 * @param pixelType NeoPixel color order constant (e.g. NEO_GRB). Add 0x100 for 400 kHz devices.
			 */
			void Initialize(UInt numberOfPixels, Byte pinNumber, UInt pixelType);

			/**
			 * @brief Get number of pixels.
			 * @return UInt 32-bit packed color.
			 */
			uint NumberOfPixels();

			/**
			 * @brief Sets the color all pixels using RGB values.
			 * @param R Red intensity (0–255).
			 * @param G Green intensity (0–255).
			 * @param B Blue intensity (0–255).
			 */
			void SetColor(Byte R, Byte G, Byte B);
			
			/**
			 * @brief Sets the color of a specific pixel using RGB values.
			 * @param index Pixel index (0-based).
			 * @param R Red intensity (0–255).
			 * @param G Green intensity (0–255).
			 * @param B Blue intensity (0–255).
			 */
			void SetPixelColor(UInt index, Byte R, Byte G, Byte B);
			
			/**
			 * @brief Sets the color of a specific pixel using RGBW values.
			 * @param index Pixel index (0-based).
			 * @param R Red intensity (0–255).
			 * @param G Green intensity (0–255).
			 * @param B Blue intensity (0–255).
			 * @param W White intensity (0–255).
			 */
			void SetPixelColor2(UInt index, Byte R, Byte G, Byte B, Byte W);
            
			/**
			 * @brief Sets the color of a specific pixel using a packed 32-bit color value.
			 * @param index Pixel index (0-based).
			 * @param packedColor Packed 32-bit RGB or RGBW color.
			 */
			void SetPixelColor3(UInt index, ULong packedColor);
			
			/**
			 * @brief Sets the global brightness for all pixels.
			 * @param level Brightness level (0–255), where 0 is off and 255 is maximum.
			 */
			void setBrightness (Byte level);

			/**
			 * @brief Returns the last-set brightness value.
			 * @return Current brightness (0–255).
			 */
			Byte getBrightness();
            
			/**
			 * @brief Converts a hue value into a packed 32-bit RGB color.
			 * @param hue 16-bit hue value (0–65535).
			 * @return 32-bit packed color.
			 */
			ULong ColorHSV(UInt hue);
            
			/**
			 * @brief Converts hue, saturation, and value into a packed 32-bit RGB color.
			 * @param hue 16-bit hue value (0–65535).
			 * @param sat 8-bit saturation (0–255).
			 * @param val 8-bit value (0–255).
			 * @return 32-bit packed color value.
			 * @note The result can be passed to SetPixelColor3().
			 */
			ULong ColorHSV2(UInt hue, Byte sat, Byte val);
            
			/**
			 * @brief Applies gamma correction to a packed 32-bit color.
			 * @param packedColor Input packed color value.
			 * @return Gamma-corrected 32-bit color.
			 */
			ULong Gamma32(ULong packedColor);
            
			/**
			 * @brief Fills a range of pixels with a single color.
			 * @param color Color to fill (default: 0/off).
			 * @param first Starting pixel index (default: 0).
			 * @param count Number of pixels to fill (default: all).
			 */
			void Fill(ULong color=0, Byte first=0, Byte count=0);
            
			/**
			 * @brief Retrieves the current color value of a pixel.
			 * @param index Pixel index (0-based).
			 * @return 32-bit packed color (RGB or RGBW).
			 */
			ULong GetPixelColor(UInt index);

			/**
			 * @brief Sends updated pixel colors to the LEDs.
			 * @note Must be called after color changes for updates to appear.
			 */
			void Show();

			/**
			 * @brief Clears all pixel colors (sets them to 0/off).
			 */
			void Clear();
			
			
			//==========================================================
			// COLOR ORDER CONSTANTS
			//==========================================================
			
			/**< @brief Red, Green, Blue color order. */
			#define /*UInt NEO_RGB;*/ B4RAdafruitNeoPixelEx_NEO_RGB NEO_RGB  
			/**< @brief Red, Blue, Green color order. */
			#define /*UInt NEO_RBG;*/ B4RAdafruitNeoPixelEx_NEO_RBG NEO_RBG  
			/**< @brief Green, Red, Blue color order (most common). */
			#define /*UInt NEO_GRB;*/ B4RAdafruitNeoPixelEx_NEO_GRB NEO_GRB  
			/**< @brief Green, Blue, Red color order. */
			#define /*UInt NEO_GBR;*/ B4RAdafruitNeoPixelEx_NEO_GBR NEO_GBR  
			/**< @brief Blue, Red, Green color order. */
            #define /*UInt NEO_BRG;*/ B4RAdafruitNeoPixelEx_NEO_BRG NEO_BRG  
			/**< @brief Blue, Green, Red color order. */
            #define /*UInt NEO_BGR;*/ B4RAdafruitNeoPixelEx_NEO_BGR NEO_BGR  
            
            // RGBW variants
			/**< @brief White, Red, Green, Blue order. */
            #define /*UInt NEO_WRGB;*/ B4RAdafruitNeoPixelEx_NEO_WRGB NEO_WRGB 
			/**< @brief White, Red, Blue, Green order. */
            #define /*UInt NEO_WRBG;*/ B4RAdafruitNeoPixelEx_NEO_WRBG NEO_WRBG 
			/**< @brief White, Green, Red, Blue order. */
            #define /*UInt NEO_WGRB;*/ B4RAdafruitNeoPixelEx_NEO_WGRB NEO_WGRB 
			/**< @brief White, Green, Blue, Red order. */
            #define /*UInt NEO_WGBR;*/ B4RAdafruitNeoPixelEx_NEO_WGBR NEO_WGBR 
			/**< @brief White, Blue, Red, Green order. */
            #define /*UInt NEO_WBRG;*/ B4RAdafruitNeoPixelEx_NEO_WBRG NEO_WBRG 
			/**< @brief White, Blue, Green, Red order. */
            #define /*UInt NEO_WBGR;*/ B4RAdafruitNeoPixelEx_NEO_WBGR NEO_WBGR 
            
			/**< @brief Red, White, Green, Blue order. */
            #define /*UInt NEO_RWGB;*/ B4RAdafruitNeoPixelEx_NEO_RWGB NEO_RWGB 
			/**< @brief Red, White, Blue, Green order. */
            #define /*UInt NEO_RWBG;*/ B4RAdafruitNeoPixelEx_NEO_RWBG NEO_RWBG 
			/**< @brief Red, Green, White, Blue order. */
            #define /*UInt NEO_RGWB;*/ B4RAdafruitNeoPixelEx_NEO_RGWB NEO_RGWB 
			/**< @brief Red, Green, Blue, White order. */
            #define /*UInt NEO_RGBW;*/ B4RAdafruitNeoPixelEx_NEO_RGBW NEO_RGBW 
			/**< @brief Red, Blue, White, Green order. */
            #define /*UInt NEO_RBWG;*/ B4RAdafruitNeoPixelEx_NEO_RBWG NEO_RBWG 
			/**< @brief Red, Blue, Green, White order. */
            #define /*UInt NEO_RBGW;*/ B4RAdafruitNeoPixelEx_NEO_RBGW NEO_RBGW 
            
			/**< @brief Green, White, Red, Blue order. */
            #define /*UInt NEO_GWRB;*/ B4RAdafruitNeoPixelEx_NEO_GWRB NEO_GWRB 
			/**< @brief Green, White, Blue, Red order. */
            #define /*UInt NEO_GWBR;*/ B4RAdafruitNeoPixelEx_NEO_GWBR NEO_GWBR 
			/**< @brief Green, Red, White, Blue order. */
            #define /*UInt NEO_GRWB;*/ B4RAdafruitNeoPixelEx_NEO_GRWB NEO_GRWB 
			/**< @brief Green, Red, Blue, White order. */
            #define /*UInt NEO_GRBW;*/ B4RAdafruitNeoPixelEx_NEO_GRBW NEO_GRBW 
			/**< @brief Green, Blue, White, Red order. */
            #define /*UInt NEO_GBWR;*/ B4RAdafruitNeoPixelEx_NEO_GBWR NEO_GBWR 
			/**< @brief Green, Blue, Red, White order. */
            #define /*UInt NEO_GBRW;*/ B4RAdafruitNeoPixelEx_NEO_GBRW NEO_GBRW 
            
			/**< @brief Blue, White, Red, Green order. */
            #define /*UInt NEO_BWRG;*/ B4RAdafruitNeoPixelEx_NEO_BWRG NEO_BWRG 
			/**< @brief Blue, White, Green, Red order. */
            #define /*UInt NEO_BWGR;*/ B4RAdafruitNeoPixelEx_NEO_BWGR NEO_BWGR 
			/**< @brief Blue, Red, White, Green order. */
            #define /*UInt NEO_BRWG;*/ B4RAdafruitNeoPixelEx_NEO_BRWG NEO_BRWG 
			/**< @brief Blue, Red, Green, White order. */
            #define /*UInt NEO_BRGW;*/ B4RAdafruitNeoPixelEx_NEO_BRGW NEO_BRGW 
			/**< @brief Blue, Green, White, Red order. */
            #define /*UInt NEO_BGWR;*/ B4RAdafruitNeoPixelEx_NEO_BGWR NEO_BGWR 
			/**< @brief Blue, Green, Red, White order. */
            #define /*UInt NEO_BGRW;*/ B4RAdafruitNeoPixelEx_NEO_BGRW NEO_BGRW 
	};
}
