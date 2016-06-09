# '.' this from indiviual test.sh files
sed -i .bak 's/\r$//' result
if diff expected result
then printf "PASSED: $PWD\n\n"
else printf "FAILED: $PWD\n\n"; exit 1
fi
