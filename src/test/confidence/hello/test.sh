set -e
export PATH=$1/bin:$PATH
export DYLD_LIBRARY_PATH=$1/lib:$DYLD_LIBRARY_PATH
rm -f *.o *.obj *.exe *.sym *.c *.h signal
voc hello.mod -m
./hello
