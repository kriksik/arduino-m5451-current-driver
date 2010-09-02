/* Suntree -- a nightlight
 * Version 1.0  March 2010
 * Author: G. Andrew Stone
 * Released under the GPL V3 license (http://www.fsf.org)
 */

#include <avr/power.h>
#include <avr/sleep.h>
#include <avr/pgmspace.h>

#include <lightuino3.h>

char temp;

#ifdef LIGHTUINO3
LightuinoSink board(6,5,7,10);
#else
Lightuino board(6,5,7,10);
#endif
FlickerBrightness leds(board);


char rayLeds[] = { 
  35,36,38,39,41,45,44,43,47,48,49,52,0};
#define NUM_RAYS 12
char sunLeds[] = {
  55,56,57,58,59,60,0};
#define NUM_SUN 6

char center[] = {
  62,61,63};

char yellowLeds[] = { 
  35,37,39,40,46,48,52,57,58,59};
#define NUM_YELLOWS 10

char whiteLeds[] = { 
  44,42,47,53,55,60 };
#define NUM_WHITES 6

char redLeds[] = { 
  36,64,41,45,43,65,49,56,62 };
#define NUM_REDS 9

char pinkLeds[] = { 
  38,54 };
#define NUM_PINKS 2

char bigRays[] = { 
  39,40,64, 42,43,65, 52,53,54};
#define NUM_BIGRAYS 9

char rgbLed[] = {
  62,61,63};

#ifdef LIGHTUINO3
#define MINFLICK 300
#else
#define MINFLICK 17
#endif

#define SPDUP 1

//?<class name="RgbFader">
// This class fades RGB leds to make different colors
class RgbFader: 
public Ani
{
public:
  FlickerBrightness& leds;
  int delayTime;

  int cdown;
  int incr[3];
  int bres[3];
  int lim[3];
  int cur[3];
  char chan[3];

  RgbFader(FlickerBrightness& pleds, int pdelayTime, unsigned char red, unsigned char grn, unsigned char blu);

  virtual void erase(void);
  virtual void next(void);
  virtual void draw(void);
};
//?</class>

RgbFader::RgbFader(FlickerBrightness& pleds, int pdelayTime, unsigned char red, unsigned char grn, unsigned char blu):
leds(pleds)
{
  delayTime=pdelayTime;
  cdown = 0;
  chan[0] = red; 
  chan[1] = grn; 
  chan[2]=blu;

  for (char i=0;i<3;i++)
  {
    lim[i] = random(Lightuino_MAX_BRIGHTNESS-2)+1;
    bres[i] =0;
    cur[i] = leds.brightness[chan[i]];
    incr[i] = random(20000)+2000;
    if (lim[i]<cur[i]) incr[i] *= -1;
  }


}


void RgbFader::erase(void)
{
  for (char i=0;i<3;i++) leds.brightness[chan[i]] -= cur[i];
}

void RgbFader::next(void)
{
  erase();
  if (cdown>=delayTime)
  {
    cdown=0;
    for (char i=0;i<3;i++)
    {
      bres[i] += incr[i];
      /* Do not enable without slowing the loop way down by increasing delayTime
       Serial.print((int)cur[i]);
       Serial.print(" ");
       Serial.print((int)bres[i]);
       Serial.print(" ");
       Serial.print((int) lim[i]);
       Serial.print(" ");
       Serial.println((int)incr[i]);
       */
      // Note if lim == 0 or incr == 0 this is going to permanently loop.  So make sure that does not happen!
      while (bres[i]>lim[i]) { 
        bres[i] -= lim[i]; 
        cur[i]++;
      }
      while (bres[i]<0) { 
        bres[i] += lim[i]; 
        cur[i]--;
      }
      if (cur[i] == lim[i])
      {
        lim[i] = random(Lightuino_MAX_BRIGHTNESS-2)+1;
        incr[i] = random(20000)+2000;
        if (lim[i]<cur[i]) incr[i] *= -1;
      }          
    }
  }
  else cdown++;

  draw();
}

void RgbFader::draw(void)
{
  for (char i=0;i<3;i++) leds.brightness[chan[i]] += cur[i];

}


