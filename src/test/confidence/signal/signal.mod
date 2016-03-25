(* Test that interrupt and quit are handled correctly. *)
MODULE SignalTest;
IMPORT Console, Platform;

PROCEDURE handle(signal: INTEGER);
BEGIN
  Console.Ln; Console.String("Signal: "); Console.Int(signal,1); Console.Ln
END handle;

PROCEDURE Take5(i: INTEGER);
BEGIN
  WHILE i > 0 DO
    Console.Int(i,2); Console.Flush(); Platform.Delay(1000); DEC(i)
  END;
  Console.Ln;
END Take5;

BEGIN
  Platform.SetInterruptHandler(handle);
  Platform.SetQuitHandler(handle);
  Take5(10);
END SignalTest.