// I use this project to test and develop the lightuino library itself.
// It is probably not that interesting to you unless you are hacking the library.

#include "./lightuino.h"
#include "avr/pgmspace.h"

/*
int myClockPin =         3; //5; //6;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPinLeft =   2; //6; //4; // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPinRight =  5; //7; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin =   10; //4;          // What Arduino pin goes to the brightness ping on the M5451s
*/

int myClockPin =     7; //6;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPinLeft =   6; //4; // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPinRight =  5; //7; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 4;          // What Arduino pin goes to the brightness ping on the M5451s


int myRowDriverClk = 8;
int myRowDriverData = 9;
int myRowDriverStrobe = 10;
int myRowDriverEnable = 11;

#define TOGGLE_IO 13
int ledPin = 13;  // The normal arduino example LED


// Most IRs differentiate a 1 vs a 0 by the length of a pulse.  In other words, a "1" may turn the IR LED "on" for twice as long as a "0".
// The IR LED is turned off to break up the bits.  This is not entirely intuitive where you might think that a 1 is the IR-LED being "on" and a 0 is it being "off".

// These constants define how long in microseconds a 1 is vs a 0.
// The variation is the fudge factor.  For example a variation of 2 means that the signal's length can vary by + or - 1/2 of the speced ideal time.
// For example given ZEROTIME of 600, and a VARIATION of 2, signals from 300-900 will be interpreted as a 0
#define ZEROTIME 600UL   // Actually 600
#define ONETIME  1200UL  // Actually 1200
#define VARIATION 2UL

// Some IR protocols indicate the start of a new code by a very long pulse.  STARTTIME specifies this.
// Its not strictly necessary to define this because the quiettime can also split up pulses, but getting this correct
// will allow the system to correctly interpret rapid signal.
#define STARTTIME 5000UL

// QUIETTIME speccs how long to wait with no pulses before deciding that the code is complete.
#define QUIETTIME 30000UL

// To determine the bits, should I measure the length of a pulse (1) or the length of the silence between pulses (0).  Typically its the length of a pulse.
// You can determine this by plotting the waveform and seeing whether the pulse or the silence varies (that's the SIGNAL_STATE).
// Each non-signal portion will essentially the same width (except perhaps for preambles and suffixes). 
#define SIGNAL_STATE 1
//#define SIGNAL_STATE 0

#define IRCODEBUFFER 4

class IrReceiver
  {
    public:
    static char pin;
    static unsigned long int zeroTimeMin;
    static unsigned long int zeroTimeMax;
    static unsigned long int oneTimeMin;
    static unsigned long int oneTimeMax;
    static unsigned long int startTime;
    static unsigned long int quietTime;
    static unsigned int      variation;
    static char signalState;
    static unsigned long int codes[IRCODEBUFFER];
    static char lastCode;
    
    IrReceiver(unsigned long int ZeroTime=ZEROTIME,unsigned long int OneTime=ONETIME,unsigned long int StartTime=STARTTIME,unsigned long int QuietTime=QUIETTIME,unsigned int Variation=VARIATION,char signalState=-1,char pin=2);
    unsigned long int getCode();
    
    void sleep();
    
    ~IrReceiver();
  };

IrReceiver::~IrReceiver()
{
  detachInterrupt(pin-2);
}


void IrReceiver::sleep()
{
}


// IR receiver globals
char IrReceiver::pin;
unsigned long int IrReceiver::zeroTimeMin;
unsigned long int IrReceiver::zeroTimeMax;
unsigned long int IrReceiver::oneTimeMin;
unsigned long int IrReceiver::oneTimeMax;
unsigned long int IrReceiver::startTime;
unsigned long int IrReceiver::quietTime;

char IrReceiver::signalState;
unsigned long int IrReceiver::codes[IRCODEBUFFER];
char IrReceiver::lastCode;
 

volatile boolean codeReady;
volatile unsigned long long int irCode=0;
volatile boolean lastState=0;
volatile unsigned long int lastTime=0;
volatile boolean p13state=0;

