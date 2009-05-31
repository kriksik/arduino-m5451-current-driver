/*
 * Constant-Current Shield and M5451 LED driver
 * Version 1.0 Author: G. Andrew Stone
 * Created March, 2009
 * Released under the MIT license (http://www.opensource.org/licenses/mit-license.php)
 *
 * This is an Arduino Library, to install see: http://www.arduino.cc/en/Hacking/LibraryTutorial
 * Quick Installation instructions:
 * Copy this file and the CCShield.h file to a new directory called
 * "CCShield" in the hardware\libraries directory in your arduino installation.  
 * Then restart the Arduino IDE.
 *
 * For example: 
 * mkdir c:\arduino-0012\hardware\libraries\CCShield
 * copy *.* c:\arduino-0012\hardware\libraries\CCShield
 */

#ifndef CCSHIELD_H
#define CCSHIELD_H

//#include "WConstants.h"
#include <inttypes.h>

#define M5451_NUMOUTS 35
#define CCShield_NUMOUTS 70
#define M5451_CLK 1L


// Maximum number of gradations of brightness
#define CCShield_MAX_BRIGHTNESS 256

// This is the mininum intensity to set for flickerless viewing.  It is subjective, and also depends upon
// how much time you are spending doing other things.  The LED will be OFF for MIN_INTENSITY/MAX_BRIGHTNESS amount of time
// When this is (say) 1/256, you can see the LED flicker since it only blinks once per 256 loop iterations!
// Strangely, the amount of visible flicker also depends upon how much current you put across the LEDs (ie. the "brightness" selector)
#define CCShield_MIN_INTENSITY 17  

/* This class provides the basic functions to control the M5451 chip; in particular, it drives 2 simultaneously
   which is how the constant-current shield is laid out.
*/
class CCShield
 {
  public:
  // What pin to use to as the M5451 clock (any digital pin can be selected on the board by solder blob short)
  uint8_t clockPin;
  // What pin to use to to control brightness (any digital pin can be selected on the board by solder blob short)
  // note that to make brightness work, use a jumper to select software controller brightness instead of resistor controlled.
  uint8_t brightPin;
  // What pins to use to send serial data to each M5451 (need 1 pin for each chip)
  // (any digital pin can be selected on the board by solder blob short)
  uint8_t serDataPin[2];
  
  // Constructor takes all of the pins needed.
  CCShield(uint8_t clockPin,uint8_t serDataPin1,uint8_t serDataPin2,uint8_t brightPin);
  
  // Turn on/off certain lines.
  // Parameters a,b,c are a bitmap; each bit corresponds to a particular M5451 output
  // The first 70 bits are used (i.e. all of parameter a and b, and just a few bits in parameter c
  void set(unsigned long int a, unsigned long int b, unsigned long int c);
      
  // The same set function conveniently taking an array
  void set(unsigned long int a[3]);
  
  // Set the overall brightness using the M5451 brightness selection (assuming its under software control)
  void setBrightness(uint8_t b);
  
  private:
  int mydelay(unsigned long int clk);
};

// This function sets a particular bit by index in a bitmap contained in parameters a,b,c
// you can then pass these into the CCShield "set" function. 
void setbit(unsigned char offset,unsigned long int* a, unsigned long int* b, unsigned char* c);

// This function clears a particular bit by index in a bitmap contained in parameters a,b,c
// you can then pass these into the CCShield "set" function. 
void clearbit(unsigned char offset,unsigned long int* a, unsigned long int* b, unsigned char* c);


// The FlickerBrightness class changes the apparent brightness of individual LEDs by turning them off and on rapidly.
// This technique is called PWM (pulse-width modulation) and if done fast enough, the fact of persistence of vision means
// that the flickering is not seen.
// The "loop" function must be called periodically and rapidly.  If the LEDs appear to flicker, "loop" should be called more
// often (or do not make the LEDs that dim).
class FlickerBrightness
{
  public:
  // The constructor takes a CCShield object
  FlickerBrightness(CCShield& brd);
  
  // This function performs a marquee function by shifting which intensity corresponds with which actual output in CCShield
  void shift(int amt=1) 
    { 
    offset+=amt; 
    if (offset>=M5451_NUMOUTS) offset -=CCShield_NUMOUTS; 
    else if (offset<0) offset +=CCShield_NUMOUTS; 
    }
    
  // Call this function periodically and rapidly to blink the LEDs and therefore create the illusion of brightness
  void loop(void);
  
  // Set this variable to the desired brightness, indexed by the LED you want to control
  uint8_t brightness[CCShield_NUMOUTS];
  
  // Private
  int bresenham[CCShield_NUMOUTS];
  int offset;
  CCShield& brd;
};

// The ChangeBrightness class modifies the brightness of the LEDs smoothly and linearly through a desired
// brightness range.
class ChangeBrightness
{
  public:
  // Pass the constructor a FlickerBrightness object and also a callback (optional).  When this class finished moving a LED
  // to the desired brightness, it will call the callback so you can program a new intensity target in.
  ChangeBrightness(FlickerBrightness& thebrd, void (*doneCallback)(ChangeBrightness& me, int led)=0);
  
  /* Transition the light at index 'led' to intensity over count iterations */
  void set(uint8_t led, uint8_t intensity, int count);
  
  // Call loop periodically and rapidly to change the brightness.  This function calls FlickerBrightness.loop(), so
  // it is unnecessary for you to do so.
  void loop(void);
 
  // semi-private variables 
  FlickerBrightness& brd;
  int  change[CCShield_NUMOUTS];
  int  count[CCShield_NUMOUTS];
  uint8_t destination[CCShield_NUMOUTS];  
  int  bresenham[CCShield_NUMOUTS];
  void (*doneCall)(ChangeBrightness& me, int led);
};

#endif
