#ifndef lightuinoPwmH
#define lightuinoPwmH

#include "lightuino.h"

// #define SAFEMODE

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
  //int bresenham[Lightuino_NUMOUTS];
  int offset;
  Lightuino& brd;
  FlickerBrightness* next;
};
//?</class>

#define LightuinoPwm FlickerBrightness

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

#endif