// Return the difference between now and some start time
unsigned long int delta(unsigned long int start, unsigned long int now)
{
  unsigned long int tmp = now-start;
  if (start < now) return tmp;
  else 
  {
    return 0xFFFFFFFFUL - tmp;
  }
}

unsigned long int IrReceiver::getCode()
{
  unsigned long int ret=0;

  cli();
  unsigned long int interval = delta(lastTime, micros());
  if (interval>IrReceiver::quietTime)
    {
      ret = irCode;
      irCode = 0;
    }
  sei();
  return ret;
}


ISR( irHandler )
{
  // When are we?
  unsigned long int now = micros();
  // What are we now?
  boolean state;
  boolean check=true;
 
  if (IrReceiver::signalState != -1) 
    {
      state = digitalRead(2);
      // If its not the signal state now, then it WAS signal before this interrupt fired
      // and that's the interval we are interested in.
      if (state == IrReceiver::signalState) check = false;
    }
  
  if (check)
    {
    // How long since last time?
    unsigned long int interval = delta(lastTime, now);  
    
    // Did we get a "HEY WAKE UP!!!" signal?
    if (interval > IrReceiver::startTime)
    {
      digitalWrite(13,p13state);
      p13state=!p13state;
      irCode = 0;
    }
    
    // If we are within the range for a zero then shift a 0 in. 
    if ((interval >= IrReceiver::zeroTimeMin)&&(interval <=IrReceiver::zeroTimeMax))
    {
    irCode *=2;
    }
    // Or if we are within the range for a 1 then shift in a one.
    else if ((interval >= IrReceiver::oneTimeMin)&&(interval <= IrReceiver::oneTimeMax))
    {
    irCode *=2;
    irCode |=1;
    }
    // Otherwise I don't know what!    
    }
    
  // Remember when we were woken up for the next time.   
  lastTime = now;
}


IrReceiver::IrReceiver(unsigned long int ZeroTime,unsigned long int OneTime,unsigned long int StartTime,unsigned long int QuietTime,unsigned int Variation,char SignalState,char Pin)
  {
    zeroTimeMin=ZeroTime-(ZeroTime/Variation); zeroTimeMax = ZeroTime+(ZeroTime/Variation);
    oneTimeMin=OneTime-(OneTime/Variation); oneTimeMax = OneTime+(OneTime/Variation);
    
    startTime=StartTime; quietTime=QuietTime; signalState=SignalState;
    pin = Pin;
    attachInterrupt(pin-2,irHandler,CHANGE);
  }




class Ams302LightSensor
  {
    public:
    char pin;
    enum {
      DirectSunlight = 150,
      BrightLight = 250,
      IndoorLight = 550,
      Dusk = 850,
      Dark = 1000
    };
    Ams302LightSensor(char panaPin=7):pin(panaPin) {}
    
    int read(void) { return analogRead(pin); };    
  };
  
#define Lightuino_NUMSRCDRVR  16

class Mic5891Pair
  {
    public:
    Mic5891Pair(unsigned char clkPin, unsigned char dataPin, unsigned char strobePin, unsigned char enaPin);

    unsigned char clkPin;
    unsigned char dataPin;
    unsigned char strobePin;
    unsigned char enaPin; 
  
    void set(unsigned int bitMap);
    void shift(unsigned char bit);
    void off(void);
  };


Mic5891Pair::Mic5891Pair(unsigned char pclkPin, unsigned char pdataPin, unsigned char pstrobePin, unsigned char penaPin)
{
  clkPin    = pclkPin;  
  dataPin   = pdataPin;  
  strobePin =  pstrobePin,  
  enaPin    = penaPin; 

  pinMode(clkPin, OUTPUT);      // sets the digital pin as output
  pinMode(dataPin, OUTPUT);     // sets the digital pin as output
  pinMode(strobePin, OUTPUT);   // sets the digital pin as output
  pinMode(enaPin, OUTPUT);      // sets the digital pin as output

  digitalWrite(strobePin,HIGH);
}

