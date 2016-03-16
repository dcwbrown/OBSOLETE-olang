MODULE OPM;  (* RC 6.3.89 / 28.6.89, J.Templ 10.7.89 / 22.7.96  *)
(* constants needed for C code generation

  31.1.2007 jt synchronized with BlackBox version, in particular PromoteIntConstToLInt added
*)

  IMPORT SYSTEM, Texts, Files, Platform, Console, errors, Configuration, vt100, Strings;

  CONST
    OptionChar* = "-";

    (* compiler options; don't change the encoding *)
    inxchk*         = 0;  (* index check on *)
    vcpp*           = 1;  (* VC++ support on; former ovflchk; neither used nor documented *)
    ranchk*         = 2;  (* range check on *)
    typchk*         = 3;  (* type check on *)
    newsf*          = 4;  (* generation of new symbol file allowed *)
    ptrinit*        = 5;  (* pointer initialization *)
    ansi*           = 6;  (* ANSI or K&R style prototypes *)
    assert*         = 7;  (* assert evaluation *)
    extsf*          = 9;  (* extension of old symbol file allowed *)
    mainprog*       = 10; (* translate module body into C main function *)
    dontasm*        = 13; (* don't call external assembler/C compiler *)
    dontlink*       = 14; (* don't link *)
    mainlinkstat*   = 15; (* generate code for main module and then link object file statically *)
    notcoloroutput* = 16; (* turn off color output *)
    forcenewsym*    = 17; (* force new symbol file *)
    verbose*        = 18; (* verbose *)
    defopt*         = {inxchk, typchk, ptrinit, ansi, assert};  (* default options *)

    nilval*         = 0;

    MaxRExp*        = 38;
    MaxLExp*        = 308;
    MaxHDig*        = 8;

    MinHaltNr*      = 0;
    MaxHaltNr*      = 255;
    MaxSysFlag*     = 1;

    MaxCC*          = -1;  (* SYSTEM.CC, GETREG, PUTREG; not implementable in C backend *)
    MinRegNr*       = 0;
    MaxRegNr*       = -1;

    LANotAlloc*     = -1;  (* XProc link adr initialization *)
    ConstNotAlloc*  = -1;  (* for allocation of string and real constants *)
    TDAdrUndef*     = -1;  (* no type desc allocated *)

    MaxCases*       = 128;
    MaxCaseRange*   = 512;

    MaxStruct*      = 255;

    (* maximal number of pointer fields in a record: *)
    MaxPtr*         = MAX(LONGINT);

    (* maximal number of global pointers per module: *)
    MaxGPtr*        = MAX(LONGINT);

    (* maximal number of hidden fields in an exported record: *)
    MaxHdFld*       = 2048;

    HdPtrName*      = "@ptr";
    HdProcName*     = "@proc";
    HdTProcName*    = "@tproc";

    ExpHdPtrFld*    = TRUE;
    ExpHdProcFld*   = FALSE;
    ExpHdTProc*     = FALSE;

    NEWusingAdr*    = FALSE;

    Eot*            = 0X;

    HeaderFile*     = 0;
    BodyFile*       = 1;
    HeaderInclude*  = 2;

    SFext = ".sym"; (* symbol file extension *)
    BFext = ".c";   (* body file extension *)
    HFext = ".h";   (* header file extension *)
    SFtag = 0F7X;   (* symbol file tag *)

  TYPE
    FileName = ARRAY 32 OF CHAR;

  VAR
    SourceFileName : ARRAY 256 OF CHAR;

    Target: ARRAY 2 OF CHAR;

    ByteSize*, CharSize*, BoolSize*, SIntSize*, IntSize*,
    LIntSize*, SetSize*, RealSize*, LRealSize*, PointerSize*, ProcSize*, RecSize*,
    CharAlign*, BoolAlign*, SIntAlign*, IntAlign*,
    LIntAlign*, SetAlign*, RealAlign*, LRealAlign*, PointerAlign*, ProcAlign*, RecAlign*,
    MaxSet*: INTEGER;

    MinSInt*, MinInt*, MinLInt*, MaxSInt*, MaxInt*, MaxLInt*, MaxIndex*: LONGINT;

    MinReal*, MaxReal*, MinLReal*, MaxLReal*: LONGREAL;

    noerr*:           BOOLEAN;
    curpos*, errpos*: LONGINT;  (* character and error position in source file *)
    breakpc*:         LONGINT;  (* set by OPV.Init *)
    currFile*:        INTEGER;  (* current output file *)
    level*:           INTEGER;  (* procedure nesting level *)
    pc*, entno*:      INTEGER;  (* entry number *)
    modName*:         ARRAY 32 OF CHAR;
    objname*:         ARRAY 64 OF CHAR;
    opt*, glbopt*:    SET;

    ErrorLineStartPos, ErrorLineLimitPos, ErrorLineNumber: LONGINT;  (* Limit = start of next line *)

    lasterrpos:   LONGINT;
    inR:          Texts.Reader;
    Log:          Texts.Text;
    W:            Texts.Writer;
    oldSF, newSF: Files.Rider;
    R:            ARRAY 3 OF Files.Rider;

    oldSFile, newSFile, HFile, BFile, HIFile: Files.File;

    S: INTEGER;

    dontAsm-, dontLink-, mainProg-, mainLinkStat-, notColorOutput-, forceNewSym-, Verbose-: BOOLEAN;

    OBERON:  ARRAY 1024 OF CHAR;
    MODULES: ARRAY 1024 OF CHAR;


  (* ------------------------- Log Output ------------------------- *)

  PROCEDURE LogW*(ch: CHAR);            BEGIN Console.Char(ch)    END LogW;
  PROCEDURE LogWStr*(s: ARRAY OF CHAR); BEGIN Console.String(s)   END LogWStr;
  PROCEDURE LogWInt*(i, len: LONGINT);  BEGIN Console.Int(i, len) END LogWInt;
  PROCEDURE LogLn*;                     BEGIN Console.Ln          END LogLn;


  (* ------------------------- parameter handling -------------------------*)

  PROCEDURE ScanOptions(VAR s: ARRAY OF CHAR; VAR opt: SET);
    VAR i: INTEGER;
  BEGIN
  i := 1; (* skip - *)
    WHILE s[i] # 0X DO
      CASE s[i] OF
      | "e": opt := opt / {extsf}
      | "s": opt := opt / {newsf}
      | "m": opt := opt / {mainprog}
      | "x": opt := opt / {inxchk}
      | "v": opt := opt / {vcpp};
      | "r": opt := opt / {ranchk}
      | "t": opt := opt / {typchk}
      | "a": opt := opt / {assert}
      | "k": opt := opt / {ansi}
      | "p": opt := opt / {ptrinit}
      | "S": opt := opt / {dontasm}
      | "c": opt := opt / {dontlink}
      | "M": opt := opt / {mainlinkstat}
      | "f": opt := opt / {notcoloroutput}
      | "F": opt := opt / {forcenewsym}
      | "V": opt := opt / {verbose}
      | "T": IF s[i+1] # 0X THEN INC(i); Target[0] := s[i] END;
             IF s[i+1] # 0X THEN INC(i); Target[1] := s[i] END
      ELSE
        LogWStr("  warning: option ");
        LogW(OptionChar);
        LogW(s[i]);
        LogWStr(" ignored");
        LogLn
      END;
      INC(i)
    END;
  END ScanOptions;


  PROCEDURE ^GetProperties;


  PROCEDURE OpenPar*(): BOOLEAN;  (* prepare for a sequence of translations *)
    VAR s: ARRAY 256 OF CHAR;
  BEGIN
    IF Platform.ArgCount = 1 THEN
      Console.Ln;
      Console.String(Configuration.versionLong); Console.String("."); Console.Ln; 
      Console.Ln;
      Console.String("From Ofront by Software Templ OEG and Vishap Oberon by Norayr Chilingarian."); Console.Ln;
      Console.String("Cross platform build simplifications and fixes by Dave CW Brown."); Console.Ln;
      Console.Ln;
      Console.String('Usage:'); Console.Ln; Console.Ln;
      Console.String('  olang options {files {options}}.'); Console.Ln; Console.Ln;
      Console.String('Where options = ["-" {option} ].'); Console.Ln;
      Console.Ln;
      Console.String("  m   - generate code for main module"); Console.Ln;
      Console.String("  M   - generate code for main module and link object statically"); Console.Ln;
      Console.String("  s   - generate new symbol file"); Console.Ln;
      Console.String("  e   - allow extending the module interface"); Console.Ln;
      Console.String("  r   - check value ranges"); Console.Ln;
      Console.String("  x   - turn off array indices check"); Console.Ln;
      Console.String("  a   - don't check ASSERTs at runtime, use this option in tested production code"); Console.Ln;
      Console.String("  p   - turn off automatic pointer initialization"); Console.Ln;
      Console.String("  t   - don't check type guards (use in rare cases such as low-level modules where every cycle counts)"); Console.Ln;
      Console.String("  P   - use BasicTypeParameters file"); Console.Ln;
      Console.String("  S   - don't call external assembler/compiler, only generate C code"); Console.Ln;
      Console.String("  c   - don't call linker"); Console.Ln;
      Console.String("  f   - don't use color output"); Console.Ln;
      Console.String("  F   - force writing new symbol file in current directory"); Console.Ln;
      Console.String("  V   - verbose output"); Console.Ln;
      Console.String("  Tnn - override C size and alignment"); Console.Ln;
      Console.Ln;
      Console.String('Initial options specify defaults for all files. Options following a filename are ');
      Console.String('specific to that file.'); Console.Ln;
      RETURN FALSE
    ELSE
      S:=1; s:=""; Platform.GetArg(S, s);

      glbopt := defopt;

      WHILE s[0] = OptionChar DO
        ScanOptions(s, glbopt);
        INC(S); s:=""; Platform.GetArg(S, s)
      END;

      RETURN TRUE
    END;
  END OpenPar;


  PROCEDURE InitOptions*;  (* get the options for one translation *)
    VAR s: ARRAY 256 OF CHAR;
  BEGIN
    opt := glbopt;
    s:=""; Platform.GetArg(S, s);
    WHILE s[0] = OptionChar DO
      ScanOptions(s, opt);
      INC(S); s:=""; Platform.GetArg(S, s)
    END;

    dontAsm        := dontasm        IN opt;
    dontLink       := dontlink       IN opt;
    mainProg       := mainprog       IN opt;
    mainLinkStat   := mainlinkstat   IN opt;
    notColorOutput := notcoloroutput IN opt;
    forceNewSym    := forcenewsym    IN opt;
    Verbose        := verbose        IN opt;

    IF mainLinkStat THEN INCL(glbopt, mainprog) END; (* sic *)

    GetProperties;
  END InitOptions;


  PROCEDURE Init*(VAR done: BOOLEAN; VAR mname : ARRAY OF CHAR);  (* get the source for one translation *)
  VAR
    T: Texts.Text;
    beg, end, time: LONGINT;
    s: ARRAY 256 OF CHAR;
  BEGIN
    (* LogWStr("OPM init, S = "); LogWInt(S,1); LogLn; *)
    done := FALSE;
    curpos := 0;
    IF S >= Platform.ArgCount THEN (* LogWStr("OPM.Init no more args"); LogLn; *) RETURN END ;

    s:=""; Platform.GetArg(S, s);

    NEW(T); Texts.Open(T, s);
    (* LogWStr(s); *)
    COPY(s, mname);
    COPY(s, SourceFileName); (* to keep it also in this module -- noch *)

    IF T.len = 0 THEN
      LogWStr(s); LogWStr(" not found"); LogLn
    ELSE
      Texts.OpenReader(inR, T, 0);
      (* LogWStr("  translating"); *)
      done := TRUE
    END;

    INC(S);
    level := 0; noerr := TRUE; errpos := curpos; lasterrpos := curpos -10;
    ErrorLineStartPos := 0; ErrorLineLimitPos := 0; ErrorLineNumber := 0;
  END Init;



  (* ------------------------- read source text -------------------------*)

  PROCEDURE Get*(VAR ch: CHAR);  (* read next character from source text, 0X if eof *)
  BEGIN
    Texts.Read(inR, ch);
    IF ch = 0DX THEN
       curpos := Texts.Pos(inR); (* supports CR LF mapping *)
    ELSE
      INC(curpos)
    END ;
    IF (ch < 09X) & ~inR.eot THEN ch := " " END
  END Get;


  PROCEDURE MakeFileName(VAR name, FName: ARRAY OF CHAR; ext: ARRAY OF CHAR);
    VAR i, j: INTEGER; ch: CHAR;
  BEGIN i := 0;
    LOOP ch := name[i];
      IF ch = 0X THEN EXIT END ;
      FName[i] := ch; INC(i)
    END ;
    j := 0;
    REPEAT ch := ext[j]; FName[i] := ch; INC(i); INC(j)
    UNTIL ch = 0X
  END MakeFileName;


  PROCEDURE LogErrMsg(n: INTEGER);
    VAR
      S: Texts.Scanner; T: Texts.Text;
      ch: CHAR; i: INTEGER;
      buf: ARRAY 1024 OF CHAR;
  BEGIN
    IF n >= 0 THEN
       IF ~notColorOutput THEN vt100.SetAttr(vt100.Red) END;
       LogWStr("  err ");
       IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;
    ELSE
       IF ~notColorOutput THEN vt100.SetAttr(vt100.Magenta) END;
       LogWStr("  warning "); n := -n;
       IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;
    END ;
    LogWInt(n, 1);
    LogWStr("  ");
    (*NEW(T); Texts.Open(T, "vocErrors.Text"); Texts.OpenScanner(S, T, 0);
    REPEAT S.line := 0;
      REPEAT Texts.Scan(S) UNTIL S.eot OR (S.line # 0)
    UNTIL S.eot OR (S.class = Texts.Int) & (S.i = n);
    IF ~S.eot THEN Texts.Read(S, ch); i := 0;
      WHILE ~S.eot & (ch # 0DX) DO buf[i] := ch; INC(i); Texts.Read(S, ch) END ;
      buf[i] := 0X; LogWStr(buf);
    END*)
    LogWStr(errors.errors[n]);
  END LogErrMsg;


  PROCEDURE FindLine(f: Files.File; VAR r: Files.Rider; pos: LONGINT);
  (* Updates ErrorLineStartPos, ErrorLineLimitPos, ErrorLineNumber to 
     describe the line containing pos. 
     Exits with the rider set to the start of the line conaining pos. *)
  VAR
    ch, cheol: CHAR;
  BEGIN
    IF pos < ErrorLineStartPos THEN  (* Desired position is before saved position, start again at the begnning of file *)
      ErrorLineStartPos := 0; ErrorLineLimitPos := 0; ErrorLineNumber := 0
    END;
    IF pos < ErrorLineLimitPos THEN (* Current saved line positions contain pos *)
      Files.Set(r, f, ErrorLineStartPos);
      RETURN
    END; 

    Files.Set(r, f, ErrorLineLimitPos);
    Files.Read(r, ch); 
    WHILE (ErrorLineLimitPos < pos) & ~r.eof DO
      ErrorLineStartPos := ErrorLineLimitPos;
      INC(ErrorLineNumber);
      WHILE (ch # 0X) & (ch # 0DX) & (ch # 0AX) DO 
        Files.Read(r, ch); INC(ErrorLineLimitPos) 
      END;
      cheol := ch; Files.Read(r, ch); INC(ErrorLineLimitPos);
      IF (cheol = 0DX) & (ch = 0AX) THEN
        INC(ErrorLineLimitPos); Files.Read(r, ch)
      END
    END;
    Files.Set(r, f, ErrorLineStartPos);
  END FindLine;


  PROCEDURE ShowLine(pos: LONGINT);
  VAR
    f:    Files.File;
    r:    Files.Rider;
    line: ARRAY 1023 OF CHAR;
    i:    INTEGER;
    ch:   CHAR;
  BEGIN
    f := Files.Old(SourceFileName);
    FindLine(f, r, pos);

    i := 0; Files.Read(r, ch);
    WHILE (ch # 0X) & (ch # 0DX) & (ch # 0AX) & (i < LEN(line)-1) DO 
      line[i] := ch; INC(i); Files.Read(r, ch)
    END;
    line[i] := 0X;

    LogLn; LogLn; 
    LogWInt(ErrorLineNumber, 4); LogWStr(": "); LogWStr(line); LogLn;
    LogWStr("      ");

    IF pos >= ErrorLineLimitPos THEN pos := ErrorLineLimitPos-1 END;
    i := SHORT(pos - ErrorLineStartPos);
    WHILE i > 0 DO LogW(" "); DEC(i) END;

    IF ~notColorOutput THEN vt100.SetAttr(vt100.Green) END;
    LogW("^");
    IF ~notColorOutput THEN vt100.SetAttr(vt100.ResetAll) END;

    Files.Close(f);
  END ShowLine;


  PROCEDURE Mark*(n: INTEGER; pos: LONGINT);
  BEGIN
    IF pos = -1 THEN pos := 0 END;
    IF n >= 0 THEN
      noerr := FALSE;
      IF (pos < lasterrpos) OR (lasterrpos + 9 < pos) THEN lasterrpos := pos; ShowLine(pos); LogLn; LogWStr("  ");
        IF n < 249 THEN LogWStr("  pos"); LogWInt(pos, 6); LogErrMsg(n)
        ELSIF n = 255 THEN LogWStr("pos"); LogWInt(pos, 6); LogWStr("  pc "); LogWInt(breakpc, 1)
        ELSIF n = 254 THEN LogWStr("pc not found")
        ELSE LogWStr(objname);
          IF    n = 253 THEN LogWStr(" is new, compile with option e")
          ELSIF n = 252 THEN LogWStr(" is redefined, compile with option s")
          ELSIF n = 251 THEN LogWStr(" is redefined (private part only), compile with option s")
          ELSIF n = 250 THEN LogWStr(" is no longer visible, compile with option s")
          ELSIF n = 249 THEN LogWStr(" is not consistently imported, recompile imports")
          END
        END
      END
    ELSE
      IF pos >= 0 THEN ShowLine(pos); LogLn; LogWStr("  pos"); LogWInt(pos, 6) END ;
      LogErrMsg(n);
      IF pos < 0 THEN LogLn END
    END
  END Mark;


  PROCEDURE err*(n: INTEGER);
  BEGIN Mark(n, errpos) 
  END err;


  PROCEDURE FPrint*(VAR fp: LONGINT; val: LONGINT);
  BEGIN
    fp := SYSTEM.ROT(SYSTEM.VAL(LONGINT, SYSTEM.VAL(SET, fp) / SYSTEM.VAL(SET, val)), 1)
  END FPrint;


  PROCEDURE FPrintSet*(VAR fp: LONGINT; set: SET);
  BEGIN FPrint(fp, SYSTEM.VAL(LONGINT, set))
  END FPrintSet;


  PROCEDURE FPrintReal*(VAR fp: LONGINT; real: REAL);
  BEGIN FPrint(fp, SYSTEM.VAL(LONGINT, real))
  END FPrintReal;


  PROCEDURE FPrintLReal*(VAR fp: LONGINT; lr: LONGREAL);
  VAR l, h: LONGINT;
  BEGIN
    SYSTEM.GET(SYSTEM.ADR(lr), l); SYSTEM.GET(SYSTEM.ADR(lr)+4, h);
    FPrint(fp, l); FPrint(fp, h)
  END FPrintLReal;




  (* ------------------------- initialization ------------------------- *)

  PROCEDURE GetProperty(VAR S: Texts.Scanner; name: ARRAY OF CHAR; VAR size, align: INTEGER);
  BEGIN
    IF (S.class = Texts.Name) & (S.s = name) THEN Texts.Scan(S);
      IF S.class = Texts.Int THEN size := SHORT(S.i); Texts.Scan(S) ELSE Mark(-157, -1) END ;
      IF S.class = Texts.Int THEN align := SHORT(S.i); Texts.Scan(S) ELSE Mark(-157, -1) END
    ELSE Mark(-157, -1)
    END
  END GetProperty;


  PROCEDURE minus(i: LONGINT): LONGINT;
  BEGIN
    RETURN -i;
  END minus;


  PROCEDURE power0(i, j : LONGINT) : LONGINT; (* we would like to calculate exact Min Max values in GetProperties, not hardcode em, noch *)
  VAR k : LONGINT;
      p : LONGINT;
  BEGIN
     k := 1;
     p := i;
     REPEAT
        p := p * i;
        INC(k);
     UNTIL k=j;
     RETURN p;
  END power0;


  PROCEDURE VerboseListSizes;
  BEGIN
    Console.String("Type        Size  Alignement"); Console.Ln;
    Console.String("CHAR         "); Console.Int(CharSize,    4); Console.Int(CharAlign,    5); Console.Ln;
    Console.String("BOOLEAN      "); Console.Int(BoolSize,    4); Console.Int(BoolAlign,    5); Console.Ln;
    Console.String("SHORTINT     "); Console.Int(SIntSize,    4); Console.Int(SIntAlign,    5); Console.Ln;
    Console.String("INTEGER      "); Console.Int(IntSize,     4); Console.Int(IntAlign,     5); Console.Ln;
    Console.String("LONGINT      "); Console.Int(LIntSize,    4); Console.Int(LIntAlign,    5); Console.Ln;
    Console.String("SET          "); Console.Int(SetSize,     4); Console.Int(SetAlign,     5); Console.Ln;
    Console.String("REAL         "); Console.Int(RealSize,    4); Console.Int(RealAlign,    5); Console.Ln;
    Console.String("LONGREAL     "); Console.Int(LRealSize,   4); Console.Int(LRealAlign,   5); Console.Ln;
    Console.String("PTR          "); Console.Int(PointerSize, 4); Console.Int(PointerAlign, 5); Console.Ln;
    Console.String("PROC         "); Console.Int(ProcSize,    4); Console.Int(ProcAlign,    5); Console.Ln;
    Console.String("RECORD       "); Console.Int(RecSize,     4); Console.Int(RecAlign,     5); Console.Ln;
  (*Console.String("ENDIAN       "); Console.Int(ByteOrder,   4); Console.Int(BitOrder,     5); Console.Ln;*)
    Console.Ln;
    Console.String("Min shortint "); Console.Int(MinSInt,     4); Console.Ln;
    Console.String("Max shortint "); Console.Int(MaxSInt,     4); Console.Ln;
    Console.String("Min integer  "); Console.Int(MinInt,      4); Console.Ln;
    Console.String("Max integer  "); Console.Int(MaxInt,      4); Console.Ln;
    Console.String("Min longint  "); Console.Int(MinLInt,     4); Console.Ln;
  END VerboseListSizes;


  PROCEDURE GetProperties();
    VAR 
      base : LONGINT;
      addressSize: INTEGER;
      alignment:   INTEGER;
  BEGIN
    addressSize := Configuration.addressSize;
    alignment   := Configuration.alignment;

    IF Target # "" THEN
      addressSize := ORD(Target[0]) - ORD('0');
      alignment   := ORD(Target[1]) - ORD('0');
    END;

    CharSize    := 1;             CharAlign    := 1;
    BoolSize    := 1;             BoolAlign    := 1;
    SIntSize    := 1;             SIntAlign    := 1;
    IntSize     := 4;             IntAlign     := 4;
    LIntSize    := 8;             LIntAlign    := alignment;
    SetSize     := 8;             SetAlign     := alignment;
    RealSize    := 4;             RealAlign    := 4;
    LRealSize   := 8;             LRealAlign   := alignment;
    PointerSize := addressSize;   PointerAlign := addressSize;
    ProcSize    := addressSize;   ProcAlign    := addressSize;
    RecSize     := 1;             RecAlign     := 1;

    ByteSize := CharSize;

    (* and I'd like to calculate it, not hardcode constants *)
    base := -2;
    MinSInt := ASH(base, SIntSize*8-2);
    MaxSInt := minus(MinSInt + 1);

    MinInt := ASH(base, IntSize*8-2);
    MaxInt := minus(MinInt + 1);

    MinLInt := ASH(base, LIntSize*8-2);
    MaxLInt := minus(MinLInt +1);

    IF RealSize = 4 THEN MaxReal := 3.40282346D38
    ELSIF RealSize = 8 THEN MaxReal := 1.7976931348623157D307 * 9.999999
      (*should be 1.7976931348623157D308 *)
    END ;

    IF LRealSize = 4 THEN MaxLReal := 3.40282346D38
    ELSIF LRealSize = 8 THEN MaxLReal := 1.7976931348623157D307 * 9.999999
      (*should be 1.7976931348623157D308 *)
    END ;

    MinReal := -MaxReal;
    MinLReal := -MaxLReal;

    MaxSet := SetSize * 8 - 1;
    MaxIndex := MaxLInt; (* shouldn't it be like max(int)? so that for loop will be safe, noch *)
    IF Verbose THEN VerboseListSizes END;
  END GetProperties;




  (* ------------------------- Read Symbol File ------------------------- *)

  PROCEDURE SymRCh*(VAR ch: CHAR);
  BEGIN Files.Read(oldSF, ch)
  END SymRCh;

  PROCEDURE SymRInt*(): LONGINT;
    VAR k: LONGINT;
  BEGIN Files.ReadNum(oldSF, k); RETURN k
  END SymRInt;

  PROCEDURE SymRSet*(VAR s: SET);
  BEGIN Files.ReadNum(oldSF, SYSTEM.VAL(LONGINT, s))
  END SymRSet;

  PROCEDURE SymRReal*(VAR r: REAL);
  BEGIN Files.ReadReal(oldSF, r)
  END SymRReal;

  PROCEDURE SymRLReal*(VAR lr: LONGREAL);
  BEGIN Files.ReadLReal(oldSF, lr)
  END SymRLReal;

  PROCEDURE CloseOldSym*;
  END CloseOldSym;

  PROCEDURE OldSym*(VAR modName: ARRAY OF CHAR; VAR done: BOOLEAN);
    VAR ch: CHAR; fileName: FileName;
  BEGIN 
    (* Console.String("OPM.OldSym modName = "); Console.String(modName); Console.Ln; *)
    MakeFileName(modName, fileName, SFext);
    oldSFile := Files.Old(fileName); done := oldSFile # NIL;
    IF done THEN
      Files.Set(oldSF, oldSFile, 0); Files.Read(oldSF, ch);
      IF ch # SFtag THEN err(-306);  (*possibly a symbol file from another Oberon implementation, e.g. HP-Oberon*)
        CloseOldSym; done := FALSE
      END
    END
  END OldSym;

  PROCEDURE eofSF*(): BOOLEAN;
  BEGIN RETURN oldSF.eof
  END eofSF;




  (* ------------------------- Write Symbol File ------------------------- *)

  PROCEDURE SymWCh*(ch: CHAR);
  BEGIN Files.Write(newSF, ch)
  END SymWCh;

  PROCEDURE SymWInt*(i: LONGINT);
  BEGIN Files.WriteNum(newSF, i)
  END SymWInt;

  PROCEDURE SymWSet*(s: SET);
  BEGIN Files.WriteNum(newSF, SYSTEM.VAL(LONGINT, s))
  END SymWSet;

  PROCEDURE SymWReal*(r: REAL);
  BEGIN Files.WriteReal(newSF, r)
  END SymWReal;

  PROCEDURE SymWLReal*(lr: LONGREAL);
  BEGIN Files.WriteLReal(newSF, lr)
  END SymWLReal;

  PROCEDURE RegisterNewSym*;
  BEGIN
    IF (modName # "SYSTEM") OR (mainprog IN opt) THEN Files.Register(newSFile) END
  END RegisterNewSym;

  PROCEDURE DeleteNewSym*;
  END DeleteNewSym;

  PROCEDURE NewSym*(VAR modName: ARRAY OF CHAR);
    VAR fileName: FileName;
  BEGIN MakeFileName(modName, fileName, SFext);
    newSFile := Files.New(fileName);
    IF newSFile # NIL THEN Files.Set(newSF, newSFile, 0); Files.Write(newSF, SFtag)
    ELSE err(153)
    END
  END NewSym;




  (* ------------------------- Write Header & Body Files ------------------------- *)

  PROCEDURE Write*(ch: CHAR);
  BEGIN Files.Write(R[currFile], ch)
  END Write;

  PROCEDURE WriteString*(s: ARRAY [1] OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] # 0X DO INC(i) END ;
    Files.WriteBytes(R[currFile], s, i)
  END WriteString;

  PROCEDURE WriteStringVar*(VAR s: ARRAY OF CHAR);
    VAR i: INTEGER;
  BEGIN i := 0;
    WHILE s[i] # 0X DO INC(i) END ;
    Files.WriteBytes(R[currFile], s, i)
  END WriteStringVar;

  PROCEDURE WriteHex* (i: LONGINT);
    VAR s: ARRAY 3 OF CHAR;
      digit : INTEGER;
  BEGIN
    digit := SHORT(i) DIV 16;
    IF digit < 10 THEN s[0] := CHR (ORD ("0") + digit); ELSE s[0] := CHR (ORD ("a") - 10 + digit ); END;
    digit := SHORT(i) MOD 16;
    IF digit < 10 THEN s[1] := CHR (ORD ("0") + digit); ELSE s[1] := CHR (ORD ("a") - 10 + digit ); END;
    s[2] := 0X;
    WriteString(s)
  END WriteHex;

  PROCEDURE WriteInt* (i: LONGINT);
    VAR s: ARRAY 20 OF CHAR; i1, k: LONGINT;
  BEGIN
    IF (i = MinInt) OR (i = MinLInt) THEN 
      (* abs(minint) is one more than maxint, causing problems representing the value as a minus sign 
         followed by absoute value. Therefore represent as -maxint - 1. For INTEGER this avoids a
         compiler warning 'this decimal constant is unsigned only in ISO C90', for LONGINT it is the 
         only way to represent MinLInt. *)
      Write("("); WriteInt(i+1); WriteString("-1)")
    ELSE i1 := ABS(i);
      s[0] := CHR(i1 MOD 10 + ORD("0")); i1 := i1 DIV 10; k := 1;
      WHILE i1 > 0 DO s[k] := CHR(i1 MOD 10 + ORD("0")); i1 := i1 DIV 10; INC(k) END ;
      IF i < 0 THEN s[k] := "-"; INC(k) END ;
      WHILE k > 0 DO  DEC(k); Write(s[k]) END
    END ;
  END WriteInt;

  PROCEDURE WriteReal* (r: LONGREAL; suffx: CHAR);
    VAR W: Texts.Writer; T: Texts.Text; R: Texts.Reader; s: ARRAY 32 OF CHAR; ch: CHAR; i: INTEGER;
  BEGIN
(*should be improved *)
    IF (r < MaxLInt) & (r > MinLInt) & (r = ENTIER(r)) THEN
      IF suffx = "f" THEN WriteString("(REAL)") ELSE WriteString("(LONGREAL)") END ;
      WriteInt(ENTIER(r))
    ELSE
      Texts.OpenWriter(W);
      IF suffx = "f" THEN Texts.WriteLongReal(W, r, 16) ELSE Texts.WriteLongReal(W, r, 23) END ;
      NEW(T); Texts.Open(T, ""); Texts.Append(T, W.buf);
      Texts.OpenReader(R, T, 0); i := 0; Texts.Read(R, ch);
      WHILE ch # 0X DO s[i] := ch; INC(i); Texts.Read(R, ch) END ;
  (* s[i] := suffx; s[i+1] := 0X;
  suffix does not work in K&R *)
      s[i] := 0X;
      i := 0; ch := s[0];
      WHILE (ch # "D") & (ch # 0X) DO INC(i); ch := s[i] END ;
      IF ch = "D" THEN s[i] := "e" END ;
      WriteString(s)
    END
  END WriteReal;

  PROCEDURE WriteLn* ();
  BEGIN Files.Write(R[currFile], 0AX)
  END WriteLn;

  PROCEDURE Append(VAR R: Files.Rider; F: Files.File);
    VAR R1: Files.Rider; buffer: ARRAY 4096 OF CHAR;
  BEGIN
    IF F # NIL THEN
      Files.Set(R1, F, 0); Files.ReadBytes(R1, buffer, LEN(buffer));
      WHILE LEN(buffer) - R1.res > 0 DO
        Files.WriteBytes(R, buffer, LEN(buffer) - R1.res);
        Files.ReadBytes(R1, buffer, LEN(buffer))
      END
    END
  END Append;

  PROCEDURE OpenFiles*(VAR moduleName: ARRAY OF CHAR);
    VAR FName: ARRAY 32 OF CHAR;
  BEGIN
    COPY(moduleName, modName);
    HFile := Files.New("");
    IF HFile # NIL THEN Files.Set(R[HeaderFile], HFile, 0) ELSE err(153) END ;
    MakeFileName(moduleName, FName, BFext);
    BFile := Files.New(FName);
    IF BFile # NIL THEN Files.Set(R[BodyFile], BFile, 0) ELSE err(153) END ;
    MakeFileName(moduleName, FName, HFext);
    HIFile := Files.New(FName);
    IF HIFile # NIL THEN Files.Set(R[HeaderInclude], HIFile, 0) ELSE err(153) END ;
  END OpenFiles;

  PROCEDURE CloseFiles*;
    VAR FName: ARRAY 32 OF CHAR; res: INTEGER;
  BEGIN
    (* IF noerr THEN LogWStr("    "); LogWInt(Files.Pos(R[BodyFile]), 0) END; *)
    IF noerr THEN
      IF modName = "SYSTEM" THEN
        IF ~(mainprog IN opt) THEN Files.Register(BFile) END
      ELSIF ~(mainprog IN opt) THEN
        Append(R[HeaderInclude], HFile);
        Files.Register(HIFile); Files.Register(BFile)
      ELSE
        MakeFileName(modName, FName, HFext); Files.Delete(FName, res);
        MakeFileName(modName, FName, SFext); Files.Delete(FName, res);
        Files.Register(BFile)
      END
    END ;
    HFile := NIL; BFile := NIL; HIFile := NIL; newSFile := NIL; oldSFile := NIL;
    Files.Set(R[0], NIL, 0); Files.Set(R[1], NIL, 0); Files.Set(R[2], NIL, 0); Files.Set(newSF, NIL, 0); Files.Set(oldSF, NIL, 0)
  END CloseFiles;


BEGIN
  Target[0] := '4';
  Target[1] := '4';

  Texts.OpenWriter(W);

  MODULES := "";  Platform.GetEnv("MODULES", MODULES);

  OBERON  := "."; Platform.GetEnv("OBERON", OBERON);
  Strings.Append(";.;",                     OBERON);
  Strings.Append(MODULES,                   OBERON);
  Strings.Append(";",                       OBERON);
  Strings.Append(Configuration.installdir,  OBERON);
  Strings.Append("/sym;",                   OBERON);

  Files.SetSearchPath(OBERON);
  (* Console.String("Oberon file open search path: "); Console.String(OBERON); Console.Ln; *)
END OPM.
