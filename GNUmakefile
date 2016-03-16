# GNU makefile starter
# Runs configuration then includes the common makefile.

config:=$(shell $(CC) -D O_VER=0.5 -I src/system -o a.o src/tools/make/configure.c; ./a.o; rm a.o)
include src/make/olang.make