void Mic5891Pair::set(unsigned int bits)
{
  bits = reverse(bits);
  digitalWrite(clkPin, LOW);
  digitalWrite(strobePin,LOW);
  for (char i=0;i<16;i++,bits>>=1)
    {
      digitalWrite(dataPin, bits&1);
      digitalWrite(clkPin, HIGH);
      digitalWrite(clkPin, LOW);      
    }

  digitalWrite(enaPin,HIGH);    // OFF
  digitalWrite(strobePin,HIGH);
  digitalWrite(enaPin,LOW);    // ON
}

void Mic5891Pair::off()
{
  digitalWrite(enaPin,HIGH);    // OFF
}

void Mic5891Pair::shift(unsigned char bit)
{
  digitalWrite(clkPin, LOW);
  digitalWrite(strobePin,LOW);

  digitalWrite(dataPin, bit&1);
  digitalWrite(clkPin, HIGH);
  digitalWrite(clkPin, LOW);      

  digitalWrite(enaPin,HIGH);    // OFF
  digitalWrite(strobePin,HIGH);
  digitalWrite(enaPin,LOW);    // ON
}

unsigned char letters[][7] = { 
  
  {  0xe,0x11,0x11,0x1f,0x11,0x11,0x11 },
{  0xf,0x11,0x11,0xf,0x11,0x11,0xf },
{  0xe,0x11,0x1,0x1,0x1,0x11,0xe },
{  0x7,0x9,0x11,0x11,0x11,0x9,0x7 },
{  0x1f,0x1,0x1,0xf,0x1,0x1,0x1f },
{  0x1f,0x1,0x1,0xf,0x1,0x1,0x1 },
{  0xe,0x11,0x1,0x1d,0x11,0x11,0xe },
{  0x11,0x11,0x11,0x1f,0x11,0x11,0x11 },
{  0xe,0x4,0x4,0x4,0x4,0x4,0xe },
{  0x10,0x10,0x10,0x10,0x11,0x11,0xe },
{  0x11,0x9,0x5,0x3,0x5,0x9,0x11 },
{  0x1,0x1,0x1,0x1,0x1,0x1,0x1f },
{  0x11,0x1b,0x15,0x11,0x11,0x11,0x11 },
{  0x11,0x11,0x13,0x15,0x19,0x11,0x11 },
{  0xe,0x11,0x11,0x11,0x11,0x11,0xe },
{  0xf,0x11,0x11,0xf,0x1,0x1,0x1 },
{  0xe,0x11,0x11,0x11,0x15,0x9,0x16 },
{  0xf,0x11,0x11,0xf,0x5,0x9,0x11 },
{  0x1e,0x1,0x1,0xe,0x10,0x10,0xf },
{  0x1f,0x4,0x4,0x4,0x4,0x4,0x4 },
{  0x11,0x11,0x11,0x11,0x11,0x11,0xe },
{  0x11,0x11,0x11,0x11,0x11,0xa,0x4 },
{  0x11,0x11,0x11,0x11,0x15,0x1b,0x11 },
{  0x11,0x11,0xa,0x4,0xa,0x11,0x11 },
{  0x11,0x11,0xa,0x4,0x4,0x4,0x4 },
{  0x1f,0x10,0x8,0x4,0x2,0x1,0x1f },
{  0xe,0x11,0x19,0x15,0x13,0x11,0xe },
{  0x8,0xc,0xa,0x8,0x8,0x8,0x8 },
{  0xf,0x10,0x10,0xe,0x1,0x1,0x1f },
{  0x1f,0x4,0x4,0xe,0x10,0x11,0xe },
{  0x8,0xc,0xa,0x1f,0x8,0x8,0x8 },
{  0x1f,0x1,0x1,0xe,0x10,0x10,0xf },
{  0xe,0x1,0x1,0xf,0x11,0x11,0xe },
{  0x1f,0x10,0x8,0x4,0x2,0x2,0x2 },
{  0xe,0x11,0x11,0xe,0x11,0x11,0xe },
{  0xe,0x11,0x11,0x1e,0x10,0x10,0xe },
{  0x1f,0x11,0x11,0x11,0x11,0x11,0x1f },
{  0x10,0x10,0x10,0x10,0x10,0x10,0x10 },
{  0x1f,0x10,0x10,0x1f,0x1,0x1,0x1f },
{  0x1f,0x10,0x10,0x1f,0x10,0x10,0x1f },
{  0x11,0x11,0x11,0x1f,0x10,0x10,0x10 },
{  0x1f,0x1,0x1,0x1f,0x10,0x10,0x1f },
{  0x1f,0x1,0x1,0x1f,0x11,0x11,0x1f },
{  0x1f,0x10,0x10,0x10,0x10,0x10,0x10 },
{  0x1f,0x11,0x11,0x1f,0x11,0x11,0x1f },
{  0x1f,0x11,0x11,0x1f,0x10,0x10,0x1f },
  
};


