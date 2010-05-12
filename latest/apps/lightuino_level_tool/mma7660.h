#include "i2c.h"

enum
{
 UnknownPos = 0,
 // BackFront values
 FaceUp = 1,
 FaceDown = 2,

 // Tilt values
 LandscapeLeft=1,
 LandscapeRight=2,
 UpsideDown=5,
 RightsideUp=6

};

typedef struct
{
 unsigned char face:2;
 unsigned char tilt:3;
 unsigned char tap:1;
 unsigned char badData:1;
 unsigned char shake:1;
} TiltTap;

class Acceleration
{
 public:
 char x;
 char y;
 char z;
};

class Mma7660
{
  public:
  Mma7660();
  void begin();
  unsigned char getTiltTap(TiltTap& tt);
  Acceleration getXYZ();
};

extern Mma7660 accel;

