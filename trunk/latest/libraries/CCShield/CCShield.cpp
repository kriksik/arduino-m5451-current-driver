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

#include "CCShield.h"
#include "WProgram.h"
#include <inttypes.h>

void setbit(byte offset,unsigned long int* a, unsigned long int* b, byte* c)
{
  if (offset < 32) *a |= 1UL<<offset;
  else if (offset < 64) *b |= 1UL<<(offset-32);
  else if (offset < CCShield_NUMOUTS) *c |= 1UL<<(offset-64);
}

void clearbit(byte offset,unsigned long int* a, unsigned long int* b, byte* c)
{
  if (offset < 32) *a &= ~(1UL<<offset);
  else if (offset < 64) *b &= ~(1UL<<(offset-32));
  else if (offset < CCShield_NUMOUTS) *c &= ~(1UL<<(offset-64));
}

// Sets the brightness of ALL LEDs using the M5451 brightness control
void CCShield::setBrightness(uint8_t b)
{
  if (brightPin<0xff)
    analogWrite(brightPin,b);
}


ChangeBrightness::ChangeBrightness(FlickerBrightness& thebrd,void (*doneCallback)(ChangeBrightness& me, int led)):brd(thebrd)
{
  doneCall = doneCallback;
  for (int i=0;i<CCShield_NUMOUTS;i++)
    {
      change[i] = 0;
      count[i]  = 0;
      countdn[i] = 0;
      bresenham[i] = 0;
    }
}

void ChangeBrightness::set(int led, int intensity, int transitionDuration)
{
  if (led<CCShield_NUMOUTS)
  {
  count[led] = transitionDuration;
  countdn[led] = transitionDuration;
  change[led] = ((long int) intensity) - ((long int) brd.brightness[led]);
  }
}

void ChangeBrightness::loop(void)
{
  int j;
  for (j=0;j<CCShield_NUMOUTS;j++)
  {
    if (countdn[j]>0) // This led is changing
    {
      bresenham[j] += change[j];
      /* Note that if change could be > count then this should be a while loop */
      while (bresenham[j]<0) { bresenham[j]+=count[j]; brd.brightness[j]--;}
      while (bresenham[j]>=count[j]) { bresenham[j]-=count[j]; brd.brightness[j]++;}
      countdn[j] -= 1;

      if ((countdn[j]==0)&&doneCall)  /* app-specific cheat; bring it back to 0 now */
      {
        (*doneCall)(*this,j);
      }
    }

  }

  brd.loop();
}


FlickerBrightness::FlickerBrightness(CCShield& mybrd):brd(mybrd)
{
  for (int i=0;i<CCShield_NUMOUTS;i++)
  {
    brightness[i] = 0;
    bresenham[i]  = 0;
  }
  
  //iteration = 0;
  offset = 0;
}

void FlickerBrightness::loop(void)
{
  int i;
  uint8_t pos;
  unsigned long int a[3] = {0,0,0};
  boolean lvl=false;
  
  for (i=0,pos=offset;i<CCShield_NUMOUTS;i++,pos++)
    {
      if (pos>=CCShield_NUMOUTS) pos=0;
      bresenham[i] += brightness[pos];
      if (bresenham[i]>=MaxBrightness) 
        {
          bresenham[i] -= MaxBrightness;
          lvl = true;
        }
      else lvl = false;
      
      if (i<32) a[0] = (a[0]<<1)|lvl;
      else if (i<64) a[1] = (a[1]<<1)|lvl;
      else a[2] = a[2]<<1|lvl;
    }
  //iteration++;
  //if (iteration > MaxBrightness) iteration = 0;  
  
  brd.set(a);
}


CCShield::CCShield(uint8_t clkPin, uint8_t dataPin1, uint8_t dataPin2, uint8_t brightnessPin)
{
  int i;
  
  clockPin = clkPin;
  serDataPin[0] = dataPin1;
  serDataPin[1] = dataPin2;
  brightPin = brightnessPin;
  
  pinMode(clkPin, OUTPUT);      // sets the digital pin as output
  pinMode(serDataPin[0], OUTPUT);      // sets the digital pin as output
  pinMode(serDataPin[1], OUTPUT);      // sets the digital pin as output
  pinMode(brightPin,OUTPUT);

  // Clear out the device so we can clock in items
  digitalWrite(serDataPin[0],LOW);  
  digitalWrite(serDataPin[1],LOW);  
  for (i=0;i<M5451_NUMOUTS+2;i++)
    {
    mydelay(M5451_CLK);
    digitalWrite(clockPin,HIGH);
    mydelay(M5451_CLK);
    digitalWrite(clockPin,LOW);    
    }
}

