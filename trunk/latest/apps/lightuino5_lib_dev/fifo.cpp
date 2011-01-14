#include "fifo.h"

void fifoPush(FifoBuf* ths, char c)
  {
  if ((ths->fend + 1) % FIFO_BUF_SIZE != ths->start) 
    {
      ths->buf[ths->fend] = c;
      ths->fend = (ths->fend + 1) % FIFO_BUF_SIZE;
    }
  else
    {
      // Buffer full
    }
    //fifoWrite(ths,&c,1);
  }

void fifoCtor(FifoBuf* ths)
{
  ths->start=0;
  ths->fend = 0;
}


void fifoWrite(FifoBuf* ths, char* c, unsigned char len)
{
  unsigned char i;
  for (i=0;i<len;i++)
    {
      fifoPush(ths,c[len]);
    }

}

void fifoPushStr(FifoBuf* ths, char* s)
  {
    while(*s!=0) { fifoPush(ths,*s); s++;}
  }

int fifoPeek(FifoBuf* ths)
{
  if (ths->fend == ths->start) return -1;
  return ths->buf[ths->start];
}

int fifoPop(FifoBuf* ths)
  {
  if (ths->fend != ths->start) 
      {        
      char temp = ths->buf[ths->start];
      ths->start = (ths->start + 1) % FIFO_BUF_SIZE;
      return(temp);
      }
      //otherwise, the buffer is empty; return an error code
  return 0xffff;   
  } 
