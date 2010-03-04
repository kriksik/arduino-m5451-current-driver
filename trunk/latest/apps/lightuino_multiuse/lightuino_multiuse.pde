/*? <section name="examples">
<sketch name='lightuino_multiuse'>
This sketch shows Lightuino control of different types of hardware.  Included are:
<html><ul>
<li>1. LEDs in series
</li>
<li>2. RGB LEDs
</li>
<li>3. Lasers
</li>
<li>4. Servo motors
</li>
<li>5. DC motors (really any "load" driven by a PNP power transistor)
</li>
<li>6. A load driven by a P-type MOSFET
</li>
<li>7. Relays
</li>
</ul></html>
*/

//? <html><h3>Boilerplate Initialization</h3> <textarea cols="160" rows="30" style="font-family:monospace">

//?[
#include <lightuino.h>

int myClockPin =     3; //6;                // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin =   2; //5;                // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 =  5;                // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 10;              // What Arduino pin goes to the brightness ping on the M5451s
int ledPin = 13;  // The normal arduino example LED


void setup()
{
    //Start up the serial port
  Serial.begin(9600);
  //Start the timer and get the timer reload value.
  //timerLoadValue=SetupTimer2(4*8192); //1000); //44100);  
  //Signal the program start
  Serial.println("Lightuino multiuse demonstration");
}



Lightuino board(myClockPin,mySerDataPin,mySerDataPin2, myBrightnessPin);   
FlickerBrightness leds(board);

//?]
//?</textarea>
//?<h3>Define which pin will control which demo</h3><textarea cols="160" rows="15" style="font-family:monospace">
//?[
#define LEDSERIES 35

#define RGBLEDBLUE 36
#define RGBLEDGRN  37
#define RGBLEDRED  38

#define LASER 39
#define SERVO1 41
#define SERVO2 42

#define MOTOR 43
#define RELAY 44
//?]
//?</textarea>

//?<h3>The main loop</h3>
//?<textarea cols="160" rows="30" style="font-family:monospace">

//?[
void loop() 
  {
  board.flags = Lightuino_FASTSET;
  
  //pinFinder();
  
  while (1)
  {

  Serial.println("Turn on the line of 3 LEDS gradually");
  for (int j=0;j<255;j++)
    {
    leds.brightness[LEDSERIES] = j;
    for (int i=0;i<100;i++) leds.loop();
    }
    leds.brightness[LEDSERIES] = 0;


  Serial.println("Turn on each color channel in the RGB LED gradually");
  for (int k=0;k<3;k++)
    {
    for (int j=0;j<255;j++)
      {
      leds.brightness[RGBLEDBLUE+k] = j;
      for (int i=0;i<10;i++) leds.loop();
      }
      leds.brightness[RGBLEDBLUE+k] = 0;
    }
    
  Serial.println("Turn on the Laser, flash it faster and faster (shine it on a wall and wiggle it to show this)");
  for (int j=0;j<255;j++)
    {
    leds.brightness[LASER] = j;
    for (int i=0;i<50;i++) leds.loop();
    }
    leds.brightness[LASER] = 0;


  Serial.println("Move the Servo slowly around its range");
  unsigned long int servoOn = (1UL << (SERVO1-32));
  int delayTime = 2000;
  for (int j=1;j<1800;j+=80)
    {
      for (int k=0; k<3; k++)
      {
      board.fastSet(0,0,0);
      delayMicroseconds(300 + j);
      board.fastSet(0,servoOn,0);
      delayMicroseconds(delayTime-j);
      delay(18);  // During this delay you could drive more servos
      }
    delay(50);  // Pause so that it stops
    }
    leds.brightness[SERVO1] = 0;


  Serial.println("Change the speed of the DC motor");
  
  for (int j=0;j<255;j++)
    {
    leds.brightness[MOTOR] = j;
    for (int i=0;i<50;i++) leds.loop();
    }
    leds.brightness[MOTOR] = 0;

   Serial.println("Turn on the relay");
   unsigned long int relayOn = (1UL << (RELAY-32));

   board.fastSet(0,relayOn,0);
   delay(2000);
   board.fastSet(0,0,0); 
 
  }
}

void pinFinder(void)
{
  while (1)
  {

  //leds.brightness[0] = 32;
  //leds.brightness[34] = 64;
  leds.brightness[35] = 128;
  //leds.brightness[69] = 255;
  for (int i=0;i<10;i++) leds.loop();
  //delay(100);
  }
}
//?]
//?</textarea></html>

/*?</sketch></section>
*/

