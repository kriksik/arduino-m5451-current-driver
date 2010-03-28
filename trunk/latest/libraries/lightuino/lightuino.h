/*? <section name="lightuino">
 * Lightuino, CCShield, and M5451 LED driver
 * Version 2.0 Author: G. Andrew Stone
 * Created March, 2009
 * Released under the MIT license (http://www.opensource.org/licenses/mit-license.php)
 *
 * This is an Arduino Library, to install see: http://www.arduino.cc/en/Hacking/LibraryTutorial
 * Quick Installation instructions:
 * Copy this file and the CCShield.h file to a new directory called
 * "CCShield" in the hardware\libraries directory in your arduino installation.  
 * Then restart the Arduino IDE.
 *
 * For example: 
 * mkdir c:\arduino-0017\hardware\libraries\CCShield
 * copy *.* c:\arduino-0017\hardware\libraries\CCShield
 */

#ifndef CCSHIELD_H
#define CCSHIELD_H


//#include "WConstants.h"
#include "avr/pgmspace.h"
#include <inttypes.h>

//?<section name="constants">

//?<const name="M5451_NUMOUTS">The number of output pins on the M5451 chip</const>
#define M5451_NUMOUTS 35

//?<const name="CCShield_NUMOUTS">The number of output pins on the shield board</const>
#define CCShield_NUMOUTS 70
//?<const name="Lightuino_NUMOUTS">The number of output pins on the Lightuino board</const>
#define Lightuino_NUMOUTS 70

//?<const name="CCShield_FASTSET">Flag selecting the algorithm used to send data to the M5451 chips</const>
#define CCShield_FASTSET 1
//?<const name="CCShield_BY32">Flag selecting the mapping between memory bits and M5451 output lines</const>
#define CCShield_BY32 2

//?<const name="Lightuino_FASTSET">Flag selecting the algorithm used to send data to the M5451 chips</const>
#define Lightuino_FASTSET 1
//?<const name="Lightuino_BY32">Flag selecting the mapping between memory bits and M5451 output lines</const>
#define Lightuino_BY32 2

//? <const name="CCShield_MAX_BRIGHTNESS">Maximum number of gradations of brightness</const>
#define CCShield_MAX_BRIGHTNESS 256
//? <const name="Lightuino_MAX_BRIGHTNESS">Maximum number of gradations of brightness</const>
#define Lightuino_MAX_BRIGHTNESS 256

//? <const name="Lightuino_MIN_INTENSITY">
// This is the mininum intensity to set for flickerless viewing.  It is subjective, and also depends upon
// how much time you are spending doing other things.  The LED will be OFF for MIN_INTENSITY/MAX_BRIGHTNESS amount of time
// When this is (say) 1/256, you can see the LED flicker since it only blinks once per 256 loop iterations!
// Strangely, the amount of visible flicker also depends upon how much current you put across the LEDs (ie. the "brightness" selector)</const>
#define CCShield_MIN_INTENSITY 17  
#define Lightuino_MIN_INTENSITY 17  
//?</section>

//?<section name="classes">

