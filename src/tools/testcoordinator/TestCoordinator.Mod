MODULE TestCoordinator;

(*
Listens for client test machines, telling them when to start tests and recording
status and log data that they send.
Also listens to command machine that says when to start a new set of tests.
*)

IMPORT IP, Platform, SYSTEM, Console, Strings;

CONST ListenPort = "2055";

VAR
  MaxSocket: LONGINT;
  Listener:  LONGINT;
  Connected: ARRAY IP.FDcount OF BOOLEAN;
  Waiting:   ARRAY IP.FDcount OF BOOLEAN;
  Underway:  ARRAY IP.FDcount OF BOOLEAN;



(* Console output convenience APIs *)

PROCEDURE cs (s: ARRAY OF CHAR);
(* Oberon07 compatible variant of Console.String (LEN(s) safe). *)
VAR i: LONGINT;
BEGIN
  i := 0;  WHILE (i<LEN(s)) & (s[i] # 0X) DO Console.Char(s[i]); INC(i) END
END cs;

PROCEDURE ci(i,w: LONGINT);      BEGIN Console.Int(i,w) END ci;
PROCEDURE ch(i: LONGINT);        BEGIN Console.Hex(i)   END ch;
PROCEDURE cc(c: CHAR);           BEGIN Console.Char(c)  END cc;
PROCEDURE cl;                    BEGIN cs(Platform.nl)  END cl;
PROCEDURE csl(s: ARRAY OF CHAR); BEGIN cs(s); cl        END csl;


PROCEDURE ErrorCheck(err: Platform.ErrorCode; msg: ARRAY OF CHAR);
(* OS API wrapper for when no error is expected. *)
BEGIN IF err # 0 THEN cs(msg); ci(err,1); cl; HALT(1) END
END ErrorCheck;


PROCEDURE AcceptConnection;
VAR
  Them: IP.SocketAddress;
  fd:   LONGINT;
BEGIN
  ErrorCheck(IP.Accept(Listener, Them, fd), "Accept failed: ");
  Connected[fd] := TRUE;
  IF fd > MaxSocket THEN MaxSocket := fd END;
  (* TODO: Set fd as non-blocking: O_NONBLOCK and fcntl().  *)
END AcceptConnection;


PROCEDURE Start(fd: LONGINT);
VAR msg: ARRAY 10 OF CHAR; err: Platform.ErrorCode;
BEGIN
  cs("Starting fd "); ci(fd,1); cl;
  msg := "Go.";
  err := Platform.Write(fd, SYSTEM.ADR(msg), 3)
END Start;


PROCEDURE DataReceived(fd: LONGINT; VAR buf: ARRAY OF CHAR; n: LONGINT);
VAR i: LONGINT;
BEGIN
  IF n < LEN(buf) THEN buf[n] := 0X END;
  IF ~Underway[fd] THEN
    IF    buf = "-wait"  THEN
      Waiting[fd] := TRUE; cs("fd "); ci(fd,1); csl(" Waiting.");
    ELSIF buf = "-start" THEN
      i := 0; WHILE i < MaxSocket DO IF Waiting[i] THEN Start(i) END; INC(i) END
    ELSE
      cs(buf)
    END
  ELSE
    cs(buf)
  END;
  Underway[fd] := TRUE;
END DataReceived;


PROCEDURE ConnectionClosed(fd: LONGINT);
BEGIN
  IF Waiting[fd] THEN cs("fd "); ci(fd,1); csl(" closed.");END;
  ErrorCheck(Platform.Close(fd), "Failed to close connection: ");
  Connected[fd] := FALSE;
  Waiting[fd]   := FALSE;
  Underway[fd]  := FALSE;
END ConnectionClosed;


PROCEDURE Cycle;
VAR
  Us:        IP.SocketAddress;
  err:       Platform.ErrorCode;
  n:         LONGINT;
  rbuf:      ARRAY 4100 OF CHAR;
  i:         LONGINT;
  waitcount: LONGINT;
  readFDs:   IP.FDset;
  noFDs:     IP.FDset;
BEGIN
  i := 0; WHILE i < IP.FDcount DO
    Connected[i] := FALSE;  Waiting[i] := FALSE;  Underway[i] := FALSE;
  INC(i) END;
  IP.ZeroFDs(noFDs);

  ErrorCheck(IP.Socket(IP.v4, IP.Stream, Listener),           "Couldn't create listener socket: ");
  ErrorCheck(IP.Lookup("", ListenPort, IP.v4, IP.Stream, Us), "Couldn't lookup our own socket address: ");
  ErrorCheck(IP.Bind  (Listener, Us),                         "Bind failed: ");
  ErrorCheck(IP.Listen(Listener, 10),                         "Listen failed: ");

  MaxSocket := Listener;
  LOOP
    (* Prepare select parameters *)
    IP.ZeroFDs(readFDs);
    IP.SetFD(Listener, readFDs);
    i := 0; WHILE i <= MaxSocket DO
      IF Connected[i] THEN IP.SetFD(i, readFDs) END;
    INC(i) END;

    (* Wait for some fd to need servicing, or 60 seconds. *)
    ErrorCheck(IP.Select(MaxSocket+1, readFDs, noFDs, noFDs, 60000, waitcount), "Wait for next service activity failed: ");
    IF waitcount > 0 THEN
      i := 0;
      WHILE i <= MaxSocket DO
        IF IP.FDisSet(i, readFDs) THEN
          IF i = Listener THEN
            AcceptConnection;
          ELSE
            ErrorCheck(Platform.ReadBuf(i, rbuf, n), "ReadBuf failed: ");
            IF n = 0 THEN
              ConnectionClosed(i); (* Client has closed the connection in an orderly manner. *)
            ELSE
              DataReceived(i, rbuf, n)
            END
          END
        END;
        INC(i)
      END
    END
  END;
  err := Platform.Close(Listener)
END Cycle;

BEGIN
  Cycle;
END TestCoordinator.

