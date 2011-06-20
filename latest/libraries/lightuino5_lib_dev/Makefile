VERSION = 0.1

ArduinoSimDir := /me/code/arduinosim

Hfiles := $(wildcard *.h) $(wildcard $(ArduinoSimDir)/avr/*.h) $(wildcard $(ArduinoSimDir)/*.h)
Cfiles := $(wildcard *.cpp) $(wildcard *.c)
Ofiles := $(patsubst %.pde,%.o,$(patsubst %.c,%.o,$(patsubst %.cpp,%.o,$(Cfiles))))

# Library name is the name of the directory
LibName := $(notdir $(shell pwd))
noop := $(shell echo LIB $(LibName))
LibName := lib$(LibName).a

# Also build a sketch if it is in there
PdeFile := $(wildcard *.pde)
SimBin  :=  $(patsubst %.pde,%,$(PdeFile))

LINKLIB := ar rcs
CF := -c -DSIM -DSIM__AVR_ATmega328P__ -g -O0 -I. -I$(ArduinoSimDir)
LF := 

default: $(LibName) $(SimBin)

clean:
	rm *.o $(SimBin) $(LibName)

$(LibName): $(Ofiles)
	$(LINKLIB) $@ $^

%.a: $(Ofiles)
	$(LINKLIB) $@ $^

%.o: %.cpp $(Hfiles)
	g++ $(CF) -o $@ $<

%.o: %.c $(Hfiles)
	g++ $(CF) -o $@ $<

# Also build a sketch if it is in there
%: %.o %.pde $(LibName) $(ArduinoSimDir)/libArduinoSim.a
	g++ $(LF) -o $@ $< $(LibName) $(ArduinoSimDir)/libArduinoSim.a

#%.o: %.pde $(Hfiles) pdehdr.txt
#	cat pdehdr.txt $< > $(patsubst %.o,%.cxx,$@)
#	g++ $(CF) -o $@ $(patsubst %.o,%.cxx,$@)
#	rm $(patsubst %.o,%.cxx,$@)

%.o: %.pde $(Hfiles) pdehdr.txt
	g++ $(CF) -x c++ -o $@ $<
