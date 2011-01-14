
// Include the header appropriate to you version of the Lightuino.
// If you are using 2 boards, include both versions, highest first.
#include <lightuino5.h>

#include "avr/pgmspace.h"

int ledPin = 13;  // The normal arduino example LED


// Note, you don't have to do this anymore, since the default pin assignments
// are set up by including the appropriate lightuino<version>.h file.
// But this sketch demonstrates what you would do if you moved the default
// pin assignments.
#ifdef LIGHTUINO5
int myClockPin        =   Lightuino_CLOCK_PIN;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPinLeft  =   Lightuino_SER_DATA_LEFT_PIN;        // Arduino pin that goes to data on one M5451 chip
int mySerDataPinRight =   Lightuino_SER_DATA_RIGHT_PIN;       // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin   =   Lightuino_BRIGHTNESS_PIN;           // What Arduino pin goes to the brightness ping on the M5451s

#elif LIGHTUINO4
int myClockPin =         7;           // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPinLeft =   6;       // Arduino pin that goes to data on one M5451 chip
int mySerDataPinRight =  4;       // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin =    5;          // What Arduino pin goes to the brightness ping on the M5451s

#elif LIGHTUINO3
/* Lightuino V3 default settings */
int myClockPin =     7;           // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPinLeft =   6;       // Arduino pin that goes to data on one M5451 chip
int mySerDataPinRight =  5;       // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 3;          // What Arduino pin goes to the brightness ping on the M5451s
#else
/* Lightuino V2 default settings */
int myClockPin =     6;           // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPinLeft =   5;       // Arduino pin that goes to data on one M5451 chip
int mySerDataPinRight =  7;       // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 10;         // What Arduino pin goes to the brightness ping on the M5451s
#endif


// These "print" wrappers just output to BOTH serial ports
void println(char*s)
{
  Serial.println(s);
#ifdef Lightuino_USB
  Usb.println(s);
#endif
}

void print(char*s)
{
  Serial.print(s);
#ifdef Lightuino_USB
  Usb.print(s);
#endif
}
void print(int i,char format=DEC)
{
  Serial.print(i,format);
#ifdef Lightuino_USB
  Usb.print(i,format);
#endif
}

void println(int i,char format=DEC)
{
  Serial.println(i,format);
#ifdef Lightuino_USB
  Usb.println(i,format);
#endif
}



/* Do a delay, but also wait for user input if a global var is set */
char waitInput=false;
boolean mydelay(int amt)
{
  char incomingByte =0;
  delay(amt);
  if (waitInput)
    {
      // Wait for input from serial or usb serial
      while ((Serial.available()==0)
#ifdef Lightuino_USB
             && (Usb.available()==0))
#endif
        delay(10);
    }

  if (Serial.available())
    incomingByte = Serial.read();
#ifdef Lightuino_USB
  else if (Usb.available())
    incomingByte = Usb.read();
#endif

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
  else if (incomingByte == 'n')
    {
      println("next animation");
      return false;
    }
  return true;
}

void setup()
{
  //Start up the serial port
  Serial.begin(9600);
  Usb.begin();
  //Signal the program start
  println("Lightuino Animations v2.0");
}

// Runs 2 independent marquees of a single led (one on the left IDE cable, one on the right).
// delayTime is the # of ms between each frame
// iters is the number of times to go around
// ledBegin is the led # to begin at
// numLeds is the number of LEDs that are in the loop
void DoubleRollChaser(FlickerBrightness& out,int delayTime = 100,int iters=1, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,int intensityChange = CCShield_MAX_BRIGHTNESS-1)
{
  int i,j;
  int otherLed;
  for (j=0;j<iters;j++)
    {
  // Go through each LED in the circle
    for (i=ledBegin;i<ledBegin+numLeds;i++)
      {
        //otherLed = (ledBegin+(numLeds-1) - i) + (CCShield_NUMOUTS/2);
        otherLed = CCShield_NUMOUTS/2+ledBegin+i;
    
        // Lighten this one
        out.brightness[i] += intensityChange;
        out.brightness[otherLed] += intensityChange;   
 
        if (!mydelay(delayTime)) return;
    
       // Darken the prior one
       out.brightness[i] -= intensityChange;
       out.brightness[otherLed] -= intensityChange;

     }
  }
}



