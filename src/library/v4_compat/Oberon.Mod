MODULE Oberon;

(* this version should not have dependency on graphics -- noch *)

  IMPORT Platform, Texts, Args, Out := Console;

  TYPE
    ParList* = POINTER TO ParRec;

    ParRec* = RECORD
    (*  vwr*: Viewers.Viewer;
      frame*: Display.Frame;*)
      text*: Texts.Text;
      pos*: LONGINT
    END;

  VAR

    Log*: Texts.Text;
    Par*: ParList; (*actual parameters*)
    W:    Texts.Writer;
    OptionChar*: CHAR;
  
  (*clocks*)

  PROCEDURE GetClock* (VAR t, d: LONGINT);
  BEGIN Platform.GetClock(t, d)
  END GetClock;

  PROCEDURE Time* (): LONGINT;
  BEGIN 
     RETURN Platform.Time()
  END Time;

  PROCEDURE PopulateParams;
  VAR 
    W:   Texts.Writer;
    i:   INTEGER;
    str: ARRAY 32 OF CHAR;
  BEGIN

    i := 1; (* skip program name *)
    Texts.OpenWriter(W);

    REPEAT
    IF i < Args.argc THEN
       Args.Get(i, str);
       Texts.WriteString(W, str);
       Texts.WriteString(W, " ");
    END;
    INC(i)
    UNTIL i >= Args.argc;

    Texts.Append (Par^.text, W.buf);

  END PopulateParams;

(*
  PROCEDURE DumpLog*;
  VAR R : Texts.Reader;
      ch : CHAR;
  BEGIN
     Texts.OpenReader(R, Log, 0);

     REPEAT
      Texts.Read(R, ch);
      Out.Char(ch); 
   UNTIL R.eot;
  END DumpLog;
*)

PROCEDURE TextToString(VAR T : Texts.Text; VAR string : ARRAY OF CHAR);
VAR 
  R:   Texts.Reader;
  ch:  CHAR;
  i:   LONGINT;
  len: LONGINT;
BEGIN
   COPY("", string);
   Texts.OpenReader(R, T, 0);
   len := T.len;
   IF len > LEN(string)-1 THEN len := LEN(string)-1 END;
   i := 0;
   WHILE Texts.Pos(R) < len DO
      Texts.Read(R, ch);
      string[i] := ch;
      INC(i);
   END;
   string[i] := 0X;
END TextToString;

PROCEDURE DumpLog*;
VAR s : POINTER TO ARRAY OF CHAR;
BEGIN
   NEW(s, Log.len + 1);
   COPY("", s^);
   TextToString(Log, s^);
   Out.String(s^); Out.Ln;

   NEW(Log);
   Texts.Open(Log, "");
END DumpLog;

BEGIN
   NEW(Par);
   NEW(Par.text);
   Par.pos := 0;
   OptionChar := '-';
   Texts.Open(Par.text, "");
   PopulateParams;
   NEW(Log);
   Texts.Open(Log, "");
END Oberon.
