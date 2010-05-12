#include <Wire.h>
//#include <SoftwareSerial.h>
#include <HardwareSerial.h>
#include "i2c.h"

I2c::I2c(unsigned char slaveAddr)
{
  myAddr = slaveAddr;
}

void I2c::begin(unsigned char slaveAddr)
{
  Serial.println("i2c begin");
  myAddr = slaveAddr;
  Wire.begin(); 
}



    // Write bytes into the i2c
unsigned char I2c::write(unsigned char deviceAddress,unsigned char* buf, int length)
  {
    Wire.beginTransmission(deviceAddress);
    for (int i=0;i<length;i++) Wire.send(buf[i]);
    Wire.endTransmission();
  }
    
unsigned char I2c::writeAddrWriteData(unsigned char deviceAddress, unsigned char addr, const unsigned char* buf, int length)
  {
    Wire.beginTransmission(deviceAddress);
    Wire.send(addr);
    for (int i=0;i<length;i++) Wire.send(buf[i]);
    Wire.endTransmission();
  }
  
unsigned char I2c::writeAddrReadData(unsigned char deviceAddress, unsigned char addr, unsigned char* buf, int length)
  {
    Wire.requestFromAt((unsigned char)deviceAddress,(unsigned char)addr,(unsigned char)length);
    for (int i=0;i<length;i++,buf++) *buf = Wire.receive();
  }

I2c i2c;
