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

#include "WProgram.h"
#include "inttypes.h"
#include "wiring.h"
//extern void analogWrite(uint8_t,int);

#include "lightuino.h"

#define M5451_CLK 1

void setbit(unsigned char offset,unsigned long int* a, unsigned long int* b, unsigned char* c)
{
  if (offset < 32) *a |= 1UL<<offset;
  else if (offset < 64) *b |= 1UL<<(offset-32);
  else if (offset < Lightuino_NUMOUTS) *c |= 1UL<<(offset-64);
}

void clearbit(unsigned char offset,unsigned long int* a, unsigned long int* b, unsigned char* c)
{
  if (offset < 32) *a &= ~(1UL<<offset);
  else if (offset < 64) *b &= ~(1UL<<(offset-32));
  else if (offset < Lightuino_NUMOUTS) *c &= ~(1UL<<(offset-64));
}

// Sets the brightness of ALL LEDs using the M5451 brightness control
void Lightuino::setBrightness(uint8_t b)
{
  if (brightPin<0xff)
    analogWrite(brightPin,b);
}


ChangeBrightness::ChangeBrightness(FlickerBrightness& thebrd,void (*doneCallback)(ChangeBrightness& me, int led)):brd(thebrd)
{
  doneCall = doneCallback;
  for (int i=0;i<Lightuino_NUMOUTS;i++)
    {
      change[i] = 0;
      count[i]  = 0;
      destination[i] = 0;
      bresenham[i] = 0;
    }
}

void ChangeBrightness::set(uint8_t led, uint8_t intensity, int transitionDuration)
{
  if (led<Lightuino_NUMOUTS)
  {
    if (transitionDuration<1) transitionDuration=1;  // Fix up impossible values
    count[led] = transitionDuration;
    destination[led] = intensity;
    change[led] = ((long int) intensity) - ((long int) brd.brightness[led]);
  }
}

void ChangeBrightness::loop(void)
{
  byte j;
  for (j=0;j<Lightuino_NUMOUTS;j++)
  {
    if (destination[j] != brd.brightness[j]) // This led is changing
    {
      bresenham[j] += change[j];
      /* Note that if change could be > count then this should be a while loop */
      while ((bresenham[j]<0)&& (brd.brightness[j] != destination[j]))
        { bresenham[j]+=count[j]; brd.brightness[j]--;}
      while ((bresenham[j]>=count[j])&& (brd.brightness[j] != destination[j])) { bresenham[j]-=count[j]; brd.brightness[j]++;}

      if ((brd.brightness[j]==destination[j])&&doneCall)
      {
        bresenham[j]=0;
        (*doneCall)(*this,j);
      }
    }
  }

  brd.loop();
}


FlickerBrightness::FlickerBrightness(Lightuino& mybrd):brd(mybrd)
{
  for (int i=0;i<Lightuino_NUMOUTS;i++)
  {
    brightness[i] = 0;
    bresenham[i]  = 0;
  }
  
  //iteration = 0;
  offset = Lightuino_NUMOUTS-1;
  minBrightness = 11;
  next = 0;
}

void FlickerBrightness::loop(void)
{
  char i;
  char pos;
  unsigned long int a[3] = {0,0,0};
  uint8_t lvl=false;

  for (i=Lightuino_NUMOUTS-1,pos=offset;i>=0;i--,pos--)
    {
      if (pos<0) pos = Lightuino_NUMOUTS-1;
      int temp = brightness[pos];

      // This provides support for saturating arithemetic in the brightness, AND enforces the minimum brightness
      if (temp>Lightuino_MAX_BRIGHTNESS) temp = Lightuino_MAX_BRIGHTNESS;
      if (temp<minBrightness) temp = 0;
      
      bresenham[i] += temp;
      if (bresenham[i]>=Lightuino_MAX_BRIGHTNESS) 
        {
          bresenham[i] -= Lightuino_MAX_BRIGHTNESS;
          lvl = true;
        }
      else lvl = false;
      
      if (i<32) a[0] = (a[0]<<1)|lvl;
      else if (i<64) a[1] = (a[1]<<1)|lvl;
      else a[2] = (a[2]<<1)|lvl;
    }
  //iteration++;
  //if (iteration > Lightuino_MAX_BRIGHTNESS) iteration = 0;  
  
  brd.set(a);
}


