#include "WProgram.h"
#include "lightuinoUsb.h"
#include "spi.h"

char LightuinoUSB::available(void)
{
  if (spiRcv.fend == spiRcv.start) xfer(0xff);
  return (spiRcv.fend != spiRcv.start);
}

int LightuinoUSB::peek(void)
{
  return fifoPeek(&spiRcv);
}

void LightuinoUSB::flush(void)
{
}

int LightuinoUSB::read(void)
{
  return fifoPop(&spiRcv);
}


void LightuinoUSB::end()
  {
  disable_spi();
  }

void LightuinoUSB::begin()
  {
    slaveSelectPin = 10;
    // set the slaveSelectPin as an output:
    pinMode (slaveSelectPin, OUTPUT);
    digitalWrite(slaveSelectPin,LOW);
    fifoCtor(&spiRcv);
    setup_spi(SPI_MODE_0, SPI_MSB, SPI_NO_INTERRUPT, SPI_MSTR_CLK8);
  }

void LightuinoUSB::print(unsigned long int num,char base)
{
  char buf[(sizeof(unsigned long int) * 8)+1];
  unsigned char i=(sizeof(unsigned long int) * 8);

  buf[i] = 0;
  while (num)
    {
      unsigned char temp = (num % base);
      i--;
      buf[i] = (temp<10) ? temp+'0': temp+'A'-10;
      num /= base;
    }
  print(&buf[i]);
}


void LightuinoUSB::print(char* str)
{
  while(*str!=0)
    {
      xfer(*str);
      delayMicroseconds(200);
      str++;
    }
}

void LightuinoUSB::println(char* str)
{
  print(str);
  //xfer('\r');
  xfer('\n');
}

void LightuinoUSB::xfer(char s)
{
  uint8_t in = send_spi(s);
  if (in != 0xFF) 
    {
      fifoPush(&spiRcv, in);
      //Serial.print("spi rcvd");
      //Serial.println((int) in);
    }
}


LightuinoUSB Usb;
