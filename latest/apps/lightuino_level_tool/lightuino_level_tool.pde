#include <lightuino.h>

#include "avr/pgmspace.h"

int myClockPin =     3; //6;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin =   4; //4; // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 =  5; //7; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 10;          // What Arduino pin goes to the brightness ping on the M5451s
int ledPin = 13;  // The normal arduino example LED


void setup()
{
    //Start up the serial port
  Serial.begin(9600);
  //Start the timer and get the timer reload value.
  //timerLoadValue=SetupTimer2(4*8192); //1000); //44100);  
  //Signal the program start
  Serial.println("LED level using an accelerometer");
}




#define xPin 0
#define yPin 1
#define zPin 2

#define ZEROG 512 //350
#define GRAVITY 116

#define NUMLIGHTS 32

int x = 0;
int y = 0;
int z  = 0;
float delta = 0;

void sample(void)
{
  int sx=0,sy=0,sz=0;
  for(int i=0;i<1;i++)
  {
  sx += analogRead(xPin);
  sy += analogRead(yPin);
  sz += analogRead(zPin);
  }
  x = (sx>>0)-ZEROG;
  y = (sy>>0)-ZEROG;
  z = (sz>>0)-ZEROG;
  
}


CCShield board(myClockPin,mySerDataPin,mySerDataPin2, myBrightnessPin);   
FlickerBrightness leds(board);


void loop() 
  {
  float light = 0;
  int sensValx = 0;
  int senspos = 0;

  digitalWrite(xPin,HIGH);
  digitalWrite(yPin,HIGH);
  digitalWrite(zPin,HIGH);
  
  board.flags = Lightuino_FASTSET | Lightuino_BY32;
  
  while (1)
  {
  delta = x + y + z;
  sample();
  delta -= x + y + z;


  if (0)
  {
  Serial.print(x);
  Serial.print(", ");  
  Serial.print(y);
  Serial.print(", ");
  Serial.print(z);
  Serial.print(", ");
  Serial.print(abs(delta));
  }
  
  for (int i=0;i<10;i++) leds.loop();
  //delay(100);
  
  for (int i=0;i<70;i++)
    {
      if (i!= light)
      {
        if (leds.brightness[i]>20) leds.brightness[i] -=  (leds.brightness[i]/8);
        else leds.brightness[i] = 0;
      }
    }
    
  if (1)  // Can only move 1 in either direction at a time.
    {
      delta = x - (light*(float)GRAVITY/NUMLIGHTS);
      //senspos += delta;
      if (delta > GRAVITY/NUMLIGHTS)
         { light +=1; sensValx +=GRAVITY/NUMLIGHTS;
        }
      else if (delta < -GRAVITY/NUMLIGHTS) 
        {
          light -= 1;
          sensValx -= GRAVITY/NUMLIGHTS;
        }
        
      if (0)
        {
      Serial.print("   light: ");
      Serial.print(light);
      Serial.print(" delta ");
      Serial.println(delta);
        }
      if (light >= NUMLIGHTS) light = NUMLIGHTS-1;
      if (light < -NUMLIGHTS) light = -NUMLIGHTS;
      if (light>=0) leds.brightness[(int)light+NUMLIGHTS] = 255;
      if (light<=0) leds.brightness[(int)(-1*light)] = 255;
      //leds.brightness[light+NUMLIGHTS] = 255;
    }  
    
  //if (!(z > 50))  leds.brightness[69] = 255;
  if (!(z < -20)) { leds.brightness[66] = 255; leds.brightness[69] = 255; }
  
  if (y > 50)  { leds.brightness[68] = 255;leds.brightness[65] = 255; }
  if (y < -50) { leds.brightness[67] = 255; leds.brightness[64] = 255; }
    
  if (0) // Direct positioning
    {
    if (x>0)
      light = (x/3)+35;
    if (x<0) { light=abs(x/3); if (light >= 35) light = 34; }  
    if (light<0) light = 0;
    if (light>69) light = 69;
    if (0) //(leds.brightness[light]<100)
      leds.brightness[(int)light] = (leds.brightness[(int)light] * 2) + 30;
    else
      leds.brightness[(int)light] = 255;
    }
  }
}


