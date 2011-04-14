

all: lightuino3.0.zip lightuino5.1.zip


lightuino3.0.zip: $(wildcard lightuino3_lib_dev/*) $(wildcard ../apps/begin_here3/*) 
	rm -rf lightuino3
	mkdir -p lightuino3
	cp lightuino3_lib_dev/*.cpp lightuino3
	cp lightuino3_lib_dev/*.h lightuino3
	cp lightuino3_lib_dev/keywords.txt lightuino3
	cp lightuino3_lib_dev/INSTALL lightuino3
	cp -r ../apps/begin_here3 lightuino3
	rm -rf lightuino3/begin_here3/.svn
	zip -r lightuino3.0.zip lightuino3

lightuino5.1.zip: $(wildcard lightuino5_lib_dev/*) $(wildcard ../apps/begin_here5/*) 
	rm -rf lightuino5
	mkdir -p lightuino5
	cp lightuino5_lib_dev/*.cpp lightuino5
	cp lightuino5_lib_dev/*.c lightuino5
	cp lightuino5_lib_dev/*.h lightuino5
	cp lightuino5_lib_dev/*.inf lightuino5
	cp lightuino5_lib_dev/keywords.txt lightuino5
	cp lightuino5_lib_dev/INSTALL lightuino5
	cp -r ../apps/begin_here5 lightuino5
	rm -rf lightuino5/begin_here5/.svn
	zip -r lightuino5.1.zip lightuino5

