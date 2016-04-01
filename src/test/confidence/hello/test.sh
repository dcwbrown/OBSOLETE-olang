set -eu
export MAIN=hello
rm -f *.o *.obj *.exe *.sym *.c *.h $MAIN
"$1" $MAIN.mod -m
./$MAIN
