

all: lightuino3.0.zip


lightuino3.0.zip: $(wildcard lightuino3_lib_dev/*) $(wildcard begin_here3/*) 
	rm -rf lightuino3
	mkdir -p lightuino3
	cp lightuino3_lib_dev/*.hxx lightuino3
	cp lightuino3_lib_dev/*.cpp lightuino3
	cp lightuino3_lib_dev/*.h lightuino3
	cp lightuino3_lib_dev/keywords.txt lightuino3
	cp lightuino3_lib_dev/INSTALL lightuino3
	cp -r begin_here3 lightuino3
	rm -rf lightuino3/begin_here3/.svn
	zip -r lightuino3.0.zip lightuino3

