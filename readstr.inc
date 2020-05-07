{readstr.inc}

Function WhereX:Byte;
   Var CSRX    :Byte Absolute $f3dd;
   Begin
     WhereX := CSRX;
   End;

Function WhereY:Byte;
   Var  CSRY    :Byte Absolute $f3dc;
   Begin
      WhereY := CSRY;
   End;



Function ReadCursorChar:Char;
    Var CSRX    :Byte Absolute $f3dd;
        CSRY    :Byte Absolute $f3dc;
        VramAddr:Integer;
        Ch      :Char;
    Begin
       VramAddr := (CSRY-1)*80 + CSRX-1;
       ReadVram(0,VramAddr,Addr(Ch),1);
       ReadCursorChar := Ch;
    End;


Function ReadCursorString(Len:Byte):StringType;

    Var CSRX    :Byte Absolute $f3dd;
        CSRY    :Byte Absolute $f3dc;
        VramAddr:Integer;
        St      :StringType;
    Begin
       VramAddr := (CSRY-1)*80 + CSRX-1;
       ReadVram(0,VramAddr,Addr(St[1]),Len);
       St[0] := Chr(Len);
       ReadCursorString := St;
    End;

Function ReadString(MaxLen:Byte):StringType;
  Var i     :Byte;
      Ch    :Char;
      St    :StringType;
  Begin
    St := '';
    i := 0;
    Repeat
      Read(kbd,Ch);
      Case Ch Of
       #30..#126,#128..#255 :
          Begin
           If i < Maxlen Then
             Begin
               i:= i + 1;
               Write(Ch);
               St := St+Ch;
             End
            Else  Write(#7);
          End;

       #8 : Begin
              If i > 0 Then
                Begin
                  i := i-1;
                  Write(Ch);Write(' ');Write(Ch);
                  St[0] := Chr(i);
                 End
              Else Write(#7);
            End;
      End; {Case}

    Until Ch = #13;

    ReadString := St;

 End; {ReadString}

