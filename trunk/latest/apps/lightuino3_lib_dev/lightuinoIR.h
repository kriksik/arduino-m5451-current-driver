#ifndef LightuinoIR
#define LightuinoIR

// Most IRs differentiate a 1 vs a 0 by the length of a pulse.  In other words, a "1" may turn the IR LED "on" for twice as long as a "0".
// The IR LED is turned off to break up the bits.  This is not entirely intuitive where you might think that a 1 is the IR-LED being "on" and a 0 is it being "off".

// These constants define how long in microseconds a 1 is vs a 0.
// The variation is the fudge factor.  For example a variation of 2 means that the signal's length can vary by + or - 1/2 of the speced ideal time.
// For example given ZEROTIME of 600, and a VARIATION of 2, signals from 300-900 will be interpreted as a 0
#define IR_ZEROTIME 600UL   // Actually 600
#define IR_ONETIME  1200UL  // Actually 1200
#define IR_VARIATION 2UL

// Some IR protocols indicate the start of a new code by a very long pulse.  STARTTIME specifies this.
// Its not strictly necessary to define this because the quiettime can also split up pulses, but getting this correct
// will allow the system to correctly interpret rapid signal.
#define IR_STARTTIME 5000UL

// QUIETTIME speccs how long to wait with no pulses before deciding that the code is complete.
#define IR_QUIETTIME 30000UL

// To determine the bits, should I measure the length of a pulse (1) or the length of the silence between pulses (0).  Typically its the length of a pulse.
// You can determine this by plotting the waveform and seeing whether the pulse or the silence varies (that's the SIGNAL_STATE).
// Each non-signal portion will essentially the same width (except perhaps for preambles and suffixes). 

#define Lightuino_IR_CODEBUFLEN 4

class IrReceiver
  {
    public:
    static char pin;
    static unsigned long int zeroTimeMin;
    static unsigned long int zeroTimeMax;
    static unsigned long int oneTimeMin;
    static unsigned long int oneTimeMax;
    static unsigned long int startTime;
    static unsigned long int quietTime;
    static unsigned int      variation;
    static char signalState;
    static unsigned long int codes[Lightuino_IR_CODEBUFLEN];
    static char lastCode;
    static char firstCode;
    
    IrReceiver(unsigned long int ZeroTime=IR_ZEROTIME,unsigned long int OneTime=IR_ONETIME,unsigned long int StartTime=IR_STARTTIME,unsigned long int QuietTime=IR_QUIETTIME,unsigned int Variation=IR_VARIATION,char SignalState=-1,char pin=2);
    unsigned long int read();
    
    void sleepUntil(unsigned long int wakeCode);

    
    ~IrReceiver();
  };


#endif
