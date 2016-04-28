source ../testenv.sh
voc hello.mod -m
./hello >result
source ../testresult.sh "Hello."
