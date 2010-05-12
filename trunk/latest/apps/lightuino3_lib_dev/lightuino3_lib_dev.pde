// I use this project to test and develop the lightuino library itself.
// It is probably not that interesting to you unless you are hacking the library.

#include "lightuino3.h"

//#include "avr/pgmspace.h"

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


/* Do a delay, but also wait for user input if a global var is set */
char waitInput=false;
float  spd=1.0;
void mydelay(int amt)
{
  unsigned long int code = 0;  
  char incomingByte =0;
  IrReceiver ir;
  if (spd != 1.0) amt = ((float)amt)*spd;
  if (amt>0) delay(amt);
  if (waitInput)
    {
    while ((Serial.available() == 0)&&((code=ir.read())==0)) delay(10);    
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


  do
    {
    
    if (code == 0x8880222A) // play
      {
      Serial.println("remote cmd: continue");
      spd = 1.0;
      waitInput=false;        
      }
    if (code == 0x880A22A) // stop
     {
     Serial.println("remote cmd: stop");
     waitInput=true;      
     }
    if (code == 0xA0800A2A) // ffwd
     {
       Serial.println("remote cmd: go faster");
       spd -=.1;
     }
    if (code == 0x8280282A) // rev
     {
       Serial.println("remote cmd: go slower");
       spd += .1;
     }
    code = ir.read();
    } while(code);

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
    mydelay(50);
  }
  
  mydelay(500); 
  for (i=0;i<70;i++)
  {
    leds.brightness[i] = 0;
    leds2.brightness[i] = 0;
    mydelay(10);
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
      
    mydelay(250);
  
    Serial.println("Now put in the opposite pattern");
    // Now set up another pattern
    for (int j=0;j<9;j++) ledState[j] = B01010101;
    
    // Now send it to the chips.
    board.set(ledState);  
      
    mydelay(250);
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
      
    mydelay(1000);
    }
}

// Source Driver Test
void sourceDriverTest(Mic5891& drvr)
{
  Serial.println("Source Driver Test");
  
  Serial.println("Driving alternating patterns");
  if(1) for (int i=0;i<100;i++)
    {
      drvr.set(0x5555);
      mydelay(250);
      drvr.set(0xaaaa);
      mydelay(250);
    }

  Serial.println("Shifting 1 set bit (per 8 bits) through the chips.");
  drvr.set(0x0000);
  for (int i=0;i<100;i++)
    {
      mydelay(100);
      drvr.shift(((i&7)==0));
    }

}

void testLightSensor(void)
{
LightSensor light;

Serial.println("Light sensor readings.");

Serial.println("Current");
int curval = light.read();
Serial.println(curval);

Serial.println("Cover the sensor");
int val;
int cnt = 0;
do
  {
    val = light.read();
    Serial.println(val);
    mydelay(500);
    cnt++;
  } while (cnt<50 && val<LightSensor::Dusk);
if (cnt>=50) Serial.println("Aborting test (timeout)...");
  
cnt=0;
Serial.println("Shine a light on the sensor");
do
  {
    val = light.read();
    Serial.println(val);
    mydelay(500);
    cnt++;
  } while ((cnt<50) && (val>LightSensor::BrightLight));
if (cnt>=50) Serial.println("Aborting test (timeout)..."); 
}

void testIr()
{
  IrReceiver ir;
    Serial.println("Waiting for input from your infrared remote");
  for (int i=0;i<50;)
  {
    unsigned long int code = ir.read();
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
    if (code == 0x20808A2A) 
      {
        Serial.println("Power button hit; test is complete");
        i=50;
        break;
      }
  }
  else delay(1);
      
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


void testMatrix(Lightuino& sink,Mic5891& src)
{
  LightuinoMatrix mtx(sink,src,0,16);
  //sink.finishReq=true;
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

  Mic5891 drvr(myRowDriverClk,myRowDriverData,myRowDriverStrobe,myRowDriverEnable);

  if (0) testMatrix(out,drvr);
   
  if (1) testIr();

  if (1) testLightSensor();
    

  if (0)  // Turn all the source drivers on for testing
    {
      drvr.set(0xFFFF);
    }

  if (1)
    {
      // Turn all drains on during the source driver test in case we are hooked to a matrix.
      out.set(0xffffffffULL,0xffffffffULL,0xff);
      sourceDriverTest(drvr);
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