// Runs 2 independent marquees of a single led in opposite directions (one on the left IDE cable, one on the right).
// delayTime is the # of ms between each frame
// iters is the number of times to go around
// ledBegin is the led # to begin at
// numLeds is the number of LEDs that are in the loop
void OpposingRollChaser(FlickerBrightness& out,int delayTime = 100,int iters=1, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,int intensityChange=CCShield_MAX_BRIGHTNESS-1)
{
  int i,j;
  int otherLed;
  for (j=0;j<iters;j++)
    {
  // Go through each LED in the circle
    for (i=ledBegin;i<ledBegin+numLeds;i++)
      {
        otherLed = (ledBegin+(numLeds-1) - i) + (CCShield_NUMOUTS/2);
        //otherLed = 35+ledBegin+i;
    
        // Lighten this one
        out.brightness[i] += intensityChange;
        out.brightness[otherLed] += intensityChange;   
 
        if (!mydelay(delayTime)) return;
    
       // Darken the prior one
       out.brightness[i] -= intensityChange;
       out.brightness[otherLed] -= intensityChange;

     }
  }
}


void Cross(FlickerBrightness& out,int delayTime = 50,int iters=10, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,int intensityChange=CCShield_MAX_BRIGHTNESS-1, int precess=0)
{
  int i,j;
  int pos[2];
  pos[0] = ledBegin; pos[1] = ledBegin;
  
  for (j = 0; j<iters; j++)
  {
    for (i=0;i<numLeds;i++)
    {
      pos[0] += 1;
      pos[1] -= 1;
      if (pos[0]>=ledBegin+numLeds) pos[0] = ledBegin;
      if (pos[1]<ledBegin) pos[1] = ledBegin+numLeds-1;
      out.brightness[pos[0]] += intensityChange;
      out.brightness[pos[1]] += intensityChange;
      if (!mydelay(delayTime)) return;    
      out.brightness[pos[0]] -= intensityChange;
      out.brightness[pos[1]] -= intensityChange;
  
    }
    pos[1] += precess;
  }
}

// Sets the LEDs to an intensity gradient and then rotoes them.
// delayTime is the # of ms between each frame
// iters is the number of times to go around
// ledBegin is the led # to begin at
// numLeds is the number of LEDs that are in the loop
void IntensityRotater(FlickerBrightness& out,int delayTime = 300,int iters=1, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,int intensityChange = CCShield_MAX_BRIGHTNESS-1)
{
  int i,j;
  int otherLed;
  
  // Load the intensities:
  // Fade from brightest to dimmest
  if (0) for (i=ledBegin;i<numLeds;i++)
  {
    out.brightness[i]=i*(intensityChange/numLeds);
    out.brightness[i+CCShield_NUMOUTS/2]=i*(intensityChange/numLeds);
  }

  // Note this creates a linear intensity gradient but intensity perception (brightness) is actually the log of the energy
  // the effect of this is that this does not look like a linear brightness decrease.
  int incr = intensityChange/(numLeds/2);
  if (0) for (i=ledBegin;i<(numLeds/2)+1;i++)
  {    
    out.brightness[i]=i*incr;
    out.brightness[i+CCShield_NUMOUTS/2]=i*incr;
    out.brightness[numLeds-i]=i*incr;
    out.brightness[(numLeds-i)+CCShield_NUMOUTS/2]=i*incr;
  }
  
  float val = 1.385355;
  float cur = val;
  if (1) for (i=ledBegin;i<(numLeds/2)+1;i++)
  { 
    cur *=val;
    println(cur);
    //out.bresenham[i] = random(0,CCShield_MAX_BRIGHTNESS);
    //out.bresenham[i+CCShield_NUMOUTS/2] = random(0,CCShield_MAX_BRIGHTNESS);
    //out.bresenham[numLeds-i] = random(0,CCShield_MAX_BRIGHTNESS);
    //out.bresenham[(numLeds-i)+CCShield_NUMOUTS/2] = random(0,CCShield_MAX_BRIGHTNESS);
    out.brightness[i]=(int)cur;
    out.brightness[i+CCShield_NUMOUTS/2]=(int)cur;
    out.brightness[numLeds-i]=(int)cur;
    out.brightness[(numLeds-i)+CCShield_NUMOUTS/2]=(int)cur;
  }
  
  
  for (j=0;j<iters;j++)
    {
    // Save the first intensities
    int intensity = out.brightness[ledBegin];
    int otherintensity = out.brightness[CCShield_NUMOUTS/2+ledBegin];
    
    // Go through each LED in the circle
    for (i=ledBegin;i<ledBegin+numLeds;i++)
      {
       otherLed = CCShield_NUMOUTS/2+ledBegin+i;
    
        // set the previous to the next intensity
       out.brightness[i] = out.brightness[i+1];
       out.brightness[otherLed] = out.brightness[otherLed+1];  
     
     }
   out.brightness[i] = intensity;
   out.brightness[otherLed] = otherintensity;     
   if (!mydelay(delayTime)) return; 
  }
}

