PROGRAM Opus8;                                     {jOhn Safranek}
        {    (C)1991 Underground Softworks     }
{Converts Macintosh 8-bit sound files to Amiga 8SVX format.}

TYPE
  SArray    = ARRAY [1..4] OF CHAR;

VAR
  InFileName  : STRING;
  InFile      : TEXT;
  OutFileName : STRING;
  OutFile     : TEXT;
  Hz          : SHORT;
  MacLength   : INTEGER;
  Czech       : BOOLEAN;
  SampleChunk : ARRAY [1..1000] OF CHAR;
  ASample,
  ChunkLength,
  CounterMain,
  CounterAux  : SHORT;

{$I "Include:Utils/StringLib.i"}
{$I "Include:Utils/Parameters.i"}
{$I "Include:Libraries/DOS.i"}

PROCEDURE Usage();
BEGIN {Usage}
  WRITELN('    Usage : Opus8 <MacFile> <8SVXFile> <Hz>');
  WRITELN;
  WRITELN('    Program by : jOhn Safranek');
  WRITELN;
  WRITELN('    (C)1991 Underground Softworks');
  EXIT(5);
END;  {Usage}

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
BEGIN {Main Program}
{Get info from the CommandLine}
  InFileName := AllocString(80);
  OutFileName := AllocString(80);
  GetParam(1, InFileName);
  IF InFileName[0] = CHR(0)
    THEN Usage;
  GetParam(2, OutFileName);
  IF OutFileName[0] = CHR(0)
    THEN Usage;
  Hz := GetHz(3);
  MacLength := FileSize(InFileName);
{Open the Files}
  Czech := REOPEN(InFileName, InFile);
  IF NOT Czech
    THEN NoFile;
  Czech := OPEN(OutFileName, OutFile);
  IF NOT Czech
    THEN CannotOpen;
  WriteTheHeader(Hz, MacLength);
  WRITELN;
  WRITELN('Opus8 - the Mac to Amiga sound converter by jOhn Safranek');
  WRITELN;
{Now let's start converting this puppy. No!, what's on second. Who's on first.}
  WRITELN('Converting ', InFileName, ' to ', OutFileName,'.');
  WRITELN('The Mac file is ', MacLength,' bytes long at ', Hz,' samples per second.');
  WRITELN;
  WRITE('Please wait');
  WHILE MacLength > 0 DO
  BEGIN {WHILE..DO}
    ChunkLength := 1000;
    IF MacLength > ChunkLength
      THEN MacLength := MacLength - ChunkLength
      ELSE
      BEGIN {IF..THEN..ELSE}
        ChunkLength := MacLength;
        MacLength := 0;
      END;  {IF..THEN..ELSE}
    FOR CounterAux := 1 TO ChunkLength DO
      READ(InFile, SampleChunk[CounterAux]);
    WRITE('.');
    FOR CounterAux := 1 TO ChunkLength DO
    BEGIN {FOR..DO}
      ASample := (ORD(SampleChunk[CounterAux]) - 128);
      IF ASample < 0 THEN
        ASample := ASample + 256;
      SampleChunk[CounterAux] := CHR(ASample);
    END;  {FOR..DO}
    FOR CounterAux := 1 TO ChunkLength DO
      WRITE(OutFile, SampleChunk[CounterAux]);
  END;  {WHILE..DO}
  WRITELN;
  WRITELN('Done. Thanks for making a small program happy.');
END.  {Main Program}
