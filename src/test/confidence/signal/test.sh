source ../testenv.sh
voc signal.mod -m
./SignalTest x &
sleep 1
kill -2 $!
wait
source ../testresult.sh "Signal 2"
