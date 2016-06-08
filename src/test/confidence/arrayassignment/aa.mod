MODULE aa;
IMPORT Console;

CONST teststring = "1st 10 ch 2nd 10 ch 3rd 10 ch";

VAR
  a10: ARRAY 10 OF CHAR;
  a20: ARRAY 20 OF CHAR;
  a30: ARRAY 30 OF CHAR;

BEGIN
  Console.String(teststring); Console.Ln;
  a30 := teststring; Console.String(a30); Console.Ln;
  COPY(a30, a20);    Console.String(a20); Console.Ln;
  COPY(a30, a10);    Console.String(a10); Console.Ln;
  a20 := a30;        Console.String(a20); Console.Ln;
  a10 := a30;        Console.String(a10); Console.Ln;
END aa.
