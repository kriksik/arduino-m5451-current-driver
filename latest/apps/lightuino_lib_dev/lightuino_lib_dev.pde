// I use this project to test and develop the lightuino library itself.
// It is probably not that interesting to you unless you are hacking the library.

#include "./lightuino.h"
#include "avr/pgmspace.h"


int myClockPin =     6; //6;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin =   5; //4; // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 =  7; //7; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 10;          // What Arduino pin goes to the brightness ping on the M5451s
int ledPin = 13;  // The normal arduino example LED


#define TOGGLE_IO 13

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

void setup()
{
    //Start up the serial port
  Serial.begin(9600);
  //Start the timer and get the timer reload value.
  //timerLoadValue=SetupTimer2(4*8192); //1000); //44100);  
  //Signal the program start
  Serial.println("Lightuino library development test v2.0");
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
    mydelay(100);    
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
  
  for (j=0;j<200;j++)
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

void loop()
{
   Lightuino out(myClockPin,mySerDataPin,mySerDataPin2, myBrightnessPin);
   out.flags |= Lightuino_FASTSET;  // fast set relies on AVR registers not digitalWrite, so may not work on some Arduino variants.
   out.flags |= Lightuino_BY32;

   if (0)
   {
   TestByteSet(out);
   }

   if (0)
   {
   Serial.println("RunThru");
   RunThru(out);
   }


   if (0)
     {
     Serial.println("Flicker Tests");
     FlickerBrightness flk(out);
     for (int i=0;i<70;i++) flk.brightness[i] = 0;
     flk.StartAutoLoop();
     
     Serial.println("Verify alignment");
     flk.brightness[0] = 200;
     flk.brightness[31] = 200;
     mydelay(5000);
     
     FlickerRoll(flk);
     Serial.println("Flicker Tests By 32");
     out.flags |= Lightuino_BY32;
     FlickerRoll(flk);
     
     out.flags &= ~Lightuino_BY32;     
     }
     
   if (1)
     {
       TestTimer(out);
     }  
     
     
   Serial.println("RollChaser");
   //RollChaser(out);
   Serial.println("Opposite RollChaser");
   //RollChaserOpposing(out); 

   //Serial.println("TimerTest");
   //TestTimer(out);

}
