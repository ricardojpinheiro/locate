{New fastwrit.inc (TXTNAM added) Feb/March 1997}
{Uses wrtvram.inc}

{Inproved by Manuel Bilderbeek }

Type TPString = String[255];
Procedure FastWrite(St :TpString);

Var CSRX :Byte Absolute $F3DD;
    CSRY :Byte Absolute $F3DC;
    TXTNAM :Integer Absolute $f3b3;
    len  :Byte;
    VramLocation :Integer;
    Width:Byte;
Begin
   Width := Mem[$F3B0];
   If Width<80 then Width := 40 else Width := 80;
   Len := Ord(St[0]);
   VramLocation := (CSRY-1) * Width + CSRX-1 + TXTNAM;
   If VramLocation > 2000 Then VramLocation := 0;
   WriteVram(0,VramLocation,Addr(St)+1,Len);
   CSRY := ((VramLocation + Len) Div Width)+1 ;
   CSRX := ((VramLocation + Len) Mod Width)+1 ;
End; {FastWrite}

Procedure FastWriteln(St :TpString);

Var CSRX :Byte Absolute $F3DD;
    CSRY :Byte Absolute $F3DC;
    TXTNAM :Integer Absolute $f3b3;
    len  :Byte;
    VramLocation :Integer;
    Width:Byte;
Begin
   Width := Mem[$F3B0];
   If Width<80 then Width := 40 else Width := 80;
   Len := Ord(St[0]);
   VramLocation := (CSRY-1) * Width + CSRX-1 + TXTNAM;
   If VramLocation > 2000 Then VramLocation := 0;
   WriteVram(0,VramLocation,Addr(St)+1,Len);
   CSRY := (VramLocation + Len) Div Width+2 ;
   CSRX := 1;
End; {FastWriteln}


