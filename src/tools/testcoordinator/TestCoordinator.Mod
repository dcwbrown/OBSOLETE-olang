MODULE TestCoordinator;

(*
Listens for client test machines, telling them when to start tests and recording
status and log data that they send.
Also listens to command machine that says when to start a new set of tests.
*)

IMPORT IP, Platform, SYSTEM, Console, Strings;

CONST
  ListenPort  = "2055";
  CoIdle      = 0;
  CoConnected = 1;
  CoUnderway  = 2;
  CoWaiting   = 3;

TYPE
  Connection = POINTER TO ConnectionState;
  ConnectionState = RECORD
    fd:     LONGINT;  (* Socket descriptor *)
    state:  INTEGER;  (* CoIdle / CoConnected / CoWaiting *)
    file:   Platform.FileHandle;
    text:   ARRAY 4096 OF CHAR;
    length: INTEGER;
    CR:     BOOLEAN;
  END;

VAR
  MaxSocket:   LONGINT;
  Listener:    LONGINT;
  Connections: ARRAY IP.FDcount OF Connection;


(* Console output convenience APIs *)

PROCEDURE cs (s: ARRAY OF CHAR);
(* Oberon07 compatible variant of Console.String (LEN(s) safe). *)
VAR i: LONGINT;
BEGIN
  i := 0;  WHILE (i<LEN(s)) & (s[i] # 0X) DO Console.Char(s[i]); INC(i) END;
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


(* Connection management APIs *)

PROCEDURE InitConnection(fd: LONGINT);
VAR co: Connection;
BEGIN
  IF Connections[fd] = NIL THEN NEW(Connections[fd]) END;
  co := Connections[fd];
  co.fd     := fd;
  co.state  := CoConnected;
  co.file   := 0;
  co.text   := '';
  co.length := 0;
  co.CR     := FALSE;
END InitConnection;

PROCEDURE OpenLogFile(VAR co: Connection);
VAR filename: ARRAY 1024 OF CHAR;  i: INTEGER;
BEGIN
  ASSERT(co.file = 0);
  i := 0;
  WHILE (i < LEN(co.text)) & (i < LEN(filename)-1) & (co.text[i] # ' ') & (co.text[i] # 0X) DO
    filename[i] := co.text[i]; INC(i);
  END;
  IF i = 0 THEN filename := "unnamed" ELSE filename[i] := 0X END;
  cs("Connected to "); cs(filename); cs(" build on fd "); ci(co.fd,1); csl(".");
  Strings.Append(".log", filename);
  IF Platform.Absent(Platform.OldRW(filename, co.file)) THEN
    ErrorCheck(Platform.New(filename, co.file), "Couldn't create log file: ")
  ELSE
    ErrorCheck(Platform.Seek(co.file, 0, Platform.SeekEnd), "Couldn't position exisiting log file at end: ")
  END;
END OpenLogFile;

PROCEDURE FlushLine(VAR co: Connection);
BEGIN
  IF co.file = 0 THEN OpenLogFile(co) END;
  ErrorCheck(Platform.Write(co.file, SYSTEM.ADR(co.text), co.length), "Failed to write to log file: ");
  ErrorCheck(Platform.Write(co.file, SYSTEM.ADR(Platform.nl), Strings.Length(Platform.nl)), "Failed to write to log file: ");
  co.length := 0;
  co.CR := FALSE;
END FlushLine;

PROCEDURE lc(VAR co: Connection; c: CHAR);
BEGIN
  (* IF (co.length = 0) & ~co.CR THEN <do something at start of line time> END; *)
  IF co.CR OR (c = 0AX) THEN FlushLine(co) END;
  CASE c OF
    0DX: co.CR := TRUE
  | 0AX:
  ELSE   co.text[co.length] := c; INC(co.length)
  END
END lc;

PROCEDURE ls(VAR co: Connection; s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO lc(co, s[i]); INC(i) END
END ls;




PROCEDURE AcceptConnection;
VAR
  Them: IP.SocketAddress;
  fd:   LONGINT;
BEGIN
  ErrorCheck(IP.Accept(Listener, Them, fd), "Accept failed: ");
  IF fd > MaxSocket THEN MaxSocket := fd END;
  InitConnection(fd);
  (* TODO: Set fd as non-blocking: O_NONBLOCK and fcntl().  *)
END AcceptConnection;


PROCEDURE Start(fd: LONGINT);
VAR msg: ARRAY 10 OF CHAR; err: Platform.ErrorCode;
BEGIN
  cs("Starting fd "); ci(fd,1); cl;
  msg := "Go.";
  err := Platform.Write(fd, SYSTEM.ADR(msg), 3)
END Start;


PROCEDURE DataReceived(co: Connection; VAR buf: ARRAY OF CHAR; n: LONGINT);
VAR i: LONGINT;
BEGIN
  IF co # NIL THEN
    IF n < LEN(buf) THEN buf[n] := 0X END;
    IF co.state = CoConnected THEN
      co.state := CoUnderway;
      IF    buf = "-wait"  THEN
        co.state := CoWaiting; cs("fd "); ci(co.fd,1); csl(" Waiting.");
      ELSIF buf = "-start" THEN
        i := 0; WHILE i < MaxSocket DO
          IF (Connections[i] # NIL) & (Connections[i].state = CoWaiting) THEN Start(i) END;
        INC(i) END
      ELSE
        ls(co, buf)
      END
    ELSE
      ls(co, buf)
    END
  END
END DataReceived;


PROCEDURE ConnectionClosed(co: Connection);
BEGIN
  IF co # NIL THEN
    IF co.state = CoWaiting THEN cs("fd "); ci(co.fd,1); csl(" closed.") END;
    ErrorCheck(Platform.Close(co.fd), "Failed to close connection: ");
    co.fd := 0;
    IF co.length > 0 THEN FlushLine(co) END;
    IF co.file # 0 THEN
      ErrorCheck(Platform.Close(co.file), "Failed to close connection log file: ");
    END;
    co.state := CoIdle;
    co.file  := 0;
  END
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
  co:        Connection;
BEGIN
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
      co := Connections[i];
      IF (co # NIL) & (co.state >= CoConnected) & (co.state <= CoUnderway) THEN IP.SetFD(i, readFDs) END;
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
              ConnectionClosed(Connections[i]); (* Client has closed the connection in an orderly manner. *)
            ELSE
              DataReceived(Connections[i], rbuf, n)
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

