#include <CCShield.h>

/*
 * Constant-Current Shield M5451 LED driver chip test and example
 * Author: G. Andrew Stone
 * Public Domain
 */

#include "WProgram.h"
void setup();
void loop();
int myClockPin = 3;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin = 9;  // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 = 5; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 11;          // What Arduino pin goes to the brightness ping on the M5451s

int ledPin = 13;  // The normal arduino example LED

void setup()                    // run once, when the sketch starts
{
}


class StepperL298N
{
  public:
  unsigned long int cnt;
//  uint8_t pins[4];
  uint8_t pinShift;
  uint8_t curState;
  uint8_t* lut;
  CCShield& brd;
  StepperL298N(CCShield& brd, uint8_t pinShift);
      
  void step(uint8_t dir);
  void halfStep(uint8_t yes) { if (yes) lut = halfStepLut; else lut = fullStepLut;}
  void start() { curState = 0xa;}
  void free() { curState = 0; }
  void brake() { curState = 0; }

  uint8_t fullStepLut[16];
  uint8_t halfStepLut[16];
};


StepperL298N::StepperL298N(CCShield& thebrd, uint8_t pinshift):brd(thebrd)
{
  cnt = 0;
//  pins[0] = pin1; pins[1] = pin2; pins[2]=pin3; pins[3] = pin4;
  pinShift = pinshift;
  lut = fullStepLut;
//  for (int i=0;i<4;i++)
//    pinMode(pins[i], OUTPUT);      // sets the digital pin as output
 
 memset(&fullStepLut,sizeof(uint8_t)*16,0);
 memset(&halfStepLut,sizeof(uint8_t)*16,0);
 
 // High nibble goes one way, low the other
 fullStepLut[0] = 0;
 // 1010 -> 1001 -> 0101 -> 0110
 fullStepLut[0xa] = 0x9 | 0x60;
 fullStepLut[0x9] = 0x5 | 0xa0;
 fullStepLut[0x5] = 0x6 | 0x90;
 fullStepLut[0x6] = 0xa | 0x50; 

 halfStepLut[0] = 0;
 // 1010 -> 1000 -> 1001 -> 0001 -> 0101 -> 0100 -> 0110 -> 0010
 halfStepLut[0xa] = 0x8 | 0x20;
 halfStepLut[0x8] = 0x9 | 0xa0; 
 halfStepLut[0x9] = 0x1 | 0x80;
 halfStepLut[0x1] = 0x5 | 0x90;
 halfStepLut[0x5] = 0x4 | 0x10;
 halfStepLut[0x4] = 0x6 | 0x50;
 halfStepLut[0x6] = 0x2 | 0x40; 
 halfStepLut[0x2] = 0xa | 0x60;
}

void StepperL298N::step(uint8_t dir)
{
  cnt+=1;
  curState = lut[curState];
  
  // Depending on the direction, go one way or the other.
  if (dir) curState &= 0xf;
  else curState >>= 4;
  
  #if 0
  for (int i=1,j=0;i<16;i<<=1,j++)
    {
    uint8_t lvl = LOW;
    if (i&curState) lvl=HIGH;
    digitalWrite(pins[j],lvl);
    }
  #endif
  brd.set(curState<<pinShift,cnt,0);
}


void LedDemo(CCShield& leds)
{
  int i;
  uint8_t j;
  
  for (i=0;i<5;i++)
    {
      leds.set(0xffffffff,0xffffffff,0xff);  // All on
      digitalWrite(ledPin,1);
      //bling(ON);
      delay(i*250);
      leds.set(0,0,0);  // All off
      digitalWrite(ledPin,0);
      //bling(OFF);
      delay(500);
    }
  
  for (i=5;i>=0;i--)
  {
    for (j=0;j<70;j++)
      { 
      // Set one LED on indexed by J
      leds.set(1L<<j,(j>=32) ? 1L<<(j-32):0,(j>=64) ? 1L<<(j-64):0 );
      delay(20*i);
      }
  }

#if 1
  // ALL FADE using M5451 Brightness feature
  leds.set(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  delay(1000);
  for (j=1;j<2;j++) 
   {
   for (i=0;i<256;i++)
      { 
      leds.setBrightness(i&255);
      delay(j*10);
      }
   for (i=255;i>=0;i--)
      { 
      leds.setBrightness(i&255);
      delay(j*10);
      }
}
#endif
  leds.setBrightness(255);
}


void BrightnessDemo(CCShield& brd)
{
  unsigned long int j;
  int i;
  FlickerBrightness leds(brd);
  
  brd.set(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  delay(250);
  brd.set(0,0,0);  /* ALL OFF */
  delay(250);
 
  // Linear per-LED brightness method
  if (1) for (j=0;j<4096;j++)
    {
      for (i=0;i<CCShield_NUMOUTS;i++)
        {
          int k = j*10;
          if (i&1)
          {        
            leds.brightness[i] = abs((k&(CCShield_MAX_BRIGHTNESS*2-1))-CCShield_MAX_BRIGHTNESS);
          }
          else
            leds.brightness[i] = CCShield_MAX_BRIGHTNESS - abs((k&(CCShield_MAX_BRIGHTNESS*2-1))-CCShield_MAX_BRIGHTNESS);
        }
      for (i=0;i<10;i++) leds.loop();
    }

  // MARQUEE
  
  for (i=0;i<CCShield_NUMOUTS;i++)  // Clear all LEDs to black
    {
      leds.brightness[i]=0;
    } 
    
  // Turn on a couple to make a "comet" with dimming tail  
  leds.brightness[0] =  CCShield_MAX_BRIGHTNESS-1; 
  leds.brightness[1] =  CCShield_MAX_BRIGHTNESS/2; 
  leds.brightness[2] =  CCShield_MAX_BRIGHTNESS/4; 
  leds.brightness[3] =  CCShield_MAX_BRIGHTNESS/8; 
  leds.brightness[4] =  CCShield_MAX_BRIGHTNESS/16; 
  leds.brightness[5] =  CCShield_MAX_BRIGHTNESS/64; 
  leds.brightness[6] =  CCShield_MAX_BRIGHTNESS/100; 

  for (j=0;j<100;j++)
    {
      leds.shift(1);
      for (i=0;i<150;i++) leds.loop();
    }
    
  for (j=0;j<100;j++)
    {
      leds.shift(-1);
      for (i=0;i<100;i++) leds.loop();
    }
  
}


void loop()                     // run over and over again
{
  unsigned long int j;

  CCShield out(myClockPin,mySerDataPin,mySerDataPin2, myBrightnessPin);
  
  out.setBrightness(255);
  
  LedDemo(out);

#if 0
  BrightnessDemo(out);
    
  out.set(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  delay(1000);
  out.set(0,0,0);  /* ALL ON */
#endif

#if 0
  StepperL298N motor(out,1);
  motor.halfStep(true);
  motor.start();

  for (j=0;j<3000;j++)
    { 
    motor.step((j>>9)&1);
    //digitalWrite(ledPin, j&1);   // sets the LED on
    //delay(2+(1000-j)/100);
    //digitalWrite(ledPin, LOW);    // sets the LED off
    //delay(3000);
    delay(4);
    }

  motor.halfStep(false);
  motor.start();
  for (j=0;j<3000;j++)
    { 
    motor.step((j>>9)&1);
    //digitalWrite(ledPin, j&1);   // sets the LED on
    //delay(2+(1000-j)/100);
    //digitalWrite(ledPin, LOW);    // sets the LED off
    delay(5);
    }
#endif
}




int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

