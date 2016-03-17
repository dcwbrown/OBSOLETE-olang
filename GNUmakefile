# GNU makefile starter
# Runs configuration then includes the common makefile.

config:=$(shell $(CC) -I src/system -o a.o src/tools/make/configure.c; ./a.o; rm a.o)
include src/tools/make/olang.make
