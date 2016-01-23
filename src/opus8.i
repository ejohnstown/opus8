{
    Opus8.i - This is the Include file for the Opus8 program by jOhn Safranek.
                                               (C)1991 Underground Softworks
              This Include has all the External references, various funtions,
              and procedures. Keep this with the source code or face an 
              eternity of flogging. Thank you.
}

PROCEDURE Usage();
BEGIN {Usage}
  WRITELN('    Usage : Opus8 <MacFile> <8SVXFile> <Hz>');
  WRITELN;
  WRITELN('    Program by : jOhn Safranek');
  WRITELN;
  WRITELN('    (C)1991 Underground Softworks');
  EXIT(5);
END;  {Usage}

FUNCTION AllocString(l : INTEGER) : STRING;
  External;

PROCEDURE FreeString(sq : STRING);
  External;

PROCEDURE GetParam(    n : SHORT;
                   VAR s : STRING);
  External;

FUNCTION GetHz(B : SHORT) : INTEGER;
VAR
  Noombah    : STRING;
  Multiplier : INTEGER;
  Numb       : INTEGER;
  Counter    : SHORT;
BEGIN {GetHz}
  Multiplier := 1;
  Numb := 0;
  Counter := 4;
  Noombah := AllocString(6);
  GetParam(B, Noombah);
  IF Noombah[0] = CHR(0)
    THEN Usage;
  FOR Counter := 4 DOWNTO 0 DO
  BEGIN {FOR..DO}
    IF Noombah[Counter] > CHR(0)
      THEN
      BEGIN {IF..THEN}
        Numb := Numb + ((ORD(Noombah[Counter]) - 48) * Multiplier);
        Multiplier := Multiplier * 10;
      END;  {IF..THEN}
  END;  {FOR..DO}
  FreeString(Noombah);
  GetHz := Numb;
END;  {GetHz}

PROCEDURE NoFile();
BEGIN {NoFile}
  WRITELN('I cannot find your Mac file.');
  WRITELN('Program  ABORTED.');
  EXIT(5);
END;  {NoFile}

PROCEDURE CannotOpen();
BEGIN {CannotOpen}
  WRITELN('I cannot open the IFF file.');
  WRITELN('Program  ABORTED.');
  EXIT(5);
END;  {CannotOpen}

FUNCTION FileSize(FileName : STRING) : INTEGER;
VAR
  FInfo  : FileInfoBlockPtr;
  FLock  : FileLock;
  Result : INTEGER;
BEGIN {FileSize}
  FLock := Lock(FileName, SHARED_LOCK);
  IF FLock = NIL
    THEN FileSize := 0;
  NEW(FInfo);
  IF Examine(FLock, FInfo)
    THEN Result := FInfo^.fib_Size
    ELSE Result := 0;
  DISPOSE(FInfo);
  UnLock(FLock);
  FileSize := Result;
END;  {FileSize}

PROCEDURE MakeChar(    Benign : INTEGER;
                   VAR Fin    : SArray);
VAR
  Result : ARRAY [1..8] OF SHORT;
  index,
  Count  : SHORT;
BEGIN {MakeChar}
  FOR Count := 1 TO 4 DO
    Fin[Count] := CHR($00);
  FOR index := 8 DOWNTO 1 DO
  BEGIN {FOR..DO}
    Result[index] := Benign AND 15;
    Benign := Benign DIV 16;
  END;  {FOR..DO}
  Count := 1;
  FOR index := 1 TO 4 DO
  BEGIN {FOR..DO}
    Fin[index] := (CHR((Result[Count] * 16) + Result[Count+1]));
    Count := Count + 2;
  END;  {FOR..DO}
END;  {MakeChar}

PROCEDURE WriteTheHeader(    Hur  : SHORT;
                             Lan  : INTEGER); 
VAR
  Cnt  : SHORT; 
  Hrts,
  Len,
  Lun  : SArray;
BEGIN {WriteTheHeader}
  MakeChar(Hur, Hrts);
  MakeChar(Lan+40, Len);
  MakeChar(Lan, Lun);  
  WRITE(OutFile, 'FORM', Len, '8SVXVHDR', CHR($00), CHR($00), CHR($00), 
  CHR($14), Lun, CHR($00), CHR($00), CHR($00), CHR($00), CHR($00), CHR($00), 
  CHR($00), CHR($00), Hrts[3], Hrts[4], CHR($01), CHR($00), CHR($00), CHR($01),
  CHR($00), CHR($00), 'BODY', Lun);
END;  {WriteTheHeader}
