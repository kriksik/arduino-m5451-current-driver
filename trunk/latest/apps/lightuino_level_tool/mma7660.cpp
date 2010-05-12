#include <Wire.h>
#include <HardwareSerial.h>
#include "i2c.h"
#include "mma7660.h"

#define MMA7660i2c (0x4c)

// Registers
#define MMA7660_X 0
#define MMA7660_Y 1
#define MMA7660_Z 2
#define MMA7660_TILT 3
#define MMA7660_SRST 4
#define MMA7660_SPCNT 5
#define MMA7660_INTSU 6
#define MMA7660_MODE 7
#define MMA7660_SR 8
#define MMA7660_PDET 9
#define MMA7660_PD 10

Mma7660::Mma7660() {}

void Mma7660::begin()
  { 
    Serial.println("begin Mma7660");
    i2c.writeAddrWriteData(MMA7660i2c, MMA7660_MODE, 0x9); // B00001001
  }

unsigned char  Mma7660::getTiltTap(TiltTap& tt)
{
  unsigned char* data = (unsigned char*) &tt;
  *data=0;
  do
    {       
      i2c.writeAddrReadData(MMA7660i2c,MMA7660_TILT,data,1);
      Serial.println("reload tilt");
    } while (tt.badData);  // reload the damn thing it is bad
  return *data;
}

Acceleration Mma7660::getXYZ()
{
  unsigned char val[3];
  val[0] = val[1] = val[2] = 64;

  i2c.writeAddrReadData(MMA7660i2c,MMA7660_X, val, 3);

  // Check to make sure we have good values for all items
  for(int i=0;i<3;i++)
    {
      while (val[i]>63)  // reload the damn thing it is bad
        {
          val[i] = i2c.writeAddrReadData(MMA7660i2c,MMA7660_X+i);
          Serial.println("reload tilt");
        }
    }
 
  // transform the 7 bit signed number into an 8 bit signed number.
  Acceleration ret;
  ret.x = ((char)(val[0]<<2))/4;
  ret.y = ((char)(val[1]<<2))/4;
  ret.z = ((char)(val[2]<<2))/4;
  return ret;
}

Mma7660 accel;

