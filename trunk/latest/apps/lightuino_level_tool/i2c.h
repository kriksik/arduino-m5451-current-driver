#ifndef i2c_H
#define i2c_H

// This class defines a basic i2c interface -- you should implement it specifically for your hardware
typedef enum
{
  I2cResultUnknown = 0,
  I2cOk            = 1
};


class I2c
  {
    unsigned char myAddr;

    public:
    I2c(unsigned char slaveAddr=0xff);  
    
    void begin(unsigned char slaveAddr=0xff);
        
    // High level i2c APIs -- should work for 99% of the chips.  Please use as they are more efficient than DIY.
    // Write bytes into the i2c
    unsigned char write(unsigned char deviceAddress,unsigned char* buf, int length);
    unsigned char writeAddrWriteData(unsigned char deviceAddress, unsigned char addr, const unsigned char* buf, int length);
    unsigned char writeAddrReadData(unsigned char deviceAddress, unsigned char addr, unsigned char* buf, int length);    

    unsigned char writeAddrWriteData(unsigned char deviceAddress, unsigned char regAddress, const unsigned char value)
      {
        writeAddrWriteData(deviceAddress, regAddress,&value,1);
      }
    unsigned char writeAddrReadData(unsigned char deviceAddress, unsigned char regAddress)
      {
        unsigned char temp=0xFF;
        writeAddrReadData(deviceAddress, regAddress,&temp,1);
        return temp;
      }
  };
  
  
extern I2c i2c;

#endif