typedef enum 
{
  DRAW,
  ERASE,
  DRAW_BLACK_ON_WHITE,
  XOR
} GraphicOperation;

class LightuinoMatrix
{
  public:
  unsigned char videoRam[Lightuino_NUMSRCDRVR*((Lightuino_NUMOUTS/8)+1)];
  Lightuino&   sink;
  Mic5891Pair& src;
  unsigned char curRow;
  unsigned char numRows;
  unsigned char startRow;
  LightuinoMatrix(Lightuino& lht, Mic5891Pair& srcDrvr,unsigned char pstartRow=0,unsigned char numRows=16);
  
  void loop(unsigned char amt=1);
  void pixel(unsigned char x,unsigned char y,unsigned char val);

  void print(int x, int y,const char* s,unsigned char spacing=1,GraphicOperation g=DRAW);

};



void LightuinoMatrix::print(int x, int y,const char* s,unsigned char spacing, GraphicOperation op)
  {
    //Serial.println("print");
    if (y>=Lightuino_NUMSRCDRVR) return; // Too far down
    
    while((*s)&&(x<Lightuino_NUMOUTS))
      {
        if ((*s >= 'A') && (*s <= 'Z') &&(x>=0))
          {
        int offset = (y*((Lightuino_NUMOUTS/8)+1)) + (x>>3);
        int shift  = x&7;
    //int split = (shift+5)-8;
        
        int charOff = offset;
        char whichLetter = (*s)-'A';

        //Serial.print(*s);
        //Serial.print(" ");
        //Serial.println((int)whichLetter);
        
        unsigned int mask;
        mask = 0b11111 << shift;
        //mask[1] = 0b11111 >> split;
        for (unsigned char i=0;(i<7)&&(y+i<Lightuino_NUMSRCDRVR);i++)
          {
          //Serial.println((int)(*((unsigned char*)(((unsigned char*)letters)+(whichLetter*7)+i))),BIN);
          //Serial.println((int)(letters[whichLetter][i]),BIN);
          if (op==DRAW)
            {
            *((unsigned int*)&videoRam[charOff]) &= ~mask;          
            *((unsigned int*)&videoRam[charOff]) |= (letters[whichLetter][i] << shift);
          //videoRam[charOff+1] |= letters[whichLetter][i] >> split;
            }
          else if (op==ERASE)
            {
            *((unsigned int*)&videoRam[charOff]) &= ~mask;              
            }
          else if (op==XOR)
            {
            *((unsigned int*)&videoRam[charOff]) ^= (letters[whichLetter][i] << shift);               
            }  
          else if (op==DRAW_BLACK_ON_WHITE)
            {
            *((unsigned int*)&videoRam[charOff]) &= ~mask;          
            *((unsigned int*)&videoRam[charOff]) |= ((~letters[whichLetter][i]&0b11111) << shift);

            }  
          charOff += ((Lightuino_NUMOUTS/8)+1);
            
          }
        //Serial.println("");
          }
        s++;
        x+=5 + spacing;
      }
  }


void LightuinoMatrix::pixel(unsigned char x,unsigned char y,unsigned char val)
    {
      int offset = (y*((Lightuino_NUMOUTS/8)+1)) + (x>>3);
      
      if (val)
      videoRam[offset] |= (1 << (x&7));
        //videoRam[y][x>>3] |= (1 << (x&7));
      else
        videoRam[offset] &= ~(1 << (x&7));
        //videoRam[y][x>>3] &= ~(1 << (x&7)); 
    }
 
