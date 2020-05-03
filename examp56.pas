Program Example56;

{ Program to demonstrate the Seek function. }

Var
  F : File;
  I,J : integer;

begin
  { Create a file and fill it with data }
  Assign (F,'test.tmp');
  Rewrite(F); { Create file }
  Close(f);
  ReSet (F); { Opened read/write }
  For I:=0 to 10 do
    BlockWrite (F,I,1);
  { Go Back to the begining of the file }
  Seek(F,0);
  For I:=0 to 10 do
    begin
    BlockRead (F,J,1);
    write(J);
    If J<>I then
      Writeln (' Error: expected ' ,I,', got ',J);
    end;
    writeln;
  Close (f);
end.
