#define FIFO_BUF_SIZE 16

typedef struct
{
  char buf[FIFO_BUF_SIZE];
  unsigned char start;
  unsigned char fend;
} FifoBuf;

extern int fifoPeek(FifoBuf* ths);
extern void fifoPush(FifoBuf* ths, char c);
extern void fifoCtor(FifoBuf* ths);
extern void fifoWrite(FifoBuf* ths, char* c, unsigned char len);
extern void fifoPushStr(FifoBuf* ths, char* s);
extern int fifoPop(FifoBuf* ths);
