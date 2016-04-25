set -e
export PATH=$1/bin:$PATH
export DYLD_LIBRARY_PATH=$1/lib:$DYLD_LIBRARY_PATH
rm -f *.o *.obj *.exe *.sym *.c *.h signal
voc signal.mod -m
./SignalTest x &
sleep 1
kill -2 $!
wait
read RESULT <result
if [ "$RESULT" != "Signal 2" ]; then echo signal test incorrect result "$RESULT"; exit 1;fi
