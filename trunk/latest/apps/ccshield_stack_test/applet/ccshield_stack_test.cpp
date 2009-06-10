#include <CCShield.h>

/*
 * Constant-Current Shield M5451 LED driver chip test and example
 * Author: G. Andrew Stone
 * Public Domain
 */


#include "WProgram.h"
void setup();
void LedDemo(CCShield* brd[2]);
void loop();
int ledPin = 13;  // The normal arduino example LED

void setup()                    // run once, when the sketch starts
{
}


void LedDemo(CCShield* brd[2])
{
  int i;
  uint8_t j;
  
  for (i=0;i<5;i++)
    {
      brd[0]->set(0xffffffff,0xffffffff,0xff);  // All on
      brd[1]->set(0xffffffff,0xffffffff,0xff);  // All on
      digitalWrite(ledPin,1);
      //bling(ON);
      delay(i*250);
      brd[0]->set(0,0,0);  // All off
      brd[1]->set(0,0,0);  // All off
      digitalWrite(ledPin,0);
      //bling(OFF);
      delay(500);
    }
  
  for (i=5;i>=0;i--)
  {
    for (j=0;j<70;j++)
      { 
      // Set one LED on indexed by J
      brd[0]->set(1L<<j,(j>=32) ? 1L<<(j-32):0,(j>=64) ? 1L<<(j-64):0 );
      brd[1]->set(1L<<j,(j>=32) ? 1L<<(j-32):0,(j>=64) ? 1L<<(j-64):0 );
      delay(20*i);
      }
  }

#if 1
  // ALL FADE using M5451 Brightness feature
  brd[0]->set(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  brd[1]->set(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  delay(1000);
  for (j=1;j<2;j++) 
   {
   for (i=0;i<256;i++)
      { 
      brd[0]->setBrightness(i&255);
      brd[1]->setBrightness(255-(i&255));
      delay(j*10);
      }
   for (i=255;i>=0;i--)
      { 
      brd[0]->setBrightness(i&255);
      brd[1]->setBrightness(255-(i&255));
      delay(j*10);
      }
}
#endif
  brd[0]->setBrightness(255);
}


void BrightnessDemo(CCShield& b1,CCShield& b2)
{
  unsigned long int j;
  int i;
  
  b1.safeSet(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  b2.safeSet(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  delay(250);
  b1.safeSet(0,0,0);  /* ALL OFF */
  b2.safeSet(0,0,0);  /* ALL OFF */
  delay(250);
 
  // Linear per-LED brightness method
  if (1) 
    {
      FlickerBrightness f1(b1);
      FlickerBrightness f2(b2);

      for (j=0;j<4096;j++)
    {
      for (i=0;i<CCShield_NUMOUTS;i++)
        {
          int k = j*10;
          if (i&1)
          {        
            f1.brightness[i] = abs((k&(CCShield_MAX_BRIGHTNESS*2-1))-CCShield_MAX_BRIGHTNESS);
            f2.brightness[i] = abs((k&(CCShield_MAX_BRIGHTNESS*2-1))-CCShield_MAX_BRIGHTNESS);
          }
          else
            f1.brightness[i] = CCShield_MAX_BRIGHTNESS - abs((k&(CCShield_MAX_BRIGHTNESS*2-1))-CCShield_MAX_BRIGHTNESS);
            f2.brightness[i] = abs((k&(CCShield_MAX_BRIGHTNESS*2-1))-CCShield_MAX_BRIGHTNESS);
        }
      for (i=0;i<10;i++) { f1.loop(); f2.loop(); }
    }
    }
}


void loop()                     // run over and over again
{
  unsigned long int j;

#if 0
int myClockPin =     2;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin =   3; // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 =  8; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 11;          // What Arduino pin goes to the brightness ping on the M5451s
#endif
             //myClockPin,mySerDataPin,mySerDataPin2, myBrightnessPin
  CCShield brd1(2,3,8, 11);
  CCShield brd2(5,6,7, 10);
  CCShield* brd[2] = { &brd1, &brd2 };
  brd[0]->setBrightness(255);
  brd[1]->setBrightness(255);
  
  LedDemo(brd);

#if 0
  BrightnessDemo(out);
    
  out.safeSet(0xffffffff,0xffffffff,0xff);  /* ALL ON */
  delay(1000);
  out.safeSet(0,0,0);  /* ALL ON */
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

