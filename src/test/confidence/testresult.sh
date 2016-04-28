# '.' this from indiviual test.sh files
read EXPECTED <expected
read RESULT <result
if [ "$RESULT" != "$EXPECTED" ];
then printf "FAILED: $PWD, incorrect result \"$RESULT\"\n"; diff expected result; exit 1;
else printf "PASSED: $PWD\n\n"
fi