int CCShield::mydelay(unsigned long int clk)
{
  unsigned long int i;
  unsigned long int j=0;
  for (i=0;i<clk;i++) 
    {
      j+=3*i;
      i+=1;
      j-=i*j/7;
    }
  //delay(1);
  return j;
}


void CCShield::set(unsigned long int a, unsigned long int b, unsigned long int c)
{
  unsigned long int data[3];
  data[0] = a; data[1]=b; data[2]=c;
  set(data);
}

#if 1
void CCShield::set(unsigned long int a[3])
{
  int i;

  // Write the initial "start" signal
  digitalWrite(clockPin,LOW);
  digitalWrite(serDataPin[0],LOW);
  digitalWrite(serDataPin[1],LOW);

  mydelay(M5451_CLK);
  digitalWrite(clockPin,HIGH);
  mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
  mydelay(M5451_CLK);
  digitalWrite(serDataPin[0],HIGH);
  digitalWrite(serDataPin[1],HIGH);
  mydelay(M5451_CLK);
  digitalWrite(clockPin,HIGH);

  uint8_t hiclk = PORTD;

  mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
 
  unsigned long int b[2];
  b[0] = (a[1]>>3 | (a[2] << 29));
  b[1] = (a[2]>>3);
  // Write the bits
  uint8_t curval=PORTD;
  
  curval &= ~((1<<serDataPin[0]) | (1<<serDataPin[1]));
  
  unsigned int dpOn[4];
  dpOn[0] = 0;
  dpOn[1] = (1<<serDataPin[0]);
  dpOn[2] = (1<<serDataPin[1]);
  dpOn[3] = dpOn[1] | dpOn[2];
  
  
  for (i=0;i<32;i++)
  {
    uint8_t lkup = (a[0]&1)+((b[0]&1)<<1);
    a[0]>>=1; b[0]>>=1;
    
    PORTD = curval | dpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk;
    //mydelay(M5451_CLK);
  }
  
    for (i=0;i<M5451_NUMOUTS-32;i++)
  {
    uint8_t lkup = (a[1]&1)+((b[1]&1)<<1);    
    a[1]>>=1; b[1]>>=1;    
    PORTD = curval | dpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk; 
    //mydelay(M5451_CLK);
  }
  
  #if 0
      for (i=0;i<4;i++)
  {
    uint8_t serDataVal[2];
    if (i<32) { serDataVal[0] = (a[0]&1); a[0]>>=1;}
    else { serDataVal[0] = (a[1]&1); a[1]>>=1;}
    if (i<32) { serDataVal[1] = (b[0]&1); b[0]>>=1;}
    else { serDataVal[1] = (b[1]&1); b[1]>>=1;}
    
    PORTD = curval | dpOn[(serDataVal[1]<<1)+serDataVal[0]];
    PORTD |= hiclk; 
  }
  #endif
}
#endif

#if 0
void CCShield::set(unsigned long int a[3])
{
  int i;

  // Write the initial "start" signal
  digitalWrite(clockPin,LOW);
  digitalWrite(serDataPin[0],LOW);
  digitalWrite(serDataPin[1],LOW);

  mydelay(M5451_CLK);
  digitalWrite(clockPin,HIGH);
  mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
  mydelay(M5451_CLK/2);
  digitalWrite(serDataPin[0],HIGH);
  digitalWrite(serDataPin[1],HIGH);
  mydelay(M5451_CLK/2);
  digitalWrite(clockPin,HIGH);

  mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
 
  unsigned long int d2[2];
  d2[0] = a[1]>>3 | (a[2] << 29);
  d2[1] = a[2]>>3;
  // Write the bits
  uint8_t curval=PORTD;
  
  curval &= ~((1<<serDataPin[0]) | (1<<serDataPin[1]));
  
  unsigned int dpOn[4];
  dpOn[0] = 0;
  dpOn[1] = (1<<serDataPin[0]);
  dpOn[2] = (1<<serDataPin[1]);
  dpOn[3] = dpOn[1] | dpOn[2];
  
  
  for (i=0;i<M5451_NUMOUTS;i++)
  {
    int serDataVal[2];
    if (i<32) { serDataVal[0] = (a[0]&1); a[0]>>=1;}
    else { serDataVal[0] = (a[1]&1); a[1]>>=1;}
    if (i<32) { serDataVal[1] = (d2[0]&1); d2[0]>>=1;}
    else { serDataVal[1] = (d2[1]&1); d2[1]>>=1;}
    
    mydelay(M5451_CLK/2);
    digitalWrite(serDataPin[0],serDataVal[0]);
    digitalWrite(serDataPin[1],serDataVal[1]);
    mydelay(M5451_CLK/2);
    digitalWrite(clockPin,HIGH);
    mydelay(M5451_CLK);
    digitalWrite(clockPin,LOW);
  }
}
#endif
