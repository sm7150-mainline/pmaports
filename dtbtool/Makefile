CFLAGS=-O2 -g -Wall
CC=gcc
PROGNAME=dtbTool

all: $(PROGNAME)

%.o: %.c
	$(CC) $(CFLAGS) -c $<

$(PROGNAME): dtbtool.o
	$(CC) -g -o $(PROGNAME) dtbtool.o

clean:
	rm -f *.o $(PROGNAME)