// Marquee
// delayTime is the # of ms between each frame
// iters is the number of times to go around
// ledBegin is the led # to begin at
// numLeds is the number of LEDs that are in the loop
// fill is true if you want this code to fill the initial LED intensities, otherwise you can do it.
void Marquee(FlickerBrightness& out,int delayTime = 100,int iters=1, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,char fill=true)
{
  int i,j;
  int otherLed;
  
  int lut[8] = { CCShield_MAX_BRIGHTNESS-1, CCShield_MAX_BRIGHTNESS/2, CCShield_MAX_BRIGHTNESS/4, CCShield_MAX_BRIGHTNESS/8,
                 CCShield_MAX_BRIGHTNESS/16,CCShield_MAX_BRIGHTNESS/32,0,0};

  if (fill) for (i=ledBegin;i<ledBegin+numLeds;i++)
  {
    
    out.brightness[i]=lut[i&7];
    out.brightness[i+CCShield_NUMOUTS/2]=lut[i&7];
  }
  
  for (j=0;j<iters;j++)
    {
    // Save the first intensities
    int intensity = out.brightness[ledBegin];
    int otherintensity = out.brightness[CCShield_NUMOUTS/2+ledBegin];
    
    // Go through each LED in the circle
    for (i=ledBegin;i<ledBegin+numLeds;i++)
      {
       otherLed = CCShield_NUMOUTS/2+ledBegin+i;
    
        // set the previous to the next intensity
       out.brightness[i] = out.brightness[i+1];
       out.brightness[otherLed] = out.brightness[otherLed+1];  
     
     }
   out.brightness[i] = intensity;
   out.brightness[otherLed] = otherintensity;     
   if (!mydelay(delayTime)) return; 
  }
}


void RgbFader(FlickerBrightness& out, int pins[3], int delayTime, int iters)
{
  int incr[3] = {0}; //{1,5,13};
  for(int i=0;i<3;i++)
  {
    incr[i] = random(-10,10);
    out.brightness[pins[i]] = CCShield_MIN_INTENSITY;
  }
  
  for (int i=0;i<iters;i++)
  {
    for (int j=0;j<3;j++)
      {
        int val = out.brightness[pins[j]];
        val += incr[j];
        if ((val<CCShield_MIN_INTENSITY)||(val>=CCShield_MAX_BRIGHTNESS))
        {
          if (val<CCShield_MIN_INTENSITY) val = CCShield_MIN_INTENSITY;
          else val = CCShield_MAX_BRIGHTNESS-1;
          incr[j] *=-1;
          incr[j] += random(-2,2);
          if (incr[j]>10) incr[j]=10;
          if (incr[j]<-10) incr[j]=-10;
          if (incr[j]==0) incr[j] = 1;
          
          print(val);
          print(" ");
          print(incr[j]);
          println(" ");
          
        }
        out.brightness[pins[j]] = val;
      }
      
   if (!mydelay(delayTime)) return;
  }
}

