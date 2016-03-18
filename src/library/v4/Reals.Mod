MODULE Reals;
  (* JT, 5.2.90 / RC 9.12.91 conversion between reals and strings for HP-700, MB 9.12.91, JT for Ofront, 16.3. 95*)

  IMPORT S := SYSTEM;

  PROCEDURE Ten*(e: INTEGER): REAL;
  VAR r, power: LONGREAL;
  BEGIN r := 1.0;
    power := 10.0;
    WHILE e > 0 DO
      IF ODD(e) THEN r := r * power END ;
      power := power * power; e := e DIV 2
    END ;
    RETURN SHORT(r)
  END Ten;
  

  PROCEDURE TenL*(e: INTEGER): LONGREAL;
    VAR r, power: LONGREAL;
  BEGIN r := 1.0;
    power := 10.0;
    LOOP
      IF ODD(e) THEN r := r * power END ;
      e := e DIV 2;
      IF e <= 0 THEN RETURN r END ;
      power := power * power
    END
  END TenL;
  
 
  PROCEDURE Expo*(x: REAL): INTEGER;
  BEGIN
    RETURN SHORT(ASH(S.VAL(INTEGER, x), -23) MOD 256)
  END Expo;
  
 
  PROCEDURE ExpoL*(x: LONGREAL): INTEGER;
    VAR h: INTEGER;
  BEGIN
    S.GET(S.ADR(x)+4, h); (* Fetch top 32 bits *)
    RETURN SHORT(ASH(h, -20) MOD 2048)
  END ExpoL;
  

  (* Convert LONGREAL: Write positive integer value of x into array d. 
     The value is stored backwards, i.e. least significant digit
     first. n digits are written, with trailing zeros fill. 
     On entry x has been scaled to the number of digits required. *)
  PROCEDURE ConvertL*(x: LONGREAL; n: INTEGER; VAR d: ARRAY OF CHAR);
    VAR i, j, k: LONGINT;
  BEGIN
    IF x < 0 THEN x := -x END;
    k := 0;

    IF (SIZE(LONGINT) < 8) & (n > 9) THEN
      (* There are more decimal digits than can be held in a single LONGINT *)
      i := ENTIER(x /      1000000000.0D0);  (* The 10th and higher digits *)
      j := ENTIER(x - (i * 1000000000.0D0)); (* The low 9 digits *)
      (* First generate the low 9 digits. *)
      IF j < 0 THEN j := 0 END;
      WHILE k < 9 DO 
        d[k] := CHR(j MOD 10 + 48); j := j DIV 10; INC(k)
      END;
      (* Fall through to generate the upper digits *)
    ELSE
      (* We can generate all the digits in one go. *)
      i := ENTIER(x); 
    END;
  
    WHILE k < n DO
      d[k] := CHR(i MOD 10 + 48); i := i DIV 10; INC(k)
    END
  END ConvertL;


  PROCEDURE Convert*(x: REAL; n: INTEGER; VAR d: ARRAY OF CHAR);
  BEGIN ConvertL(x, n, d)
  END Convert;


  PROCEDURE Unpack(VAR b, d: ARRAY OF S.BYTE);
    VAR i, k: SHORTINT; len: LONGINT;
  BEGIN i := 0; len := LEN(b);
    WHILE i < len DO
      k := SHORT(ORD(S.VAL(CHAR, b[i])) DIV 16);
      IF k > 9 THEN d[i*2] := k + 55 ELSE d[i*2] := k + 48 END ;
      k := SHORT(ORD(S.VAL(CHAR, b[i])) MOD 16);
      IF k > 9 THEN d[i*2+1] := k + 55 ELSE d[i*2+1] := k + 48 END ;
      INC(i)
    END
  END Unpack;

  (* Convert Hex *)
  PROCEDURE ConvertH*(y: REAL; VAR d: ARRAY OF CHAR);
  BEGIN Unpack(y, d)
  END ConvertH;
  
  (* Convert Hex Long *)
  PROCEDURE ConvertHL*(x: LONGREAL; VAR d: ARRAY OF CHAR);
  BEGIN Unpack(x, d)
  END ConvertHL;


BEGIN
  ASSERT(SIZE(INTEGER)=4)
END Reals.
