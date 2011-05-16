// I use this project to test and develop the lightuino library itself.
// It is probably not that interesting to you unless you are hacking the library.

#include "lightuino5.h"

#include "avr/pgmspace.h"


int myClockPin =       Lightuino_CLOCK_PIN;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPinLeft =   Lightuino_SER_DATA_LEFT_PIN;            // Arduino pin that goes to data on one M5451 chip
int mySerDataPinRight =  Lightuino_SER_DATA_RIGHT_PIN;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = Lightuino_BRIGHTNESS_PIN;          // What Arduino pin goes to the brightness ping on the M5451s

int myRowDriverClk = Lightuino_SRC_CLOCK_PIN;
int myRowDriverData = Lightuino_SRC_DATA_PIN;
int myRowDriverStrobe = Lightuino_SRC_STROBE_PIN;
int myRowDriverEnable = Lightuino_SRC_ENABLE_PIN;

#define TOGGLE_IO 13
int ledPin = 13;  // The normal arduino example LED


void println(char*s)
{
  Serial.println(s);
  Usb.println(s);
}

void print(char*s)
{
  Serial.print(s);
  Usb.print(s);
}
void print(int i,char format=DEC)
{
  Serial.print(i,format);
  Usb.print(i,format);
}

void println(int i,char format=DEC)
{
  Serial.println(i,format);
  Usb.println(i,format);
}


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
      println("stop");
      waitInput=true;
    }
  else if (incomingByte == 'c')
    {
      println("continue");
      waitInput=false;
    }

  do
    {   
    if (code == 0x8880222A) // play
      {
      println("remote cmd: continue");
      spd = 1.0;
      waitInput=false;        
      }
    if (code == 0x880A22A) // stop
     {
     println("remote cmd: stop");
     waitInput=true;      
     }
    if (code == 0xA0800A2A) // ffwd
     {
       println("remote cmd: go faster");
       spd -=.1;
     }
    if (code == 0x8280282A) // rev
     {
       println("remote cmd: go slower");
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
      //println(in);
      if (in=='.') { *extra |=2; break; }
      else if ((in>='0')&&(in<='9')) { val= (val*10)+ (in-'0'); *extra|=1;}
      else break;
    }
  return val;
}

void setup()
{
  Usb.begin();
    //Start up the serial port
  Serial.begin(9600);
  //Start the timer and get the timer reload value.
  //timerLoadValue=SetupTimer2(4*8192); //1000); //44100);  
  //Signal the program start
  println("Lightuino library development test v3.0");
}

