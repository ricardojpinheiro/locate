Program TESTDOS2FILE;

{$i d:types.inc}
{$i d:memory.inc}
{$i d:msxdos.inc}
{$i d:msxdos2.inc}
{$i d:dos2file.inc}
{$i d:dos2err.inc}
{$i d:dpb.inc}

{$r+}
{$v+}

Var
      nFileHandle     : Byte;
      nErrorCode      : Byte;
      strErrorMSg     : TMSXDOSString;
      strFileName     : TFileName;
      nBufferSize     : Integer;
      nRecord         : Integer;
      nNewPos         : Integer;
      aBuffer         : array[0..255] of byte;
      pData           : Pointer;
      nCount          : Integer;
      nRead           : Integer;
      bEOF            : Boolean;
      bODEGA          : Boolean;
      bUNDA           : string[8];
      bATATA          : string[8];
      bOLA            : char;
      i, j, k         : integer;

Begin
  ClrScr;

  strFileName := 'd:\q.dat';
  nBufferSize := SizeOf( aBuffer );
  nRecord     := 1;
  nFileHandle := FileOpen( strFileName, 'rw' );
  {pData       := Ptr( Addr( aBuffer ) );}
  bEOF        := False;

  If( nFileHandle In [ctInvalidFileHandle,
                      ctInvalidOpenMode] )  Then
  Begin
    nErrorCode := GetLastErrorCode;

    GetErrorMessage( nErrorCode, strErrorMsg );
    WriteLn( strErrorMsg );
    Exit;
  End;

  While( Not bEOF ) Do
  Begin
    Write( 'Current Record -> ', nRecord, ' Type new record number ' );
    ReadLn( nRecord );

    FillChar( aBuffer, SizeOf( aBuffer ), ' ' );

    bODEGA := FileSeek( nFileHandle, 0, ctSeekSet, nNewPos );

    For nCount := 1 To nRecord Do
      If( Not FileSeek( nFileHandle,
                        ( nBufferSize {* nRecord} ),
                        ctSeekCur,
                        nNewPos ) ) Then
      Begin
        nErrorCode := GetLastErrorCode;

        GetErrorMessage( nErrorCode, strErrorMsg );
        WriteLn( strErrorMsg );
        Exit;
      End;

    nRead := FileBlockRead( nFileHandle, aBuffer, nBufferSize );

    If( nRead = ctReadWriteError )  Then
    Begin
       nErrorCode := GetLastErrorCode;

       GetErrorMessage( nErrorCode, strErrorMsg );
       WriteLn( strErrorMsg );
       bEOF := True;
    End;

    aBuffer[0] := ord('0');
    aBuffer[1] := ord('0');

    For nCount := 2 To ( nBufferSize - 1 ) Do
    Begin
        bOLA := Char(aBuffer[nCount]);
        aBuffer[nCount - 2] := ord(bOLA);
    End;

    For nCount := 0 To ( nBufferSize - 1 ) Do
        Write(Char(aBuffer[nCount]));
    WriteLn;
{    
    for nCount := 0 to ( nBufferSize - 2 ) do
        bUNDA[nCount] := chr(32);
}
    bOLA := ' ';    
    writeln('nCount: ');
    readln(nCount);
   
        i := 0;
        while bOLA <> ',' do
        begin
            bOLA := chr(aBuffer[(i + 7 * (nCount - 1))]);

            writeln('bOLA: ',bOLA, ' i: ',i, ' (i + 7 * (nCount - 1)): ', (i + 7 * (nCount - 1)));

            bUNDA[i + 1] := bOLA;
            i := i + 1;
        end;
{
        writeln('bUNDA: ', bUNDA);
        writeln('total: ', i);
}
        j := i;
{
        writeln('virgula: ', j);
}        
        bOLA := bUNDA[i - 1];
{
        writeln('bOLA: ', bOLA);
        writeln('length(bUNDA): ', length(bUNDA));
}
        delete(bUNDA, i - 1, length(bUNDA));
{
        writeln('bUNDA nova: ', bUNDA);
}        
        val(bUNDA, k, nCount);

        writeln('j: ',j, ' Hash em texto: ', bUNDA, ' Letra: ', bOLA, ' Hash: ',k);
        
    WriteLn( 'Record ( ', nRecord, ' ) READ -> ', nRead, ' NEWPOS ', nNewPos );

    {nPosition := Succ( nPosition );}
  End;

  If( Not FileClose( nFileHandle ) )  Then
  Begin
    nErrorCode := GetLastErrorCode;
    GetErrorMessage( nErrorCode, strErrorMsg );
    WriteLn( strErrorMsg );
  End;

End.