//?<class name="MultiFader">
//This class just lights LEDs sequentially from some start position to some end position.
//When it gets to the end it starts over.  Either direction is possible.
class MultiFader: 
public Ani
{
public:
  FlickerBrightness& leds;
  char* xlat;
  int numLeds;
  int delayTime;
  int intensityChange;

  int cdown;
  //int iamt;
  double iamt;
  double mulamt;

  MultiFader(FlickerBrightness& pleds, int pdelayTime,int pintensityChange,char* xlat, int numLeds);

  virtual void erase(void);
  virtual void next(void);
  virtual void draw(void);
};
//?</class>



MultiFader::MultiFader(FlickerBrightness& pleds, int pdelayTime,int pintensityChange,char* pxlat, int pnumLeds):
leds(pleds)
{
  xlat      = pxlat;
  numLeds   = pnumLeds;
  delayTime = pdelayTime&(~1);
  intensityChange = pintensityChange;
  cdown     = 0;
  double temp = delayTime/2;
  temp = 1.0/temp;

  mulamt = pow(intensityChange,temp);
  //float t = mulamt;
  //Serial.print("MULAMT: ");
  //Serial.println(t);
  iamt = mulamt;
  //iamt      = 0;
}

void MultiFader::erase(void)
{
  for(char i = 0;i<numLeds;i++)
  {
    int temp = iamt;
    if (temp<MINFLICK) temp=0;
    if (temp>=Lightuino_MAX_BRIGHTNESS-1) temp=(Lightuino_MAX_BRIGHTNESS-1);

    leds.brightness[xlat[i]] -= temp;
  }
}

void MultiFader::next(void)
{
  erase();

  if (cdown<(delayTime>>1))
  {
    //iamt += intensityChange;
    iamt *= mulamt;
    //float t = iamt;
    //Serial.print("IAMT: ");
    //Serial.println(t);

  }
  else
  {
    //iamt -= intensityChange;
    iamt /= mulamt;

  }
  cdown++;
  if (cdown >= delayTime) { 
    cdown=0; 
    iamt=mulamt; 
  }

  //Serial.println(iamt);
  draw();
}

void MultiFader::draw(void)
{
  for(char i = 0;i<numLeds;i++)
  {
    int temp = iamt;
    if (temp<MINFLICK) temp=0;
    if (temp>=Lightuino_MAX_BRIGHTNESS) temp=(Lightuino_MAX_BRIGHTNESS-1);
    //Serial.print("LED  VAL:  ");
    //Serial.print(xlat[i]);
    //Serial.println(temp);
    leds.brightness[xlat[i]] += temp;
  }
}




//?<class name="AniSweep">
//This class just lights LEDs sequentially from some start position to some end position.
//When it gets to the end it starts over.  Either direction is possible.
class Circler: 
public Ani
{
public:
  FlickerBrightness& leds;
  char* xlat;
  int numLeds;
  int delayTime;
  int intensityChange;

  int  cdown;
  char cpos;
  char ppos;
  char dir;

  int iamt[2];

  Circler(FlickerBrightness& pleds, int pdelayTime,int pintensityChange,char* xlat, int numLeds);

  virtual void erase(void);
  virtual void next(void);
  virtual void draw(void);
};
//?</class>

Circler::Circler(FlickerBrightness& pleds, int pdelayTime,int pintensityChange,char* pxlat, int pnumLeds):
leds(pleds)
{
  dir = 1;
  xlat      = pxlat;
  numLeds   = pnumLeds;
  delayTime = pdelayTime;
  intensityChange = pintensityChange;
  cdown = 0;
  cpos = dir;
  ppos = 0;
  // Fix the startup case
  //leds.brightness[xlat[ppos]] += intensityChange;
  iamt[0]=intensityChange*delayTime;
  iamt[1]=0;
}

void Circler::next(void)
{
  erase();
  if (cdown) 
  { 
    cdown--;
    iamt[0] -= intensityChange;
    iamt[1] += intensityChange;
  }
  else
  {
    cdown += delayTime;
    ppos   = cpos;
    cpos  += dir;
    if (cpos<0) cpos += numLeds;
    if (cpos>=numLeds) cpos -= numLeds; 
    iamt[0]=iamt[1];
    iamt[1]=0;
  } 
  draw();
}