/*? <class name="Lightuino">
   This class provides the basic functions to control the M5451 chip; in particular, it drives 2 chips simultaneously
   which is what the CCShield and Lightuino boards are populated with.
*/
class Lightuino
 {
  public:
     
  //? <var name="flags" type="uint8_t">
  // What algorithm to use to clock the data out to the M5451 chips.  
  // You may choose a Lightuino_FASTSET which works only with 88,168 or 328 chipsets.  
  // If fastset is not selected, the code should work with any arduino clone (it uses digitalWrite).
  // However the speed may not be fast enough to PWM the Leds without a lot of flickering.
  // Lightuino_BY32 selects how the parameters in the set() call map to output lines.  In the BY32 case, the first
  // parameter to set handles lines 0-31 on the left connector, the second sets lines 0-31 on the right connector,
  // and the third parameter handles the leftover 6 lines.
  // If BY32 is NOT set, the parameters to the set() call are handled as if they were a single continuous bitmap.</var>
  uint8_t flags;
  //? <var name="clockPin"> What pin to use to as the M5451 clock (any digital pin can be selected on the board by solder blob short)</var>
  uint8_t clockPin;
  //? <var>What pin to use to to control brightness (any digital pin can be selected on the board by solder blob short)
  // note that to make brightness work, use a jumper to select software controller brightness instead of resistor controlled. </var>
  uint8_t brightPin;

  //? <var>What pins to use to send serial data to each M5451 (need 1 pin for each chip)
  // (any digital pin can be selected on the board by solder blob short)</var>
  uint8_t serDataPin[2];
  
  //? <ctor>Constructor takes all of the pins needed.</ctor>
  Lightuino(uint8_t clockPin,uint8_t serDataPin1,uint8_t serDataPin2,uint8_t brightPin);
  
  //? <method>Turn on/off certain lines, using direct register access -- may not work on Arduino variants!
  // Parameters a,b,c are a bitmap; each bit corresponds to a particular M5451 output
  // The first 70 bits are used (i.e. all of parameter a and b, and just a few bits in parameter c.</method>
  void set(unsigned long int a, unsigned long int b, unsigned long int c);
      
  //? <method>The same set function conveniently taking an array</method>
  void set(unsigned long int a[3]);

  //? <method>The same set function conveniently taking a byte array (should be 9 bytes long)</method>
  void set(unsigned char* a);

  //? <method>Turn on/off certain lines, using direct register access -- may not work on Arduino variants!
  // Parameters a,b,c are a bitmap; each bit corresponds to a particular M5451 output
  // The first 70 bits are used (i.e. all of parameter a and b, and just a few bits in parameter c</method>
  void fastSet(unsigned long int a, unsigned long int b, unsigned long int c);
      
  //? <method>The same set function conveniently taking an array</method>
  void fastSet(unsigned long int a[3]);

  // <method>
  // Reorder the set bits as:
  // input[0] -> Chip 0 lines 0->31
  // input[1] -> Chip 1 lines 0->31
  // input[2] -> bits 0-2 chip 0 lines 32-34.  bits 3-5 chip 1 lines 32 - 34.</method>
  void fastSetBy32(unsigned long int input[3]);
  void fastSetBy32(unsigned long int left, unsigned long int right, unsigned long int overflow);

  // <method>Turn on/off certain lines, using digitalWrite.
  // Parameters a,b,c are a bitmap; each bit corresponds to a particular M5451 output
  // The first 70 bits are used (i.e. all of parameter a and b, and just a few bits in parameter c</method>
  void safeSet(unsigned long int a, unsigned long int b, unsigned long int c);
  void safeSet(unsigned long int a[3]);
  
  // <method>Set the overall brightness using the M5451 brightness selection (assuming its under software control)</method>
  void setBrightness(uint8_t b);
  
  private:
  int mydelay(unsigned long int clk);
};
//?</class>

//?<class>
class CCShield:public Lightuino
{
 public:
  //?<ctor>Constructor takes all of the pins needed.</ctor>
 CCShield(uint8_t clockPin,uint8_t serDataPin1,uint8_t serDataPin2,uint8_t brightPin):Lightuino(clockPin,serDataPin1,serDataPin2,brightPin) {};

};
//?</class>


//?<class name="FlickerBrightness">
// The FlickerBrightness class changes the apparent brightness of individual LEDs by turning them off and on rapidly.
// This technique is called PWM (pulse-width modulation) and if done fast enough, the fact of persistence of vision means
// that the flickering is not seen.
// The "loop" function must be called periodically and rapidly.  If the LEDs appear to flicker, "loop" should be called more
// often (or do not make the LEDs that dim).
class FlickerBrightness
{
  public:
  //? <ctor>The constructor takes a Lightuino object</ctor>
  FlickerBrightness(Lightuino& brd);
  ~FlickerBrightness() {StopAutoLoop();}
  
  //? <method>This function performs a marquee function by shifting which intensity corresponds with which actual output in Lightuino</method>
  void shift(int amt=1) 
    { 
    offset+=amt; 
    if (offset>=M5451_NUMOUTS) offset -=Lightuino_NUMOUTS; 
    else if (offset<0) offset +=Lightuino_NUMOUTS; 
    }
    
  //? <method>Call this function periodically and rapidly to blink the LEDs and therefore create the illusion of brightness</method>
  void loop(void);
  
  //? <method> Call the loop() function automatically in the background...</method>
  void StartAutoLoop(void);
  
  //? <method> Stop automatic looping</method>
  void StopAutoLoop(void);
  
  //? <var>Set this variable to the desired brightness, indexed by the LED you want to control</var>
  int brightness[Lightuino_NUMOUTS];
  
  //? <var>Set this variable to force a cutoff to zero below this brightness level.  This stops a perception of flickering</var>
  int minBrightness;
  
  // Private
  int bresenham[Lightuino_NUMOUTS];
  int offset;
  Lightuino& brd;
  FlickerBrightness* next;
};
//?</class>

//? <class>The ChangeBrightness class modifies the brightness of the LEDs smoothly and linearly through a desired
// brightness range.
class ChangeBrightness
{
  public:
  //?<method> Pass the constructor a FlickerBrightness object and also a callback (optional).  When this class finished moving a LED
  // to the desired brightness, it will call the callback so you can program a new intensity target in.</method>
  ChangeBrightness(FlickerBrightness& thebrd, void (*doneCallback)(ChangeBrightness& me, int led)=0);
  
  /*?<method> Transition the light at index 'led' to intensity over count iterations</method> */
  void set(uint8_t led, uint8_t intensity, int count);
  
  //?<method> Call loop periodically and rapidly to change the brightness.  This function calls FlickerBrightness.loop(), so
  // it is unnecessary for you to do so.</method>
  void loop(void);
 