LightuinoMatrix::LightuinoMatrix(Lightuino& lht, Mic5891Pair& srcDrvr,unsigned char pstartRow,unsigned char pnumRows):sink(lht),src(srcDrvr)
{
  startRow = pstartRow;
  numRows = pnumRows;
  memset(&videoRam,0,((Lightuino_NUMOUTS/8)+1)*Lightuino_NUMSRCDRVR);
  curRow = numRows+startRow;
}

void LightuinoMatrix::loop(unsigned char amt)
  {
    //unsigned char line[((Lightuino_NUMOUTS/8)+1)];
    unsigned char cnt = amt;
    while(cnt>0)
      {
        cnt--;
        curRow++;
        if (curRow >= startRow+numRows) 
          {
            curRow=startRow;
          }
        sink.set(videoRam + (curRow*((Lightuino_NUMOUTS/8)+1)));       
        src.off();
        sink.finish();
        if (curRow ==startRow) 
          {
            //src.shift(1);
            src.set(1<<startRow);
          }
        else src.shift(0);
        //memcpy(line,videoRam[curRow],((Lightuino_NUMOUTS/8)+1));
        //memset(line,0,((Lightuino_NUMOUTS/8)+1));
        //sink.set(line);
      }
  }



/* Do a delay, but also wait for user input if a global var is set */
char waitInput=false;
void mydelay(int amt)
{
  char incomingByte =0;
  delay(amt);
  if (waitInput)
    {
    while (Serial.available() == 0) delay(10);    
    incomingByte = Serial.read();
    }
  else
  {
    if (Serial.available())
      incomingByte = Serial.read();
  }
  if (incomingByte == 's')
    {
      Serial.println("stop");
      waitInput=true;
    }
  else if (incomingByte == 'c')
    {
      Serial.println("continue");
      waitInput=false;
    }

}

int serialGetNum(char*extra)
{
  char in;
  int val = 0;
  *extra=0;
  while(1)
    {
      in = Serial.read();
      //Serial.println(in);
      if (in=='.') { *extra |=2; break; }
      else if ((in>='0')&&(in<='9')) { val= (val*10)+ (in-'0'); *extra|=1;}
      else break;
    }
  return val;
}

void setup()
{
    //Start up the serial port
  Serial.begin(9600);
  //Start the timer and get the timer reload value.
  //timerLoadValue=SetupTimer2(4*8192); //1000); //44100);  
  //Signal the program start
  Serial.println("Lightuino library development test v3.0");
}

void RunThru(Lightuino& out)
{
  int i;
  //unsigned long int val;
  for (i=0;i<70;i++)
  {
    Serial.print(i);
    Serial.print(" ");
    if (i<32)
      out.set(1UL<<i,0,0);
    else if (i<64)
      out.set(0,1UL<<(i-32),0);
    else out.set(0,0,1UL<<(i-64));
    mydelay(50); 
  }  
}

void RollChaser(Lightuino& out)
{
  int i;
  //unsigned long int val;
  for (i=0;i<32;i++)
  {
    out.fastSetBy32(1UL<<i,1UL<<i,0);
    mydelay(500); 
  }  
}

void RollChaserOpposing(Lightuino& out)
{
  int i;
  for (i=0;i<32;i++)
  {
    out.fastSetBy32(1UL<<i,1UL<<(32-i),0);
    mydelay(50);    
  }  
}

void BrightChaser(Lightuino& board)
{
  int i;
  int j;
  int k;
  int repeats;
  FlickerBrightness leds(board);
}

void TestTimer(Lightuino& board)
{
  int i;
  int j;
  int k;
  int repeats;
  Lightuino board2(2,4,8, 10);   
  
  FlickerBrightness leds(board);
  FlickerBrightness leds2(board2);
  leds.next = &leds2;
  
  //gleds = &leds;
  leds.StartAutoLoop();
  
  for (j=0;j<2;j++)
  {
  for (i=0;i<70;i++)
  {
    leds.brightness[i] = 100+(i*2);
    leds2.brightness[i] = 100+(i*2);
    delay(50);
  }
  
  mydelay(500); 
  for (i=0;i<70;i++)
  {
    leds.brightness[i] = 0;
    leds2.brightness[i] = 0;
    delay(10);
  }
  
  #if 0
  for (k=0;k<2000;k++)
  {
  for (i=0;i<32;i++)
  {
    //leds.brightness[i] =  0;
    leds.brightness[i+1] = i* (Lightuino_MAX_BRIGHTNESS/10); 
    leds2.brightness[i+1] = i* (Lightuino_MAX_BRIGHTNESS/10); 
    mydelay(50);
  }
  }
  #endif
  }

  leds.StopAutoLoop();  
  mydelay(100);
}