void RunThru(Lightuino& out)
{
  int i;
  //unsigned long int val;
  for (i=0;i<70;i++)
  {
    print(i);
    print(" ");
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
    println("Turn on every other LED");
    
    // Each bit (1 or 0) in this array corresponds to one LED light
    byte ledState[9] = {B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010};
     
    // Now send it to the chips.
    board.set(ledState);  
      
    mydelay(250);
  
    println("Now put in the opposite pattern");
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
    println("Turn on ALL LEDs");
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
  println("Source Driver Test");
  println("  Driving alternating patterns");
  if(1) for (int i=0;i<10;i++)
    {
      println("  5");
      drvr.set(0x5555);
      mydelay(250);
      
      
      println("  a");
      drvr.set(0xaaaa);
      mydelay(250);
    }

  println("  Shifting 1 set bit (per 16 bits) through the chips.");
  drvr.set(0x0000);
  for (int i=0;i<100;i++)
    {
      mydelay(250);
      drvr.shift(((i&15)==0));
    }
    
  drvr.set(0);  // All done, so turn them all off  

}

void testLightSensor(void)
{
LightSensor light;

println("Light sensor readings.");

println("Current");
int curval = light.read();
println(curval);

println("Cover the sensor");
int val;
int cnt = 0;
do
  {
    val = light.read();
    println(val);
    mydelay(500);
    cnt++;
  } while (cnt<50 && val<LightSensor::Dusk);
if (cnt>=50) println("Aborting test (timeout)...");
  
cnt=0;
println("Shine a light on the sensor");
do
  {
    val = light.read();
    println(val);
    mydelay(500);
    cnt++;
  } while ((cnt<50) && (val>LightSensor::BrightLight));
if (cnt>=50) println("Aborting test (timeout)..."); 
}

void testIr()
{
  IrReceiver ir;
    println("Waiting for input from your infrared remote");
  for (int i=0;i<50;)
  {
    unsigned long int code = ir.read();
  if (code)
  {
    print("code: ");
    print((unsigned long int)(code>>32),HEX);
    print(" ");
    print((unsigned long int)(code),HEX);
    print(" | ");
    print((unsigned long int)(code>>32),BIN);
    print(" ");
    println((unsigned long int)(code),BIN);
    i++;
    if (code == 0x20808A2A) 
      {
        println("Power button hit; test is complete");
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
  println("Perf Tests");

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
  
  print("fastSet time in uSec: ");
  print((unsigned long int)(duration/perfIters));
  print(" fastSet frames per second: ");
  print((unsigned long int) ((1000000ULL * perfIters)/duration));
  println("");
  
  
  
  FlickerBrightness flk(lht);
  flk.minBrightness = 0;
  //for (i=0;i<70;i++) flk.brightness[i] = 1+(i*(Lightuino_MAX_BRIGHTNESS/70));
  //for (i=0;i<70;i++) flk.brightness[i] = (1+(i*(Lightuino_MAX_BRIGHTNESS/10)))%Lightuino_MAX_BRIGHTNESS;
  for (i=0;i<70;i++) flk.brightness[i] = i;
  duration = micros();
  for (i=0;i<perfFlickIters;i++)
    flk.loop();   
  duration = micros() - duration;
  
  print("PWM loop time in uSec: ");
  print((unsigned long int)duration/perfIters);
  print(" PWM frames per second: ");
  print((unsigned long int)((1000000ULL * perfFlickIters)/duration));
  println("");
    
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

const prog_char flashPrintTest[] PROGMEM = {"This is stored in flash"};
PROGMEM const char flashPrintTest1[] = {"flash2"};

/* DOES NOT WORK const char* flashPrintTest2 PROGMEM = "flash3"; */

void loop()
{
  Lightuino out(myClockPin,mySerDataPinLeft,mySerDataPinRight, myBrightnessPin);
  out.flags |= Lightuino_FASTSET;  // fast set relies on AVR registers not digitalWrite, so may not work on some Arduino variants.
  //out.flags &= ~Lightuino_FASTSET;
  //out.flags |= Lightuino_BY32;
  out.setBrightness(255);

  while (0) perfTest(out);

  Mic5891 drvr(myRowDriverClk,myRowDriverData,myRowDriverStrobe,myRowDriverEnable);

  if (0) testMatrix(out,drvr);
   
  if (0) testIr();

  if (0) testLightSensor();

  while(0)
  {
    Usb.println("USB TEST 1");
    println("USB TEST 1");
    //fifoPush(&usb.spiRcv,'a');
    while (Usb.available())
      {
        char c[2];
        c[1] = 0;
        c[0] = Usb.read();
        //Usb.print(c);
        print(c);
      }
    delay(1000);
  }
  Usb.print("Zero test: ");
  Usb.println((unsigned long int)0);
  Usb.print("Flash print test: ");
  Usb.pgm_println(flashPrintTest);
  Usb.pgm_println(flashPrintTest1);
  //Usb.pgm_println(flashPrintTest2);

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
      println("All ON");
      allOn(out);
    }

  Usb.println("USB TEST 2");
  if (1)
    {
      println("TestByteSet");
      TestByteSet(out);
    }

  Usb.println("USB TEST 3");
  if (1)
    {
      println("RunThru");
      RunThru(out);
    }


  Usb.println("USB TEST 4");
  if (1)
    {
      println("Flicker Tests");
      FlickerBrightness flk(out);
      for (int i=0;i<70;i++) flk.brightness[i] = 0;
      flk.StartAutoLoop();
     
      println("Verify alignment");
      flk.brightness[0] = 200;
      flk.brightness[31] = 200;
      mydelay(5000);
     
      println("Flicker Tests By 32");
      FlickerRoll(flk);
      out.flags |= Lightuino_BY32;
      FlickerRoll(flk);
     
      out.flags &= ~Lightuino_BY32;     
    }
     
     
     
  println("RollChaser");
  RollChaser(out);
  println("Opposite RollChaser");
  RollChaserOpposing(out); 

  if (1)
    {
      println("TimerTest");
      TestTimer(out);
    }  
}
