// I use this project to test and develop the lightuino library itself.
// It is probably not that interesting to you unless you are hacking the library.

#include "./lightuino.h"
#include "avr/pgmspace.h"


int myClockPin =     3; //6;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin =   5; //4; // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 =  2; //7; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 11;          // What Arduino pin goes to the brightness ping on the M5451s
int ledPin = 13;  // The normal arduino example LED

#define TIMER_CLOCK_FREQ (16000000.0/128.0) //2MHz for /8 prescale from 16MHz

// Code from: http://www.uchobby.com/index.php/2007/11/24/arduino-interrupts/
// Setup Timer2.
//Configures the ATMegay168 8-Bit Timer2 to generate an interrupt at the specified frequency.
//Returns the time load value which must be loaded into TCNT2 inside your ISR routine.
//See the example usage below.
unsigned char SetupTimer2(float timeoutFrequency)
{
  unsigned char result; //The value to load into the timer to control the timeout interval.

  //Calculate the timer load value
  result=(int)((257.0-(TIMER_CLOCK_FREQ/timeoutFrequency))+0.5); //the 0.5 is for rounding;
  //The 257 really should be 256 but I get better results with 257, dont know why.

  //Timer2 Settings: Timer Prescaler /8, mode 0
  //Timmer clock = 16MHz/8 = 2Mhz or 0.5us
  //The /8 prescale gives us a good range to work with so we just hard code this for now.
  TCCR2A = 0;
  TCCR2B = 1<<CS22 | 0<<CS21 | 1<<CS20; 

  //Timer2 Overflow Interrupt Enable   
  TIMSK2 = 1<<TOIE2;

  //load the timer for its first cycle
  TCNT2=result; 
  
  return(result);
}


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
  Serial.println("Lightuino library development test v1.0");
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
  FlickerBrightness leds(board);
  //gleds = &leds;
  leds.StartAutoLoop();
  
  for (j=0;j<200;j++)
  {
  for (i=0;i<32;i++)
  {
    leds.brightness[i] = i*10;
  }
  mydelay(500); 
  for (k=0;k<2000;k++)
  {
  for (i=0;i<32;i++)
  {
    Serial.println("loop");
    //leds.brightness[i] =  0;
    leds.brightness[i+1] = i* (Lightuino_MAX_BRIGHTNESS/10); 
    mydelay(2);
  }
  }
  }
  //gleds = 0;  
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


   TestByteSet(out);

   Serial.println("RunThru");
   RunThru(out);

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
     
     FlickerRoll(flk);
     Serial.println("Flicker Tests By 32");
     out.flags |= Lightuino_BY32;
     FlickerRoll(flk);
     
     out.flags &= ~Lightuino_BY32;
     
     }
     
     
   Serial.println("RollChaser");
   //RollChaser(out);
   Serial.println("Opposite RollChaser");
   //RollChaserOpposing(out); 

   //Serial.println("TimerTest");
   //TestTimer(out);

}
