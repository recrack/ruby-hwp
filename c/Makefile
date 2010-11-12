all: libhwp hwp

libhwp: libhwp.c libhwp.h
	gcc -c -fPIC -o libhwp.so libhwp.c

hwp: hwp.c
	gcc -o hwp hwp.c -L. -lhwp

clean:
	rm hwp libhwp.so
