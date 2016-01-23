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

{$I "Include:Libraries/DOS.i"} {Needs a few AmigaDOS routines.}
{$I "Opus8.i"} {Has the External references, procedures, and functions.}

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
