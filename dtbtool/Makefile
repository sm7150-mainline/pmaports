CFLAGS=-O2 -g -Wall
CC=gcc
PROGNAME=dtbtool

all: dtbtool

%.o: %.c
	$(CC) $(CFLAGS) -c $<

dtbtool: dtbtool.o
	$(CC) -g -o dtbtool dtbtool.o

clean:
	rm -f *.o dtbtool
