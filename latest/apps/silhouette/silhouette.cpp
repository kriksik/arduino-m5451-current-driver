/* Silouette: a 70 image ceiling display
 * Version 1.0  March 2009
 * Author: G. Andrew Stone
 * Released under the MIT license (http://www.opensource.org/licenses/mit-license.php)
 */
 
#include <avr/power.h>
#include <avr/sleep.h>
#include <avr/pgmspace.h>

#include <CCShield.h>

#include "WProgram.h"
byte cvt(byte x,byte y);
byte cvt(byte in);
unsigned long int gerhardRand(unsigned long int lim);
void sleepInterrupt();
void wakeNow();
void nop();
void setup();
void sleepNow();
void etchInterrupt();
void DelayByLeftDial();
void loop();
const byte myClockPin = 3;                // Arduino pin that goes to M5451 clock
const byte mySerDataPin = 4;              // Arduino pin that goes to M5451 data
const byte mySerDataPin2 = 5;             // Arduino pin that goes to the OTHER M5451's data

// Input:
const byte wakePin = 2;
const byte leftDial = 0;
const byte rightDial = 1;

#define ANALOG_READ_MAX (1024/2) // 2 is because the voltage divider means that I only use half of the analog voltage range

byte state = 1;
int lightRate = 63; //1023;

// LED layout.  If the LEDs in your grid are not wired linearly this translation table can adjust them
// but you must update the values to reflect your grid.
prog_uchar layout[] PROGMEM = { 
  0,1,4,5,35,36,37,
  2,3,6,7,38,40,42,
  8,9,13,12,39,41,43,
  10,11,14,15,44,46,48,
  16,17,21,20,45,47,49,
  18,19,22,23,50,52,54,
  24,25,28,29,51,53,55,
  26,27,30,31,56,59,58,
  32,33,67,65,57,58,60,
  34,69,68,66,62,63,64
};

// LED grid conversion
byte cvt(byte x,byte y)
{
  x = y*7+x;
  if (x < 70)
    return pgm_read_byte_near(layout + x);
  return 255;
}

byte cvt(byte in)
{
  if (in < 70)
    return pgm_read_byte_near(layout + in);
  return 255;
}

// A simple pseudo-random number generator
unsigned long int seed=1;
unsigned long int gerhardRand(unsigned long int lim)
{
  seed=(seed*32719 + 3) % 32749;
  return (seed % lim);
}

// Interrupt handlers:

void sleepInterrupt()
{
  state = !state;
  detachInterrupt(wakePin-2);
}

void wakeNow()
{
}

void nop()
{
}


void setup()                    // run once, when the sketch starts
{
  pinMode(wakePin,INPUT);
  digitalWrite(wakePin,HIGH);  
  attachInterrupt(wakePin-2,sleepInterrupt,RISING);
}

// Put the System to sleep when the power button is pressed, or the mode times out
void sleepNow()
{
  //attachInterrupt(wakePin-2,wakeNow,RISING);
  set_sleep_mode(SLEEP_MODE_IDLE);  //PWR_DOWN);
  sleep_enable();
  power_adc_disable();
  power_spi_disable();
  power_timer0_disable();
  power_timer1_disable();
  power_timer2_disable();
  power_twi_disable();
  attachInterrupt(wakePin-2,wakeNow,RISING);  // Attach our wakeup interrupt
  sleep_mode();  // Goodnight
  
  // Once we get here, it has woken up!
  sleep_disable();
  power_all_enable();
  attachInterrupt(wakePin-2,nop,RISING); // Debounce reset button input -- throw away any pending interrupts (detachInterrupt leaves them pending)
  delay(250);   // Debounce reset button input -- wait for button unpress
}  

// Random Fader Mode

void DeltaDone(ChangeBrightness& me, int led)
{
  if (me.brd.brightness[led]<160) me.brd.brightness[led]=0;  /* all done */
  else me.set(led,0,me.count[led]);  /* Dim it in the same # of steps */  
}

void RandomFader(CCShield& brd,unsigned long int time)
{
  FlickerBrightness f(brd);
  ChangeBrightness display(f,DeltaDone);
  unsigned long int i;
  byte curBrightness = (analogRead(rightDial)/(ANALOG_READ_MAX/256));
  
  brd.setBrightness(255);  // By default highest brightness unless the dial is moved
  
  state = 1;
  for (i=0;(i<time) && state;i++)
  {       
    attachInterrupt(wakePin-2,sleepInterrupt,RISING);
    lightRate = analogRead(leftDial);
    lightRate = lightRate*2;
    if (lightRate < 5) lightRate=5;

    if (1)  // Adjust brightness.  Do it in an isolated block to save a byte
      {
      byte brightness = (analogRead(rightDial)/ (ANALOG_READ_MAX/256));
      // Deliberately only set the brightness if the dial is moved
      // so it will be highest brightness unless explicitly adjusted.
      if (brightness != curBrightness) brd.setBrightness(brightness);
      }
    
    if ((i%lightRate)==0)
      {
      byte led = gerhardRand(CCShield_NUMOUTS);
      display.set(led,gerhardRand(MaxBrightness-1),gerhardRand(MaxBrightness));
      }
    display.loop();
   }
}


