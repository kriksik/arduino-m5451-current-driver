/*? <section name="examples">
<sketch name="begin_here">
This sketch shows basic Lightuino control, so you can get up and running quickly!
<verbatim>
*/

// Include the Lightuino library
#include <lightuino3.h>

void setup(void)
  {
  // Start up the serial port.  This is not required for the lightuino, I'm just doing it so I can print stuff.
  Serial.begin(9600);
  Serial.println("Lightuino3 Introduction Sketch V1.0");
  }
  
// Create the basic Lightuino 70 LED sink controller (the pins in the 2 40-pin IDE connectors)
LightuinoSink sinks;

// This object PWMs the Lightuino outputs, and provides array-based access to the Leds
FlickerBrightness pwm(sinks);

//?? A wrapper around delay so you can tweak how long the delays actually are...
void mydelay(int amt)
{
  delay(amt);
}

//?? This function demonstrates turning the 70 sinks on/off
void SinkOnOffDemo()
  {
  Serial.println("Sink Discrete (On/OFF) Control Demo");
  
  for (int i=0;i<15;i++)
    {
    Serial.println("  Turn on every other LED");
    
    // Each bit (1 or 0) in this array corresponds to one LED light
    byte ledState[9] = {B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010,B10101010};
     
    // Now send it to the chips.
    sinks.set(ledState);  
      
    delay(250);
  
    Serial.println("  Now put in the opposite pattern");
    // Now set up another pattern
    for (int j=0;j<9;j++) ledState[j] = B01010101;
    
    // Now send it to the chips.
    sinks.set(ledState);  
      
    delay(250);
    }
   
  Serial.println("  Turn them all off!");  
  sinks.set(0,0,0);
  
  // Its THAT simple!
  
  // But before you go off and reinvent the wheel on top of the functions shown here, please check 
  // out the more advanced animation functions used in the other sketches (for example lightuino_animations).  

  // Mastering them will will let you code complex patterns with less effort than doing it yourself.
}

//?? This function demonstrates PWM control over the LED sinks
void SinkPwmDemo()
  {
  Serial.println("Now show brightness changes (PWM control)");
        
  for (int j=0;j<600;j++)
    {
    // You just set leds.brightness[LED_NUMBER] to the desired intensity (0-255).
    // Note that you will see blinking at low intensities, so the minimum brightness you can set is around 30

    // Here I will set each LED to a slightly different intensity.
    for (int i=0;i<70;i++)
      pwm.brightness[i] = (((i*3)+j)*10)%256;  // Your homework is to figure out why this formula works! :-)
    
    // The CPU controls the rapid blinking that creates the variable brightness effect
    // so you must call leds.loop() rapidly to make it happen.
    // Note: You can also set it up so that the Lightuino library calls this function periodically automatically
    // but that is beyond this simple tutorial.  It can be found in the lightuino_animations sketch.
    for (int i=0;i<400;i++) pwm.loop();
    }
  }

//?? This function demonstrates control over the source drivers (the 16 pin header on top)
void SourceDriverDemo()
{
  LightuinoSourceDriver drvr;
  Serial.println("Source Driver Demo");
  
  Serial.println("  Driving alternating patterns");
  if(1) for (int i=0;i<100;i++)
    {
      drvr.set(0x5555);
      mydelay(250);
      drvr.set(0xaaaa);
      mydelay(250);
    }

  Serial.println("  Shifting 1 set bit (per 8 bits) through the chips.");
  drvr.set(0x0000);
  for (int i=0;i<100;i++)
    {
      mydelay(100);
      drvr.shift(((i&7)==0));
    }  
}

void LightSensorDemo(void)
  {
  LightSensor light;  // Initialize the light sensor

  Serial.println("Light sensor demo");

  Serial.print("  Current: ");
  int curval = light.read();  // Read it -- returns an "analog" number just like analogRead() (i.e. 0-1024)
  Serial.println(curval);

  Serial.println("  Cover the sensor fully to end the demo (automatically ends in 50 seconds)");
  int val;
  int cnt = 0;
  do
    {
    val = light.read();
    Serial.print("  Sensor value is: ");
    Serial.println(val);
    mydelay(500);
    cnt++;
    } while (cnt<100 && val<LightSensor::Dusk);  // Some convenient constants are defined like "Dusk".  See the header file or docs...
}

