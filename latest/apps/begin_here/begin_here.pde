/*? <section name="examples">
<sketch name="begin_here">
This sketch shows basic Lightuino control, so you can get up and running quickly!
<verbatim>
*/


// Include the Lightuino library
#include <lightuino.h>

// NOTE: you must set these pins correctly for your board.
// But what is set here is the default I ship with, so you probably don't need to do anything.
int myClockPin =     6;              // Arduino pin that goes to the clock on all M5451 chips
int mySerDataPin =   5;              // Arduino pin that goes to data on one M5451 chip
int mySerDataPin2 =  7;              // Arduino pin that goes to data on another M5451 chip (if you don't have 2, set this to an unused digital pin)
int myBrightnessPin = 10;            // What Arduino pin goes to the brightness ping on the M5451s


void setup()
{
  // Start up the serial port.  This is not required for the lightuino, I'm just doing it so I can print stuff.
  Serial.begin(9600);
  Serial.println("Lightuino Introduction Sketch");
}

// Create the basic lightuino object
Lightuino board(myClockPin,mySerDataPin,mySerDataPin2, myBrightnessPin);

// This object PWMs the Lightuino outputs, and provides array-based access to the Leds
FlickerBrightness leds(board);

void loop() 
  {
    
  Serial.println("A Simple Marquee");
  
  for (int i=0;i<15;i++)
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

    
  Serial.println("Now show brightness changes");
        
  
  for (int j=0;j<600;j++)
    {
    // You just set leds.brightness[LED_NUMBER] to the desired intensity (0-255).
    // Note that you will see blinking at low intensities, so the minimum brightness you can set is around 30

    // Here I will set each LED to a slightly different intensity.
    for (int i=0;i<70;i++)
      leds.brightness[i] = (((i*3)+j)*10)%256;  // Your homework is to figure out why this formula works! :-)
    
    // The CPU controls the rapid blinking that creates the variable brightness effect
    // so you must call leds.loop() rapidly to make it happen.
    // Note: You can also set it up so that the Lightuino library calls this function periodically automatically
    // but that is beyond this simple tutorial.  It can be found in the lightuino_animations sketch.
    for (int i=0;i<50;i++) leds.loop();
    }
    
  

  Serial.println("Turn them all off!");  
  board.set(0,0,0);
  
  // Its THAT simple!
  
  // But before you go off and reinvent the wheel on top of the functions shown here, please check 
  // out the more advanced animation functions used in the other sketches (for example lightuino_animations).  

  // Mastering them will will let you code complex patterns with less effort than doing it yourself.
}


// This is a convenient function which illuminates the first and last LED on each side
// so you can find the pins on the board.  This sketch does not actually call this function,
// its just here for your use.
void pinFinder(void)
{
  while (1)
  {

  leds.brightness[0] = 32;
  leds.brightness[34] = 64;
  leds.brightness[35] = 128;
  leds.brightness[69] = 255;
  for (int i=0;i<10;i++) leds.loop();
  }
}


/*? </verbatim></sketch></section>
*/