// Etch-a-Sketch mode
byte etchOn=0;
void etchInterrupt()
{
  etchOn=!etchOn;
  attachInterrupt(wakePin-2,nop,RISING);

}

void EtchSketch(CCShield& brd,unsigned long int time)
{
  unsigned long int a,b;
  byte c;
  byte lastEtchOn=etchOn;

  state=1;
  attachInterrupt(wakePin-2,etchInterrupt,RISING);

  for (unsigned long int cnt=0;(cnt<time) && state;cnt++)
    {
    if (etchOn != lastEtchOn) 
      {
        lastEtchOn=etchOn;
        delay(100);  // debounce
        attachInterrupt(wakePin-2,etchInterrupt,RISING);
      }
        
    if (lastEtchOn==0) { a=0;b=0;c=0;}
      
    unsigned int val = analogRead(leftDial);      
    byte x = val/ (ANALOG_READ_MAX/7);
    val = analogRead(rightDial); 
    byte y = val/ (ANALOG_READ_MAX/10);
    if (x>6) x = 6;
    if (y>9) y = 9;
    setbit(cvt(x,y),&a,&b,&c);
    brd.set(a,b,c);    
    delay(100);
    if ((x==0)&&(y==0))  // Get out
      {
        if (digitalRead(wakePin)==HIGH) return;
      }
    }
}



// This mode displays the LEDs in various sequences, such as vertical and horizontal bars
void DelayByLeftDial()
{
    lightRate = analogRead(leftDial);
    lightRate = lightRate*2;
    delay(lightRate);
}

void Sequence(CCShield& brd,unsigned long int time)
{
  
  byte i;
  unsigned long int a,b;
  byte c;
  
  //attachInterrupt(wakePin-2,nop,RISING);
  //delay(250);
  state = 1;
  
  for (unsigned long int cnt=0;(cnt<time) && state;cnt++)
  {       
    attachInterrupt(wakePin-2,sleepInterrupt,RISING);

    int val = analogRead(rightDial); 
    byte seq = val/ (ANALOG_READ_MAX/3);

  // Horizontal bar
    if (seq==0)
       {
       for (i=0;(i<19) && state;i++)
         {
         a=0;b=0;c=0;
         for (byte j=0;j<7;j++)
           setbit(cvt(j,abs(10-i)),&a,&b,&c);
         brd.set(a,b,c);    
         DelayByLeftDial();
         }
       }
    else if (seq==1)
      {
      // Vertical bar
      for (i=0;(i<12) && state;i++)
        {
        a=0;b=0;c=0;
        for (byte j=0;j<10;j++)
          setbit(cvt(abs(6-i),j),&a,&b,&c);
        brd.set(a,b,c);
        DelayByLeftDial();
        }
      }
    else if (seq == 2)
      {
      for(i=0;i<70 && state; i++)
        {
        a=0;b=0;c=0;
        setbit(cvt(i),&a,&b,&c);
        brd.set(a,b,c);
        DelayByLeftDial(); 
        }
    }
    
  }  
}

 
#define NUMMODES 3

void loop()                     // run over and over again
{
  unsigned long int time;
  byte i=0;
  
  CCShield out(myClockPin,mySerDataPin,mySerDataPin2, 11);
  
  out.setBrightness(255);
  //out.set(0xffffffff,0xffffffff,0xf);
  //delay(250);

  if (digitalRead(wakePin)==HIGH)  // Still held -- mode select
    {
      unsigned long start = millis();
      while (digitalRead(wakePin)==HIGH) 
        {
          unsigned long mode = (millis()-start)/500;
          mode = mode % NUMMODES;
          out.set(1UL<<cvt(mode,0),0,0);
          delay(50);
          i = mode;
        }
    }

  if (1)
    {  
    time = analogRead(rightDial);
    time = time * 4000;
    if (time < 5000) time = 5000;
    if (i==0)
      RandomFader(out,time);
    else if (i==1)
      Sequence(out,time);
    else if (i==2)
      EtchSketch(out,time);
    //out.set(0xffffffff,0xffffffff,0xf);  /* ALL OFF */
    out.set(0,0,0);  /* ALL OFF */
    delay(500);   // Debounce reset button input
    //attachInterrupt(wakePin-2,sleepInterrupt,RISING);
    out.set(0,0,0);  /* ALL OFF */
    sleepNow();  
    }
}




int main(void)
{
	init();

	setup();
    
	for (;;)
		loop();
        
	return 0;
}

