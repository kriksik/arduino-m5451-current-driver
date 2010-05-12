
#include "lightuinoLightSensor.hxx"
#include "wiring.h"

LightSensor::LightSensor(unsigned char panaPin):pin(panaPin) {}    

int LightSensor::read(void) { return analogRead(pin); };    