Lightuino::Lightuino(uint8_t clkPin, uint8_t dataPin1, uint8_t dataPin2, uint8_t brightnessPin)
{
  int i;
  flags = Lightuino_FASTSET;
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

int Lightuino::mydelay(unsigned long int clk)
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

void Lightuino::set(unsigned long int a, unsigned long int b, unsigned long int c)
{
  unsigned long int data[3];
  data[0] = a; data[1]=b; data[2]=c;
  if (flags&Lightuino_FASTSET)
    {
    if (flags&Lightuino_BY32) fastSetBy32(data);
    else fastSet(data);
    }
  else safeSet(data);
}

void Lightuino::set(unsigned char* a)
{
  unsigned long int data[3];
  data[0] = *((unsigned long int*) a); 
  data[1]=*((unsigned long int*) (a+4)); 
  data[2]= a[8];
  if (flags&Lightuino_FASTSET)
    {
    if (flags&Lightuino_BY32) fastSetBy32(data);
    else fastSet(data);
    }
  else safeSet(data);
}


void Lightuino::set(unsigned long int a[3])
{
  if (flags&Lightuino_FASTSET) 
    {
    if (flags&Lightuino_BY32) fastSetBy32(a);
    else fastSet(a);
    }
  else safeSet(a);

}

void Lightuino::fastSet(unsigned long int a, unsigned long int b, unsigned long int c)
{
  unsigned long int data[3];
  data[0] = a; data[1]=b; data[2]=c;
  fastSet(data);
}

void Lightuino::fastSetBy32(unsigned long int left, unsigned long int right, unsigned long int overflow)
{
  unsigned long int data[3];
  data[0] = left; data[1]=right; data[2]=overflow;
  fastSetBy32(data);
}


void Lightuino::fastSet(unsigned long int a[3])
{
  uint8_t i;

  // Write the initial "start" signal
  digitalWrite(clockPin,LOW);
  digitalWrite(serDataPin[0],LOW);
  digitalWrite(serDataPin[1],LOW);

  // Remember the low values
  uint8_t dcurval  = PORTD;
  uint8_t bcurval = PORTB;

  //mydelay(M5451_CLK);
  digitalWrite(clockPin,HIGH);
  //mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
  //mydelay(M5451_CLK);
  digitalWrite(serDataPin[0],HIGH);
  digitalWrite(serDataPin[1],HIGH);
  //mydelay(M5451_CLK);
  digitalWrite(clockPin,HIGH);

  uint8_t hiclk = PORTD;

  //mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
 
  unsigned long int b[2];
  b[0] = (a[1]>>3 | (a[2] << 29));
  b[1] = (a[2]>>3);

#if 0
  if (serDataPin[0]<8) curval &= ~(1<<serDataPin[0]);
  if (serDataPin[1]<8) curval &= ~(1<<serDataPin[1]);
  if (serDataPin[0]>=8) bcurval &= ~(1<<(serDataPin[0]-8));
  if (serDataPin[1]>=8) bcurval &= ~(1<<(serDataPin[1]-8));
#endif  
  
  // Set up all possible values for PORTD
  uint8_t dpOn[4];
  dpOn[0] = dcurval;
  //digitalPinToBitMask(serDataPin[0]);
  if (serDataPin[0]<8) dpOn[1] = dcurval | (1<<serDataPin[0]);
  else dpOn[1] = dcurval;  
  if (serDataPin[1]<8) dpOn[2] = dcurval | (1<<serDataPin[1]);
  else dpOn[2] = dcurval;
  dpOn[3] = dcurval | (dpOn[1] | dpOn[2]);

  // Set up all possible values for PORTB
  uint8_t bpOn[4];
  bpOn[0] = bcurval;
  if (serDataPin[0]>=8) bpOn[1] = bcurval | (1<<(serDataPin[0]-8));
  else bpOn[1] = bcurval;
  if (serDataPin[1]>=8) bpOn[2] = bcurval | (1<<(serDataPin[1]-8));
  else bpOn[2] = bcurval;
  bpOn[3] = bcurval | (bpOn[1] | bpOn[2]);
  
  
  for (i=0;i<32;i+=2)
  {
    uint8_t lkup = (a[0]&1)+((b[0]&1)<<1);
    
    PORTD = dpOn[lkup];
    PORTB = bpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk;
    //mydelay(M5451_CLK);
    lkup = ((a[0]&2)>>1)+(b[0]&2);
    
    PORTD = dpOn[lkup];
    PORTB = bpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk;    
    a[0]>>=2; b[0]>>=2;   
  }
  
    for (i=0;i<M5451_NUMOUTS-32;i++)
  {
    uint8_t lkup = (a[1]&1)+((b[1]&1)<<1);    
    a[1]>>=1; b[1]>>=1;    
    PORTD = dpOn[lkup];
    PORTB = bpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk; 
    //mydelay(M5451_CLK);
  }
}

void Lightuino::fastSetBy32(unsigned long int input[3])
{
  uint8_t i;

  // Write the initial "start" signal
  digitalWrite(clockPin,LOW);
  digitalWrite(serDataPin[0],LOW);
  digitalWrite(serDataPin[1],LOW);

  // Remember the low values
  uint8_t dcurval  = PORTD;
  uint8_t bcurval = PORTB;

  //mydelay(M5451_CLK);
  digitalWrite(clockPin,HIGH);
  //mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
  //mydelay(M5451_CLK);
  digitalWrite(serDataPin[0],HIGH);
  digitalWrite(serDataPin[1],HIGH);
  //mydelay(M5451_CLK);
  digitalWrite(clockPin,HIGH);

  uint8_t hiclk = PORTD;

  //mydelay(M5451_CLK);
  digitalWrite(clockPin,LOW);
 
  // Make "a" contain what should be programmed to one of the chips
  // and "b" contain what to program to the other chip 
  unsigned long int a[2];
  unsigned long int b[2];
  a[0] = input[0];
  b[0] = input[1];
  b[1] = input[2]>>3;
  a[1] = input[2];
  
  // Set up all possible values for PORTD
  uint8_t dpOn[4];
  dpOn[0] = dcurval;
  //digitalPinToBitMask(serDataPin[0]);
  if (serDataPin[0]<8) dpOn[1] = dcurval | (1<<serDataPin[0]);
  else dpOn[1] = dcurval;  
  if (serDataPin[1]<8) dpOn[2] = dcurval | (1<<serDataPin[1]);
  else dpOn[2] = dcurval;
  dpOn[3] = dcurval | (dpOn[1] | dpOn[2]);

  // Set up all possible values for PORTB
  uint8_t bpOn[4];
  bpOn[0] = bcurval;
  if (serDataPin[0]>=8) bpOn[1] = bcurval | (1<<(serDataPin[0]-8));
  else bpOn[1] = bcurval;
  if (serDataPin[1]>=8) bpOn[2] = bcurval | (1<<(serDataPin[1]-8));
  else bpOn[2] = bcurval;
  bpOn[3] = bcurval | (bpOn[1] | bpOn[2]);
  
  
  for (i=0;i<32;i+=2)
  {
    uint8_t lkup = (a[0]&1)+((b[0]&1)<<1);
    
    PORTD = dpOn[lkup];
    PORTB = bpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk;
    //mydelay(M5451_CLK);
    lkup = ((a[0]&2)>>1)+(b[0]&2);
    
    PORTD = dpOn[lkup];
    PORTB = bpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk;    
    a[0]>>=2; b[0]>>=2;   
  }
  
    for (i=0;i<M5451_NUMOUTS-32;i++)
  {
    uint8_t lkup = (a[1]&1)+((b[1]&1)<<1);    
    a[1]>>=1; b[1]>>=1;    
    PORTD = dpOn[lkup];
    PORTB = bpOn[lkup];
    //mydelay(M5451_CLK);
    PORTD |= hiclk; 
    //mydelay(M5451_CLK);
  }
}


void Lightuino::safeSet(unsigned long int a, unsigned long int b, unsigned long int c)
{
  unsigned long int data[3];
  data[0] = a; data[1]=b; data[2]=c;
  safeSet(data);
}

void Lightuino::safeSet(unsigned long int a[3])
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

void AniPattern::next(void)
{
  unsigned long int bits[3];

  bits[0] = pgm_read_dword_near(ani + curFrame);
  bits[1] = pgm_read_dword_near(ani + curFrame+4);
  bits[2] = pgm_read_byte_near(ani + curFrame+8);
  shield.set(bits);
  int d = pgm_read_word_near(delays + curDelay);
  delay(d);
      
  curFrame+=(anidir*9);
  curDelay+=anidir;

  if (curDelay >= numFrames) 
    { 
    if (flags&1) { anidir = -1; curDelay=numFrames-2; curFrame = (numFrames-2)*9; }
    else { curFrame=0; curDelay=0; }    
    }
  else if (curDelay < 0)
  {
    if (flags&1) { anidir = 1; curDelay=1; curFrame = 9; }
    else { curDelay=numFrames-1; curFrame=(numFrames-1)*9; }    
  }
}


// Code from: http://www.uchobby.com/index.php/2007/11/24/arduino-interrupts/
// Setup Timer2.
//Configures the ATMegay168 8-Bit Timer2 to generate an interrupt at the specified frequency.
//Returns the time load value which must be loaded into TCNT2 inside your ISR routine.
//See the example usage below.
#define TIMER_CLOCK_FREQ (16000000.0/128.0) //2MHz for /8 prescale from 16MHz
FlickerBrightness* gleds= 0;
unsigned int timerLatency;
unsigned char timerLoadValue;

#define TOGGLE_IO 13

ISR(TIMER2_OVF_vect) {
  FlickerBrightness* tmp = gleds;
  //Toggle the IO pin to the other state.
  //digitalWrite(TOGGLE_IO,!digitalRead(TOGGLE_IO));
  while (tmp) { tmp->loop(); tmp=tmp->next; }  
  
  //Capture the current timer value. This is how much error we have
  //due to interrupt latency and the work in this function
  timerLatency=TCNT2;

  //Reload the timer and correct for latency.  
  TCNT2=timerLatency+timerLoadValue; 
}

void StartTimer2(float timeoutFrequency)
{
  //Calculate the timer load value
  timerLoadValue=(int)((257.0-(TIMER_CLOCK_FREQ/timeoutFrequency))+0.5); //the 0.5 is for rounding;
  //The 257 really should be 256 but I get better results with 257, dont know why.

  //Timer2 Settings: Timer Prescaler /8, mode 0
  //Timmer clock = 16MHz/8 = 2Mhz or 0.5us
  //The /8 prescale gives us a good range to work with so we just hard code this for now.
  TCCR2A = 0;
  TCCR2B = 1<<CS22 | 0<<CS21 | 1<<CS20; 

  //Timer2 Overflow Interrupt Enable   
  TIMSK2 = 1<<TOIE2;

  //load the timer for its first cycle
  TCNT2=timerLoadValue; 
}

unsigned char StopTimer2()
{
    TCCR2B = 0;  // Stop the timer/counter 
}

void FlickerBrightness::StartAutoLoop(void)
{
  gleds = this;
  StartTimer2(4*8192);
}

void FlickerBrightness::StopAutoLoop(void)
{
  if (gleds == this)
    {
    gleds = 0;
    StopTimer2();
    }
}
  
void Ani::loop(void)
{
  erase();
  next();
  draw();
}

AniSweep::AniSweep(FlickerBrightness& pleds, char pstart, char pend, char pdelayTime,int pintensityChange):leds(pleds)
      {
        dir = (pend-pstart>0)? 1:-1;
        if (dir>0)
        {
        start=pstart;
        end=pend;
        }
        else
        {
          start = pend;
          end = pstart;
        }
        delayTime = pdelayTime;
        intensityChange = pintensityChange;
        cpos = pstart;
        lst = NULL;
      }
      
void AniSweep::erase(void)
{
    leds.brightness[cpos] -= intensityChange;
}

void AniSweep::draw(void)
{
    leds.brightness[cpos] += intensityChange;
}

void AniSweep::next(void)
{
  cpos += dir;

  if (cpos > end) { cpos -= (end-start)+1; }
  if (cpos < start) { cpos += (end-start)+1; }
    
  //Serial.println((int)cpos);
}

AniWiper::AniWiper(FlickerBrightness& pleds, char pstart, char nleds, char pdelayTime,int pintensityChange):leds(pleds)
      {
        start=pstart;
        end=pstart + nleds-1;
        delayTime = pdelayTime;
        intensityChange = pintensityChange;
        cpos = start;
        dir = 1;
        lst = NULL;
      }

void AniWiper::erase(void)
{
    leds.brightness[cpos] -= intensityChange;
}

void AniWiper::draw(void)
{
    leds.brightness[cpos] += intensityChange;
}

void AniWiper::next(void)
{
  cpos += dir;
  if (cpos >= end) { cpos = 2*end - cpos; dir *= -1; }
  if (cpos <= start) { cpos = 2*start -cpos; dir *= -1; }
  //Serial.println((int)cpos);
}

void AniDraw(Ani& pani)
  {
    Ani* ani = &pani;
    
    while(ani!=NULL)
      {
        ani->draw();
        ani = ani->lst;
      }
  }

void AniNext(Ani& pani)
  {
    Ani* ani = &pani;
    
    while(ani!=NULL)
      {
        ani->next();
        ani = ani->lst;
      }
  }

void AniLoop(Ani& pani)
  {
    Ani* ani = &pani;
    
    while(ani!=NULL)
      {
        ani->erase();
        ani->next();
        ani->draw();
        ani = ani->lst;
      }
  }

void AniErase(Ani& pani)
  {
    Ani* ani = &pani;
    
    while(ani!=NULL)
      {
        ani->erase();
        ani = ani->lst;
      }
  }

