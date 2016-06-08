# '.' this from indiviual test.sh files
if diff --strip-trailing-cr expected result
then printf "PASSED: $PWD\n\n"
else printf "FAILED: $PWD\n\n"; exit 1
fi
#read EXPECTED <expected
#read RESULT <result
#if [ "$RESULT" != "$EXPECTED" ];
#then printf "FAILED: $PWD, incorrect result \"$RESULT\"\n"; diff expected result; exit 1;
#else printf "PASSED: $PWD\n\n"
#fi
