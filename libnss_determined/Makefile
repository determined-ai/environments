INPUTS=src/parse.c src/passwd.c src/shadow.c src/group.c
OUTPUT=libnss_determined.so.2

CC=gcc
CFLAGS=-Wall -Wextra -Wswitch-enum -Wsign-conversion -Wformat

all: mini

install:
	cp $(OUTPUT) /lib

.PHONY: test
test:
	test/integration_test.sh

mini:
	gcc -fPIC -shared -o libnss_determined.so.2 -Wl,-soname,libnss_determined.so.2 libnss_determined.c

clean:
	rm -f $(OUTPUT)
