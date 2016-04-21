MODULE TestClient;

IMPORT IP, Platform, Console, Strings, SYSTEM;

CONST
  ServerName = "gan.brownsmeet.com";
  ServerPort = "2055";

TYPE
  LineBuffer = RECORD
    text:   ARRAY 4096 OF CHAR;
    length: INTEGER;
    CR:     BOOLEAN
  END;

VAR
  Socket:   Platform.FileHandle;
  Identity: ARRAY 1024 OF CHAR;
  Buffer:   LineBuffer;


(* Console output convenience APIs *)

PROCEDURE cs(s: ARRAY OF CHAR);
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


(* Line buffer output APIs *)

PROCEDURE InitBuffer;
BEGIN
  Buffer.text   := '';
  Buffer.length := 0;
  Buffer.CR     := FALSE;
END InitBuffer;

PROCEDURE AddChar(c: CHAR);
BEGIN IF Buffer.length < LEN(Buffer.text) THEN Buffer.text[Buffer.length] := c; INC(Buffer.length) END
END AddChar;

PROCEDURE AddString(s: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0;
  WHILE (Buffer.length < LEN(Buffer.text)) & (i < LEN(s)) & (s[i] # 0X) DO
    Buffer.text[Buffer.length] := s[i];
    INC(Buffer.length);
    INC(i)
  END
END AddString;

PROCEDURE FlushLine;
VAR i: INTEGER;
BEGIN
  AddChar(0AX); Buffer.text[LEN(Buffer.text)-1] := 0AX; (* Force EOLN even on overflow *)
  ErrorCheck(Platform.Write(Socket,          SYSTEM.ADR(Buffer.text), Buffer.length), "Failed to write log to network: ");
  ErrorCheck(Platform.Write(Platform.StdOut, SYSTEM.ADR(Buffer.text), Buffer.length), "Failed to write log to stdout: ");
  InitBuffer
END FlushLine;

PROCEDURE TwoDigits(i: LONGINT);
BEGIN AddChar(CHR(48 + i DIV 10 MOD 10)); AddChar(CHR(48 + i MOD 10));
END TwoDigits;

PROCEDURE Timestamp;
VAR t, d: LONGINT;
BEGIN
  AddString(Identity); AddChar(' ');
  Platform.GetClock(t,d);
  TwoDigits(ASH(t, -12));        AddChar('.');
  TwoDigits(ASH(t, -6) MOD 64);  AddChar('.');
  TwoDigits(t MOD 64);           AddString(': ');
END Timestamp;

PROCEDURE LogCharacter(c: CHAR);
BEGIN
  IF Buffer.length = 0 THEN Timestamp END;
  IF Buffer.CR OR (c = 0AX) THEN FlushLine END;
  CASE c OF
    0DX: Buffer.CR := TRUE
  | 0AX:
  ELSE   AddChar(c)
  END
END LogCharacter;

PROCEDURE FlushLog;
BEGIN IF (Buffer.length # 0) OR Buffer.CR THEN FlushLine END
END FlushLog;


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


PROCEDURE LogStdIn;
VAR i, n: LONGINT;  inbuf: ARRAY 8192 OF CHAR;
BEGIN
  ConnectSocket;
  ErrorCheck(Platform.ReadBuf(Platform.StdIn, inbuf, n), "Failure reading standard input: ");
  InitBuffer;
  WHILE n > 0 DO
    i := 0;
    WHILE i < n DO LogCharacter(inbuf[i]); INC(i) END;
    ErrorCheck(Platform.ReadBuf(Platform.StdIn, inbuf, n), "Failure reading standard input: ");
  END;
  FlushLog;
  CloseSocket
END LogStdIn;


PROCEDURE SendString(s: ARRAY OF CHAR);
BEGIN
  ErrorCheck(Platform.Write(Socket, SYSTEM.ADR(s), Strings.Length(s)),
             "Failed to write string to socket: ");
END SendString;


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
    ELSE  COPY(arg, Identity); LogStdIn
    END
  END
END ParseParameters;




BEGIN
  Socket := 0;
  ParseParameters;
END TestClient.

