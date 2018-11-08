program Opus8;
{ (C)1991-2018 John Safranek }
{ Converts Macintosh 8-bit sound files to Amiga 8SVX format. }



{$I "Include:Utils/StringLib.i"}
{$I "Include:Utils/Parameters.i"}
{$I "Include:Libraries/DOS.i"}



const
  singleOctave = 1;
  compressionNone = 0;
  maxVolume = $10000;
  tagForm = $464f524d;
  tagVhdr = $56484452;
  tag8svx = $38535658;
  tagBody = $424f4459;


type
  SArray = array [1..4] of char;
  ChunkHeader = record
      name: integer;
      size: integer;
	end;
  Voice8Header = record
      oneShotHiSamples: integer; { length of highest octave one-shot part }
      repeatHiSamples: integer; {length of highest octave repeat part }
      samplesPerHiCycle: integer; { frequency }
      samplesPerSec: short; { sample rate }
      ctOctave: byte; { number of octaves of waveforms }
      sCompression: byte; { 0 = none, 1 = FibDelta }
      volume: integer; { 0 = silent, 0x10000 = max }
    end;



var
  srcName, destName: string;
  srcFile, destFile: text;
  freq        : short;
  MacLength   : integer;
  success     : boolean;
  SampleChunk : array [1..1000] of byte;
  ASample,
  ChunkLength,
  CounterMain,
  CounterAux  : short;



procedure Usage();
  begin
    WriteLn('Usage: Opus8 src dest freq');
    exit(5);
  end;



{ converts ascii string to a signed integer in base 10 }
function atoi10(s : string) : integer;
var
  Multiplier : integer;
  Numb       : integer;
  Counter    : short;
  sign       : integer;
begin
  Multiplier := 1;
  Numb := 0;
  Counter := 4;
  if s[0] = '-'
    then sign := -1;
	else sign := 1;

  for Counter := 4 downto 0 do
  begin
      if s[Counter] > chr(0) then
      begin
          Numb := Numb + ((ord(s[Counter]) - 48) * Multiplier);
          Multiplier := Multiplier * 10;
      end;
  end;
  atoi10 := Numb;
end;



function FileSize(FileName: string): integer;
  var
    fInfo: FileInfoBlockPtr;
    fLock: FileLock;
    fSz: integer;

  begin
    fSz := 0;
    fLock := Lock(FileName, SHARED_LOCK);
    if fLock <> NIL
	then
	  begin
        new(fInfo);
        if Examine(fLock, fInfo)
        then fSz := fInfo^.fib_Size
        dispose(fInfo);
        UnLock(fLock);
      end;
    FileSize := fSz;
  end;



{ translates an integer to a flat array }
procedure c32toa(c : integer;
                 VAR Fin : SArray);
VAR
  Result : array [1..8] of short;
  index,
  Count  : short;
begin
  for Count := 1 to 4 do
    Fin[Count] := chr($00);

  for index := 8 downto 1 do
    begin
      Result[index] := Benign AND 15;
      Benign := Benign div 16;
    end;

  Count := 1;
  for index := 1 to 4 do
    begin
      Fin[index] := (CHR((Result[Count] * 16) + Result[Count+1]));
      Count := Count + 2;
    end;

end;



procedure WriteTheHeader(bitRate: short;
                         fileSz: integer);
begin
  Write(OutFile, tagForm, Len, tag8svx, tagVhdr, CHR($00), CHR($00), CHR($00),
  CHR($14), fileSz+40, CHR($00), CHR($00), CHR($00), CHR($00), CHR($00), CHR($00),
  CHR($00), CHR($00), bitRate, CHR($01), CHR($00), CHR($00), CHR($01),
  CHR($00), CHR($00), 'BODY', fileSz);
end;



begin

  srcName := AllocString(256);
  destName := AllocString(256);
  sndFreq := AllocString(256);

  GetParam(1, srcName);
  if srcName[0] = chr(0) then Usage;

  GetParam(2, destName);
  if destName[0] = chr(0) then Usage;

  GetParam(3, sndFreq);
  if sndFreq[0] = chr(0) then Usage;
  freq := atoi10(sndFreq);

  MacLength := FileSize(srcName);

  success := ReOpen(InFileName, InFile);
  if not success then
	begin
      WriteLn('cannot open source file');
	  exit(5);
	end;

  success := Open(OutFileName, OutFile);
  if not success then
    begin
      WriteLn('cannot create destination file');
	  exit(5);
	end;

  WriteTheHeader(freq, MacLength);

  while MacLength > 0 do
    begin
      ChunkLength := 1000;

      if MacLength > ChunkLength then
        MacLength := MacLength - ChunkLength
      else
        begin
          ChunkLength := MacLength;
          MacLength := 0;
        end;

      for CounterAux := 1 to ChunkLength do
        Read(InFile, SampleChunk[CounterAux]);

      for CounterAux := 1 to ChunkLength do
        begin
          ASample := (ord(SampleChunk[CounterAux]) - 128);
          if ASample < 0 then
            ASample := ASample + 256;
          SampleChunk[CounterAux] := chr(ASample);
        end;

      for CounterAux := 1 to ChunkLength do
        Write(OutFile, SampleChunk[CounterAux]);

    end;

    Close(InFile);
    Close(OutFile);
    FreeString(InFileName);
    FreeString(OutFileName);

end.
