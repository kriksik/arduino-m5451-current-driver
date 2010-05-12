#include <Wire.h>

#include "i2c.h"
#include "mma7660.h"

#include <lightuino.h>


#include "avr/pgmspace.h"

int myClockPin =     6; //6;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin =   5; //4; // 7; //9;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 =  7; //7; //8; //10;             // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
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
  
  i2c.begin();
  accel.begin();
}




#define xPin 0
#define yPin 1
#define zPin 2

#define ZEROG 512 //350
#define GRAVITY 116

#define NUMLIGHTS 32

char dump = 1;
char tail = 0; //8;
char yz = 0;

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
  float light2 = 0;
  int sensValx = 0;
  int senspos = 0;

  digitalWrite(xPin,HIGH);
  digitalWrite(yPin,HIGH);
  digitalWrite(zPin,HIGH);
  
  board.flags = Lightuino_FASTSET; // | Lightuino_BY32;
  board.setBrightness(255);
  
  while (1)
  {
  delta = x + y + z;
  sample();
  delta -= x + y + z;

  // MMA7660 section
  if (1)
    {
      Acceleration rot;
      rot = accel.getXYZ();
      
      if (dump)
        {
 Serial.print("MMA7660: ");  
 Serial.print((int)rot.x);
 Serial.print(" ");
 Serial.print((int)rot.y);
 Serial.print(" ");
 Serial.print((int)rot.z);
 Serial.println("  ");          
        }
        
      light2 = rot.x/2;
      leds.brightness[((int)light2)+35+12] = 255;      
    }
    
  if (dump)
  {
  Serial.print("ADXL330: ");
  Serial.print(x);
  Serial.print(", ");  
  Serial.print(y);
  Serial.print(", ");
  Serial.print(z);
  Serial.print(", ");
  Serial.println(abs(delta));
  }
  
  for (int i=0;i<100;i++) leds.loop();
  //delay(100);
  
  // Cool down old spots
  for (int i=0;i<70;i++)
    {
      if ((i!= light)&&(i!=light2))
      {
        if (tail)
        {
        if (leds.brightness[i]>20) leds.brightness[i] -=  (leds.brightness[i]/tail);
        else leds.brightness[i] = 0;
        }
        else leds.brightness[i] = 0;
      }
    }
    
  if (0)  // Can only move 1 in either direction at a time.
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
        
      if (dump)
        {
        Serial.print("   light: ");
        Serial.print(light);
        Serial.print(" delta ");
        Serial.print(delta);
        }
      if (light >= NUMLIGHTS) light = NUMLIGHTS-1;
      if (light < -NUMLIGHTS) light = -NUMLIGHTS;
      if (light>=0) leds.brightness[(int)light+NUMLIGHTS] = 255;
      if (light<=0) leds.brightness[(int)(-1*light)] = 255;
      //leds.brightness[light+NUMLIGHTS] = 255;
    }  
  if (1) // Direct positioning
    {
    if (0)
      {  
      if (x>0)
        light = (x/3)+35;
      if (x<0) { light=abs(x/3); if (light >= 35) light = 34; }  
      if (light<0) light = 0;
      if (light>69) light = 69;
      }
    else
      {
      light = x*35;
      light /= (GRAVITY*2);
      light += 16;
      if (light<0) light = 0;
      if (light>34) light = 34;       
      }
    if (0) //(leds.brightness[light]<100)
      leds.brightness[(int)light] = (leds.brightness[(int)light] * 2) + 30;
    else
      leds.brightness[(int)light] = 255;
    }  
  
  if (dump)
    {
    Serial.println();
    }
  
  
  if (yz)
    {
    //if (!(z > 50))  leds.brightness[69] = 255;
    if (!(z < -20)) { leds.brightness[66] = 255; leds.brightness[69] = 255; }
  
    if (y > 50)  { leds.brightness[68] = 255;leds.brightness[65] = 255; }
    if (y < -50) { leds.brightness[67] = 255; leds.brightness[64] = 255; }
    }  
    

  }
  
  
}


