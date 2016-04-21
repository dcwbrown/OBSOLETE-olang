MODULE TestClient;

IMPORT IP, Platform, Console, Strings, SYSTEM;

CONST
  ServerName = "gan";
  ServerPort = "2055";

VAR
  Socket:   Platform.FileHandle;
  Identity: ARRAY 64 OF CHAR;



(* Console output convenience APIs *)

PROCEDURE cs (s: ARRAY OF CHAR);
(* Oberon07 compatible variant of Console.String (LEN(s) safe). *)
VAR i: LONGINT;
BEGIN
  i := 0;  WHILE (i<LEN(s)) & (s[i] # 0X) DO Console.Char(s[i]); INC(i) END
END cs;

PROCEDURE ci (i,w: LONGINT);     BEGIN Console.Int(i,w) END ci;
PROCEDURE cl;                    BEGIN cs(Platform.nl) END cl;
PROCEDURE csl(s: ARRAY OF CHAR); BEGIN cs(s); cl END csl;


PROCEDURE ErrorCheck(err: Platform.ErrorCode; msg: ARRAY OF CHAR);
BEGIN IF err # 0 THEN cs(msg); ci(err,1); cl; HALT(1); END
END ErrorCheck;


PROCEDURE SendString(s: ARRAY OF CHAR);
BEGIN
  ErrorCheck(Platform.Write(Socket, SYSTEM.ADR(s), Strings.Length(s)),
             "Failed to write string to socket: ");
END SendString;


PROCEDURE ConnectSocket;
VAR server: IP.SocketAddress;
BEGIN
  Socket := 0;
  ErrorCheck(IP.Socket(IP.v4, IP.Stream, Socket), "Couldn't create sender socket: ");
  ErrorCheck(IP.Lookup(ServerName, ServerPort, IP.v4, IP.Stream, server),
                                                  "Couldn't lookup server socket address: ");
  ErrorCheck(IP.Connect(Socket, server),          "Couldn't connect to server: ");
END ConnectSocket;


PROCEDURE CloseSocket;
BEGIN ErrorCheck(Platform.Close(Socket), "Couldn't close socket: ")
END CloseSocket;


PROCEDURE Ch(ch: CHAR; VAR buf: ARRAY OF CHAR; VAR offset: LONGINT);
BEGIN buf[offset] := ch; INC(offset);
END Ch;

PROCEDURE TwoDigits(i: LONGINT; VAR buf: ARRAY OF CHAR; VAR offset: LONGINT);
BEGIN Ch(CHR(48 + i DIV 10 MOD 10), buf, offset); Ch(CHR(48 + i MOD 10), buf, offset);
END TwoDigits;

PROCEDURE Str(s: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR; VAR offset: LONGINT);
VAR i: LONGINT;
BEGIN i := 0; WHILE (i < LEN(s)) & (s[i] # 0X) DO Ch(s[i], buf, offset); INC(i) END
END Str;

PROCEDURE Timestamp(id: ARRAY OF CHAR; VAR buf: ARRAY OF CHAR; VAR offset: LONGINT);
VAR t, d: LONGINT;
BEGIN
  Str(id, buf, offset); Ch(" ", buf, offset);
  Platform.GetClock(t,d);
  TwoDigits(ASH(t, -12),       buf, offset);  Ch('.', buf, offset);
  TwoDigits(ASH(t, -6) MOD 64, buf, offset);  Ch('.', buf, offset);
  TwoDigits(t MOD 64,          buf, offset);  Ch(':', buf, offset);
  Ch(' ', buf, offset);
END Timestamp;


PROCEDURE FlushLog(VAR buf: ARRAY OF CHAR; n: LONGINT);
BEGIN
  ErrorCheck(Platform.Write(Socket,          SYSTEM.ADR(buf), n), "Failed to write log to network: ");
  ErrorCheck(Platform.Write(Platform.StdOut, SYSTEM.ADR(buf), n), "Failed to write log to stdout: ");
END FlushLog;


PROCEDURE Log(id: ARRAY OF CHAR);
CONST
  StPl = 0; (* In plain text *)
  StCr = 1; (* CR just received *)
  StLf = 2; (* LF just received *)
  StSl = 3; (* Start of line pending *)
VAR
  state:   INTEGER;
  ch:      CHAR;
  inbuf:   ARRAY 512  OF CHAR;
  outbuf:  ARRAY 1024 OF CHAR;
  i, j, n: LONGINT;
  lablen:  LONGINT;
BEGIN
  lablen := Strings.Length(id) + 12;
  ConnectSocket;
  ErrorCheck(Platform.ReadBuf(Platform.StdIn, inbuf, n), "Failure reading standard input: ");
  state := StSl; (* Trigger an initial display of name *)
  j := 0;
  WHILE n > 0 DO
    i := 0;
    WHILE i < n DO
      ch := inbuf[i]; INC(i);
      (* Start new line on first occurence of CR or LF. Ignore LF after CR or CR after LF. *)
      CASE ch OF
        0AX: CASE state OF
               StPl: state := StLf; Ch(0AX, outbuf, j)
             | StCr: state := StSl;
             | StLf: state := StLf; Timestamp(id, outbuf, j); Ch(0AX, outbuf, j)
             ELSE    state := StLf; Timestamp(id, outbuf, j); Ch(ch, outbuf, j)
             END
      | 0DX: CASE state OF
               StPl: state := StCr; Ch(0AX, outbuf, j)
             | StCr: state := StCr; Timestamp(id, outbuf, j); Ch(0AX, outbuf, j)
             | StLf: state := StSl;
             ELSE    state := StCr; Timestamp(id, outbuf, j); Ch(ch, outbuf, j)
             END
      ELSE   IF state # StPl THEN state := StPl; Timestamp(id, outbuf, j) END; Ch(ch, outbuf, j)
      END;
      IF j+lablen > LEN(outbuf) THEN FlushLog(outbuf, j); j := 0 END
    END;
    ErrorCheck(Platform.ReadBuf(Platform.StdIn, inbuf, n), "Failure reading standard input: ");
  END;
  IF j > 0 THEN FlushLog(outbuf, j) END;
  CloseSocket
END Log;


PROCEDURE Start;
BEGIN ConnectSocket; SendString("-start"); CloseSocket
END Start;


PROCEDURE Wait;
VAR buf: ARRAY 64 OF CHAR; n: LONGINT;
BEGIN
  ConnectSocket; SendString("-wait");
  ErrorCheck(Platform.ReadBuf(Socket, buf, n), "Wait for goahead failed.");
  IF n < LEN(buf) THEN buf[n] := 0X END;
  csl(buf);
  CloseSocket
END Wait;


PROCEDURE Help;
BEGIN
  cl;
  csl("TestClient - test log client"); cl;
  csl("usage:"); cl;
  csl("  command | TestClient id  - Send command output identified by id.");
  csl("  TestClient -w            - wait until TestClient -s runs somewhere.");
  csl("  TestClient -s            - terminate all pending TestClient -w commands.");
  Platform.Exit(0);
END Help;


PROCEDURE ParseParameters;
VAR arg: ARRAY 1024 OF CHAR;
BEGIN
  IF Platform.ArgCount # 2 THEN Help
  ELSE
    Platform.GetArg(1, arg);
    IF    arg = "-w"   THEN Wait
    ELSIF arg = "-s"   THEN Start
    ELSIF arg[0] = "-" THEN Help
    ELSE  Log(arg)
    END
  END
END ParseParameters;




BEGIN
  Socket := 0;
  ParseParameters;
END TestClient.

