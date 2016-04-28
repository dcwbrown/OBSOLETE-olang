# '.' this from indiviual test.sh files
read RESULT <result
if [ "$RESULT" != "$1" ];
then printf "FAILED: $PWD, incorrect result \"$RESULT\"\n\n"; exit 1;
else printf "PASSED: $PWD\n\n"
fi
