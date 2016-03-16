# BSD makefile starter
# Runs configuration then includes the common makefile.

config!=$(CC) -D O_VER=0.5 -I src/system -o a.o src/tools/configure.c; ./a.o; rm a.o
include src/olang.make