void Circler::erase(void)
{
  leds.brightness[xlat[ppos]] -= iamt[0];  // If statement skips the startup case
  leds.brightness[xlat[cpos]] -= iamt[1];  // If statement skips the startup case
}

void Circler::draw(void)
{
  leds.brightness[xlat[ppos]] += iamt[0];
  leds.brightness[xlat[cpos]] += iamt[1];
}



void setup()
{
  //Start up the serial port
  Serial.begin(9600);
  //Signal the program start
  Serial.println("Lightuino SunTree v2.0");
}


void mydelay(int amt)
{
  delay(amt);
}


void loop()                     // run over and over again
{
  board.flags |= CCShield_FASTSET;  // fast set relies on AVR registers not digitalWrite, so may not work on some Arduino variants.
  board.setBrightness(255);


#if 0 
  if (1)
  {
    Serial.println("Light Check -- ALL ON");
    board.set(0xffffffffUL, 0xffffffffUL,0xff);      
    delay(2000);
  } 
  board.set(0x0UL, 0x0UL,0x0);   
#endif

  leds.minBrightness = MINFLICK;
  leds.StartAutoLoop(6000);
  //leds.StartAutoLoop();


  if (0)
  {
    Serial.println("Rays ON: ");

    for (int i=0;i<NUM_RAYS;i++)
    {
      Serial.println((int)rayLeds[i]);
      leds.brightness[rayLeds[i]]=(Lightuino_MAX_BRIGHTNESS-1);
      mydelay(500);
    }
    for (int i=0;i<NUM_RAYS;i++)
    {
      leds.brightness[rayLeds[i]]=0;
    }

  }



  if (0)
  {
    Serial.println("Individual Light Check");

    for (int i=0;i<70;i++)
    {
      leds.brightness[i]= (Lightuino_MAX_BRIGHTNESS-1);
      Serial.println(i);
      mydelay(50);
      //for (int j=0;j<1000;j++) leds.loop();
      leds.brightness[i]= 0;     
    }
  }


  Circler rays(leds,120,(Lightuino_MAX_BRIGHTNESS-30)/121,rayLeds,NUM_RAYS);
  Circler negrays(leds,79,(Lightuino_MAX_BRIGHTNESS-30)/80,rayLeds,NUM_RAYS);
  Circler sun(leds,219,(Lightuino_MAX_BRIGHTNESS-40)/220,sunLeds,NUM_SUN);
  sun.dir = -1;
  negrays.dir = -1;

  MultiFader yellows(leds,1000,Lightuino_MAX_BRIGHTNESS-MINFLICK,yellowLeds,NUM_YELLOWS);
  MultiFader reds(leds,700,(Lightuino_MAX_BRIGHTNESS-MINFLICK),redLeds,NUM_REDS);
  MultiFader whites(leds,2220,(Lightuino_MAX_BRIGHTNESS-MINFLICK),whiteLeds,NUM_WHITES);
  MultiFader pinks(leds,630,(Lightuino_MAX_BRIGHTNESS-MINFLICK),pinkLeds,NUM_PINKS);

  RgbFader rgb(leds, 2, rgbLed[0], rgbLed[1], rgbLed[2]);

  while(1)
  {
    if (1)
    {
      rays.draw(); 
      rgb.draw();
      yellows.draw(); 
      reds.draw(); 
      whites.draw(); 
      pinks.draw();
      Serial.println("color loop");
      for(int j=0;j<8000/SPDUP;j++)
      {

        rgb.next(); 
        yellows.next(); 
        reds.next(); 
        whites.next(); 
        pinks.next();

        if ((j&7)==0)  rays.next();

        mydelay(5);  
      }

      rgb.erase(); 
      yellows.erase(); 
      reds.erase(); 
      whites.erase(); 
      pinks.erase();
      rays.erase();
    }

    if(1)
    {  
      Serial.println("ray loop");
      rgb.draw(); 
      rays.draw(); 
      sun.draw(); 
      negrays.draw();
      for(int j=0;j<8000/SPDUP;j++)
      {

        rgb.next();
        rays.next(); 
        sun.next(); 
        negrays.next();
        mydelay(5);
        negrays.next();
        mydelay(10); 
      }
      rgb.erase(); 
      rays.erase(); 
      sun.erase(); 
      negrays.erase();
    }
  }

}