void FlickerRoll(FlickerBrightness& flk)
{
  int i;
  for (i=0;i<70;i++)
  {
    flk.brightness[i] = 200;
    mydelay(100);
    flk.brightness[i] = 0;
  }
}

void TestByteSet(Lightuino& board)
{
    for (int i=0;i<30;i++)
    {
    Serial.println("Turn on every other LED");
    
    // Each bit (1 or 0) in this array corresponds to one LED light
    byte ledState[9] = {B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010};
     
    // Now send it to the chips.
    board.set(ledState);  
      
    delay(250);
  
    Serial.println("Now put in the opposite pattern");
    // Now set up another pattern
    for (int j=0;j<9;j++) ledState[j] = B01010101;
    
    // Now send it to the chips.
    board.set(ledState);  
      
    delay(250);
    }

}

void allOn(Lightuino& board)
{
  for (int i=0;i<3;i++)
    {
    Serial.println("Turn on ALL LEDs");
    // Each bit (1 or 0) in this array corresponds to one LED light
    byte ledState[9] = {B11111111,B11111111,B11111111,B11111111,B11111111,B11111111,B11111111,B11111111,B11111111};
     
    // Now send it to the chips.
    board.set(ledState);  
      
    delay(1000);
    }
}

void drvrTest(Mic5891Pair& drvr)
{
  if(0) for (int i=0;i<100;i++)
    {
      drvr.set(0x5555);
      delay(250);
      drvr.set(0xaaaa);
      delay(250);
    }

  drvr.set(0x0000);
  for (int i=0;i<100;i++)
    {
      delay(100);
      drvr.shift(((i&7)==0));
    }

}

void testLightSensor(void)
{
Ams302LightSensor light;

Serial.println("Light sensor readings");
for (int i=0;i<500;i++)
  {
    int val = light.read();
    Serial.println(val);
    delay(500);
  }

}

void testIr()
{
  IrReceiver ir;
    Serial.println("Waiting for input from your remote");
  for (int i=0;i<100;)
  {
    unsigned long int code = ir.getCode();
  if (code)
  {
    Serial.print("code: ");
    Serial.print((unsigned long int)(code>>32),HEX);
    Serial.print(" ");
    Serial.print((unsigned long int)(code),HEX);
    Serial.print(" | ");
    Serial.print((unsigned long int)(code>>32),BIN);
    Serial.print(" ");
    Serial.println((unsigned long int)(code),BIN);
    i++;
  }
  else delay(10);
      
  }
}

#define perfIters 10000
#define perfFlickIters 20000
void perfTest(Lightuino& lht)
{
  int i;
  Serial.println("Perf Tests");

  unsigned long long int duration;
  unsigned long int a[3];
  a[0]=0x55555555;
  a[1]=0xAAAAAAAA;
  a[2]=0xff;
  duration = micros();
  for (i=0;i<perfIters;i++)
    {
    unsigned long int b[3];
    b[0] = a[0]; b[1] = a[1]; b[2] = a[2];
    lht.fastSet(b);   
    a[0]++;
    a[1]++;
    }
  duration = micros() - duration;
  
  Serial.print("fastSet time in uSec: ");
  Serial.print((unsigned long int)(duration/perfIters));
  Serial.print(" fastSet frames per second: ");
  Serial.print((unsigned long int) ((1000000ULL * perfIters)/duration));
  Serial.println("");
  
  
  
  FlickerBrightness flk(lht);
  flk.minBrightness = 0;
  //for (i=0;i<70;i++) flk.brightness[i] = 1+(i*(Lightuino_MAX_BRIGHTNESS/70));
  //for (i=0;i<70;i++) flk.brightness[i] = (1+(i*(Lightuino_MAX_BRIGHTNESS/10)))%Lightuino_MAX_BRIGHTNESS;
  for (i=0;i<70;i++) flk.brightness[i] = i;
  duration = micros();
  for (i=0;i<perfFlickIters;i++)
    flk.loop();   
  duration = micros() - duration;
  
  Serial.print("PWM loop time in uSec: ");
  Serial.print((unsigned long int)duration/perfIters);
  Serial.print(" PWM frames per second: ");
  Serial.print((unsigned long int)((1000000ULL * perfFlickIters)/duration));
  Serial.println("");
    
}