void IrDemo(void)
{
  IrReceiver ir;  // Initialize the IR receiver
  Serial.println("Infrared Receiver Demo");  
  Serial.println("  Waiting for input from your infrared remote -- demo will stop after 5 one-second intervals without input.");
  for (int i=0;i<5;)
    {
    unsigned long int code = ir.read();  // Read a code from the input buffer
    if (code)                            // Nonzero means a code was received.
    {
      // Print it out in hex and binary notation
      Serial.print("  code: ");
      Serial.print((unsigned long int)(code>>32),HEX);
      Serial.print(" ");
      Serial.print((unsigned long int)(code),HEX);
      Serial.print(" | ");
      Serial.print((unsigned long int)(code>>32),BIN);
      Serial.print(" ");
      Serial.println((unsigned long int)(code),BIN);
    }
    else                                 // A zero means no code was received.
      {
        delay(1000);
        i++;
      }    
  }
}

const char* stringA = "LIGHTUINO 3   SEVENTY BY SIXTEEN LED MATRIX";
const char* stringB = "SALE TOILET PAPER LIGHTLY USED   REROLLED";
void MatrixDemo(LightuinoSink& sink)
{
  Serial.println("LED Matrix Demo");
  LightuinoSourceDriver src;  // Create the source driver object because we didn't create it globally (but we could have!)

  // Create the matrix object.  Pass the source and sink objects, the start scan line, and the total # of lines.  In this case I am doing ALL of them.
  LightuinoMatrix mtx(sink,src,0,16);  

  Serial.println("  Turn on the entire matrix");
  mtx.clear(1);
  // You've got to keep calling loop to paint each scan line in the matrix
  for (int j=0;j<5000;j++) { mtx.loop();}
 
  Serial.println("  Write a bit pattern into the entire matrix");
  memset(mtx.videoRam,0xAA,((Lightuino_NUMOUTS/8)+1)*Lightuino_NUMSRCDRVR);
  // You've got to keep calling loop to paint each scan line in the matrix
  for (int j=0;j<5000;j++) { mtx.loop();}

  Serial.println("  Turn off the entire matrix");
  mtx.clear(0);
 
  Serial.println("  Write Pixels");
  for(int x=0;x<Lightuino_NUMOUTS;x++)
    {
      for(int y=0;y<Lightuino_NUMSRCDRVR;y++)
        {
          mtx.pixel(x,y,1);
          for (int j=0;j<10;j++) { mtx.loop();}
        }
    }

  mtx.clear(0);

  Serial.println("  Letter Marquee");
  
  unsigned int cnt = 0;
  while(1)
    {
      cnt++;  
      //if ((cnt & 511)==0) memset(mtx.videoRam,0xff,((Lightuino_NUMOUTS/8)+1)*Lightuino_NUMSRCDRVR);
  
      // Print some text to the matrix
      // the api is print(x,y,string,LetterSpacing,Operation)
      // The "fancy" math just shifts the letters by one pixel for every cnt, and then after 
      // the width of a letter it resets the pixel shift and moves forward one character in the string
      mtx.print(0-(cnt%6),0,stringA+((cnt/6)%strlen(stringA)),1,DRAW);
      mtx.print(0-(cnt%6),8,stringB+((cnt/6)%strlen(stringB)),1,DRAW);
      for (int j=0;j<400;j++) { mtx.loop();}
      // Erase that same text
      mtx.print(0-(cnt%6),0,stringB+((cnt/6)%strlen(stringB)),1,ERASE);
      mtx.print(0-(cnt%6),8,stringA+((cnt/6)%strlen(stringA)),1,ERASE);

    }    
}

void loop(void)
{
  SinkOnOffDemo();
  SinkPwmDemo();
  SourceDriverDemo();
  //MatrixDemo(sinks);
  
  LightSensorDemo();
  IrDemo();
}

// This is a convenient function which illuminates the first and last LED on each side
// so you can find the pins on the board.  This sketch does not actually call this function,
// its just here for your use.
void pinFinder(void)
{
  while (1)
  {

  pwm.brightness[0] = 32;
  pwm.brightness[34] = 64;
  pwm.brightness[35] = 128;
  pwm.brightness[69] = 255;
  for (int i=0;i<10;i++) pwm.loop();
  }
}


/*? </verbatim></sketch></section>
*/