  // semi-private variables 
  FlickerBrightness& brd;
  int  change[Lightuino_NUMOUTS];
  int  count[Lightuino_NUMOUTS];
  uint8_t destination[Lightuino_NUMOUTS];  
  int  bresenham[Lightuino_NUMOUTS];
  void (*doneCall)(ChangeBrightness& me, int led);
};
//?</class>

//?<class>
//This class allows you to define a bit pattern in FLASH memory and then it will run through that pattern.
//A "pattern-compiler" Google-gadget exists <a href="http://code.google.com/p/arduino-m5451-current-driver/wiki/LedAnimationGenerator">here</a>
class AniPattern
{
  public:
  AniPattern(Lightuino& shld, prog_uchar* anim,prog_uint16_t* delayLst, int total_frames): shield(shld) {flags=0; delays=delayLst; ani=anim; numFrames=total_frames; curFrame=0; curDelay=0; anidir=1;}

  Lightuino& shield;
  int curFrame;
  int curDelay;
  int numFrames;
  int anidir;
  uint8_t flags;
  prog_uchar* ani;
  prog_uint16_t* delays;
  
  void setBackForth(uint8_t yes=1) { if (yes) flags |= 1; else flags &= ~1; }
  void setReverse(uint8_t yes =1) { if (yes) anidir = -1; else anidir = 1; }
  
  void setPos(int i) { if (i<numFrames) curFrame = i;}
  void next(void);
};
//?</class>

/*?<class name="Ani">
  This is an abstract base class describing the state of an animation.  
  This subsystem attempts to solve the problem of animation reuse.  There is a problem with reusing animations -- you
  can only run a single one at a time because the Arduino is not threaded. 
  But with Ani objects you call "loop" to tick forward one hop in the animation.  Therefore your code can call "loop"
  on multiple Ani objects within your main loop to run multiple animations simultaneously.
  <html>
  A typical use is shown below.  In the first line the object is created.
  Then it is drawn for the first time.  Next we enter the animation loop.  Finally it is erased.
  <pre>
     AniWiper w(leds,0,32,100,CCShield_MAX_BRIGHTNESS/2-1);
     
     w.draw();
     for (int i=0;i!=100;i++)
     {
       w.loop();
       mydelay(100-i);
     }
     w.erase();
  </pre>
  </html>
*/
class Ani
  {
    public:
    Ani* lst;
    //?<method> Move forward one frame</method>
    virtual void next(void);
    //?<method>Undo a light setting</method>
    virtual void erase(void);
    //?<method>Do a light setting</method>
    virtual void draw(void);   

    //?<method> Execute a single "step".  This consists of: erase(), next(), draw(), and is the function you should call within your loop.</method>
    virtual void loop(void);
  };
//?</class>

//?<class name="AniSweep">
//This class just lights LEDs sequentially from some start position to some end position.
//When it gets to the end it starts over.  Either direction is possible.
class AniSweep: public Ani
{
  public:
    FlickerBrightness& leds;
    char start, end;
    char delayTime;
    int intensityChange;
    
    char cpos;
    char dir;
    
    AniSweep(FlickerBrightness& pleds, char pstart, char pend, char pdelayTime,int pintensityChange);
    
    virtual void erase(void);
    virtual void next(void);
    virtual void draw(void);
};
//?</class>

//?<class name="AniWiper">
//This class just lights LEDs sequentially from some start position to some end position.
//But unlike <ref>AniSweep</ref> when it gets to the end turns around and goes back (like a windshield wiper).
class AniWiper: public Ani
  {
    public:
    FlickerBrightness& leds;
    char start, end;
    char delayTime;
    int intensityChange;
    
    char cpos;
    char dir;
    AniWiper(FlickerBrightness& pleds, char pstart, char nleds, char pdelayTime,int pintensityChange);
      
    virtual void erase(void);
    virtual void next(void);
    virtual void draw(void);
  };
//?</class>

//?</section>

//?<section name="functions">
// <fn>This function sets a particular bit by index in a bitmap contained in parameters a,b,c
// you can then pass these into the Lightuino "set" function. </fn>
void setbit(unsigned char offset,unsigned long int* a, unsigned long int* b, unsigned char* c);

//? <fn>This function clears a particular bit by index in a bitmap contained in parameters a,b,c
// you can then pass these into the Lightuino "set" function. </fn>
void clearbit(unsigned char offset,unsigned long int* a, unsigned long int* b, unsigned char* c);

//? <fn>This function draws the current frame of all the animations in the passed Ani tree</fn>
void AniDraw(Ani& pani);
//? <fn>This function moves to the next frame of all the animations in the passed Ani tree</fn>
void AniNext(Ani& pani);
//? <fn>This function erases the current frame of all the animations in the passed Ani tree</fn>
void AniErase(Ani& pani);

//? <fn>This function does an Erase/Next/Draw triplet all the animations in the passed Ani tree</fn>
void AniLoop(Ani& pani);

//?</section>

//?</section>
#endif