void allDark(FlickerBrightness& leds)
{
  for (int i=0;i<70;i++)
   {
     leds.brightness[i]= 0;
     
   }
}


void loop()
{
  Lightuino board(myClockPin,mySerDataPinLeft,mySerDataPinRight, myBrightnessPin);   
  board.flags |= CCShield_FASTSET;  // fast set relies on AVR registers not digitalWrite, so may not work on some Arduino variants.
  board.setBrightness(255);

#ifdef LIGHTUINO3
  if (1)  // just turn off the source drivers
    {
    LightuinoSourceDriver drvr;
    drvr.set(0);
    }
#endif
    
   if (1)
     {
     println("Light Check -- ALL ON");
     board.set(0xffffffffUL, 0xffffffffUL,0xff);      
     }

#if 0
  for(int k=0;k<1;k++) for (int i=0;i<256;i++)
    {
      println(i);
      println(" ");
      board.setBrightness(i);
      mydelay(20);
    }
#endif

  println("Say hi");
  pinMode(ledPin,OUTPUT);
  for (int j=0;j<12;j++)
    {
      digitalWrite(ledPin,1);
      if (!mydelay(j*j*5)) break;
      digitalWrite(ledPin,0);
      if (!mydelay(j*j*5)) break;
      
    }
  mydelay(2000); 
  board.setBrightness(255);
  board.set(0x0UL, 0x0UL,0x0);      
   
      
  FlickerBrightness leds(board);
  leds.StartAutoLoop();
 
  
   if (1)
     {
     println("Individual Light Check");
      
     for (int i=0;i<70;i++)
       {
       leds.brightness[i]= CCShield_MAX_BRIGHTNESS-1;
       println(i);
       if (!mydelay(50)) break;
       leds.brightness[i]= 0;     
       }
     }
   
   allDark(leds);
   
#if 0
   println("DoubleRollChaser");
   DoubleRollChaser(leds);
   
   allDark(leds);
   println("Opposite RollChaser");
   OpposingRollChaser(leds); 
  
   allDark(leds);
   println("Cross");
   Cross(leds,50,1,0,32,(CCShield_MAX_BRIGHTNESS/2)-1,0);
#endif

 //  mydelay(60000);
   allDark(leds);
   println("Ani");
   println("  Wiper");
   if (1)
   {
     AniWiper w(leds,0,32,100,CCShield_MAX_BRIGHTNESS/2-1);
     
     w.draw();
     for (int i=0;i<100;i++)
     {
       w.loop();
       if (!mydelay(100-i)) break;
     }
     w.erase();
   }

   println("  Sweep");
   
   
   if (1)
   {     
     AniWiper w(leds,0,32,100,CCShield_MAX_BRIGHTNESS/2-1);     
     AniWiper w1(leds,0,32,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniWiper w2(leds,34,32,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniWiper w3(leds,34,32,100,CCShield_MAX_BRIGHTNESS/2-1);
     w.lst = &w1;
     w1.lst = &w2;
     w2.lst = &w3;
     
     w3.cpos=w3.end;
     w1.cpos=w1.end;    
     AniDraw(w);
     for (int i=0;i<100;i++)
       {
         AniLoop(w);
         if (!mydelay(50)) break;
       }
     AniErase(w);
   }
   
   if (1)
   {     
     AniSweep w(leds,0,7,100,CCShield_MAX_BRIGHTNESS/2-1);     
     AniSweep w1(leds,8,15,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniSweep w2(leds,23,16,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniSweep w3(leds,31,24,100,CCShield_MAX_BRIGHTNESS/2-1);

     int st = 35;
     AniSweep w4(leds,st,st+16,100,CCShield_MAX_BRIGHTNESS/2-1);     
     AniSweep w5(leds,st,st+16,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniSweep w6(leds,st+31,st+16,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniSweep w7(leds,st+31,st+16,100,CCShield_MAX_BRIGHTNESS/2-1);
     
     w.lst = &w1;
     w1.lst = &w2;
     w2.lst = &w3; 
     w3.lst = &w4;
     w4.lst = &w5;
     w5.lst = &w6;
     w6.lst = &w7;
     w5.cpos = st+8;  // Start it halfway
     w6.cpos = st+24;
     
     AniDraw(w);
     for (int i=0;i<100;i++)
       {
         AniLoop(w);
         if (!mydelay(75)) break;
       }
     AniErase(w);
   }

   println("DoubleRollChaser with other lit LEDs");
   allDark(leds);
   leds.brightness[4] = Lightuino_MAX_BRIGHTNESS/14;
   leds.brightness[15] = Lightuino_MAX_BRIGHTNESS/7;
   leds.brightness[27] = Lightuino_MAX_BRIGHTNESS/2;
   leds.brightness[36] = Lightuino_MAX_BRIGHTNESS/5;
   leds.brightness[49] = Lightuino_MAX_BRIGHTNESS/10;
   leds.brightness[53] = Lightuino_MAX_BRIGHTNESS/20;
   // void DoubleRollChaser(FlickerBrightness& out,int delayTime = 100,int iters=1, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,int intensityChange = CCShield_MAX_BRIGHTNESS-1)
   DoubleRollChaser(leds,75,4,0,32,CCShield_MAX_BRIGHTNESS/2);
   allDark(leds);

   if (1)
   {     
     AniWiper w(leds,0,8,100,CCShield_MAX_BRIGHTNESS/2-1);     
     AniWiper w1(leds,8,8,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniWiper w2(leds,16,8,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniWiper w3(leds,24,8,100,CCShield_MAX_BRIGHTNESS/2-1);
     w.lst = &w1;
     w1.lst = &w2;
     w2.lst = &w3;
     
     w3.cpos=w3.end;
     w1.cpos=w1.end;    
     AniDraw(w);
     for (int i=0;i<200;i++)
       {
         AniLoop(w);
         // reflect whatever is from 0-35 to the other side
         for(int j=0;j<CCShield_NUMOUTS/2;j++)
           leds.brightness[CCShield_NUMOUTS/2+j] = leds.brightness[j];
         
         if (!mydelay(25)) break;
       }
     AniErase(w);
   }


   if (1)
   {     
     AniWiper w(leds,0,3,100,CCShield_MAX_BRIGHTNESS/2-1);     
     AniWiper w1(leds,3,5,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniWiper w2(leds,8,9,100,CCShield_MAX_BRIGHTNESS/2-1);
     AniWiper w3(leds,17,15,100,CCShield_MAX_BRIGHTNESS/2-1);
     w.lst = &w1;
     w1.lst = &w2;
     w2.lst = &w3;
     
     w3.cpos=w3.end;
     w1.cpos=w1.end;    
     AniDraw(w);
     for (int i=0;i<200;i++)
       {
         AniLoop(w);
         // reflect whatever is from 0-35 to the other side
         for(int j=0;j<CCShield_NUMOUTS/2;j++)
           leds.brightness[CCShield_NUMOUTS/2+j] = leds.brightness[j];
         if (!mydelay(25)) break;
       }
     AniErase(w);
   }




   println("Marquee");
   //void Marquee(FlickerBrightness& out,int delayTime = 100,int iters=1, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,int fill)
   Marquee(leds,50,200,0,32,true);

  //void IntensityRotater(FlickerBrightness& out,int delayTime = 100,int iters=1, int ledBegin=0,int numLeds=CCShield_NUMOUTS/2,int intensityChange = CCShield_MAX_BRIGHTNESS-1)
   println("IntensityRotater");
   IntensityRotater(leds,25,200);
   IntensityRotater(leds,15,300);
   IntensityRotater(leds,5,600);
   //IntensityRotater(leds,1,600);

    //println("RGB Fader");
   //int pins[3] = {28,29,30};
  //RgbFader(leds,pins,50,10000/50);
   

}
