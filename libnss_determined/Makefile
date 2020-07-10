INPUTS := src/parse.c src/util.c src/passwd.c src/shadow.c src/group.c
OUTPUT := libnss_determined.so.2

CC := gcc
CFLAGS := -Wall -Wextra -Wswitch-enum -Wsign-conversion -Wformat -Werror

all: $(OUTPUT)

install:
	cp $(OUTPUT) /lib

$(OUTPUT): Makefile src/libnss_determined.h $(INPUTS)
	$(CC) $(INPUTS) -o $@ $(CFLAGS) -fPIC -shared -Wl,-soname,$@

test/unit_test: Makefile src/libnss_determined.h $(INPUTS) test/unit_test.c
	$(CC) $(INPUTS) test/unit_test.c -o $@ $(CFLAGS) -I./src -g

.PHONY: test
test: test/unit_test
	test/unit_test
	test/integration_test.sh

.PHONY: fmt
fmt:
	clang-format -i src/*.c src/*.h test/*.c

clean:
	rm -f $(OUTPUT) test/unit_test