void testMatrix(Lightuino& sink,Mic5891Pair& src)
{
  LightuinoMatrix mtx(sink,src,0,16);
  sink.finishReq=true;
  //memset(mtx.videoRam,0xff,((Lightuino_NUMOUTS/8)+1)*Lightuino_NUMSRCDRVR);
  //for (int i=0;i<5000;i++)
  char x=0;
  char y=0;
  
  //mtx.videoRam[0][0] = 0xff;
  //mtx.pixel(10,5,1);
  unsigned int cnt = 0;

  while(1)
    {
      cnt++;  
      //if ((cnt & 511)==0) memset(mtx.videoRam,0xff,((Lightuino_NUMOUTS/8)+1)*Lightuino_NUMSRCDRVR);
  
      //memset(mtx.videoRam,cnt&0xFF,((Lightuino_NUMOUTS/8)+1)*Lightuino_NUMSRCDRVR);
      mtx.print(35+25 - (cnt%300),0,"SALE TOILET PAPER LIGHTLY USED   REROLLED",1,DRAW);
      for (int j=0;j<400;j++) { mtx.loop();}
      mtx.print(35+25 - (cnt%300),0,"SALE TOILET PAPER LIGHTLY USED   REROLLED",1,ERASE);

      //x++;
      //if (x>=35+25) {x=35; y++; if (y>=7) y=0; }
      //mtx.pixel(x,y,1);    
      //#endif
    }
  
  
  
}

void loop()
{
  Lightuino out(myClockPin,mySerDataPinLeft,mySerDataPinRight, myBrightnessPin);
  out.flags |= Lightuino_FASTSET;  // fast set relies on AVR registers not digitalWrite, so may not work on some Arduino variants.
  //out.flags &= ~Lightuino_FASTSET;
  //out.flags |= Lightuino_BY32;


  while (0) perfTest(out);

  Mic5891Pair drvr(myRowDriverClk,myRowDriverData,myRowDriverStrobe,myRowDriverEnable);

  if (0) testMatrix(out,drvr);
   
  if (1)
    {
      testIr();

      testLightSensor();
    }

  if (0)
    {
      drvr.set(0xFFFF);
    }

  if (1)
    {
      out.set(0xffffffffULL,0xffffffffULL,0xff);
      drvrTest(drvr);
    }


  if (1)
    {
      Serial.println("All ON");
      allOn(out);
    }

  if (1)
    {
      Serial.println("TestByteSet");
      TestByteSet(out);
    }

  if (1)
    {
      Serial.println("RunThru");
      RunThru(out);
    }


  if (1)
    {
      Serial.println("Flicker Tests");
      FlickerBrightness flk(out);
      for (int i=0;i<70;i++) flk.brightness[i] = 0;
      flk.StartAutoLoop();
     
      Serial.println("Verify alignment");
      flk.brightness[0] = 200;
      flk.brightness[31] = 200;
      mydelay(5000);
     
      Serial.println("Flicker Tests By 32");
      FlickerRoll(flk);
      out.flags |= Lightuino_BY32;
      FlickerRoll(flk);
     
      out.flags &= ~Lightuino_BY32;     
    }
     
     
     
  Serial.println("RollChaser");
  RollChaser(out);
  Serial.println("Opposite RollChaser");
  RollChaserOpposing(out); 

  if (1)
    {
      Serial.println("TimerTest");
      TestTimer(out);
    }  


}
