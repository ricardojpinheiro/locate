(*<dos2err.pas>
 * Wrapper to MSXDOS2 error messages management calls.
 * CopyLeft (c) since 1995 by PopolonY2k.
 *)

(**
  *
  * $Id: dos2err.pas 98 2015-08-21 01:28:40Z popolony2k $
  * $Author: popolony2k $
  * $Date: 2015-08-21 01:28:40 +0000 (Fri, 21 Aug 2015) $
  * $Revision: 98 $
  * $HeadURL: file:///svn/p/oldskooltech/code/msx/trunk/msxdos/pascal/dos2err.pas $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * - memory.pas;
 * - types.pas;
 * - msxdos.pas;
 * - msxdos2.pas;
 *)

Const       ctMSXDOSMsgSize = 65;  { Error message buffer size }


(**
  * MSXDOS error and message string.
  *)
Type TMSXDOSString = String[ctMSXDOSMsgSize];


(**
  * Get the error code, caused by the previous MSX-DOS function call.
  *)
Function GetLastErrorCode : Byte;
Var
       regs  : TRegs;

Begin
  regs.C := ctGetPreviousErrorCode;
  MSXBDOS( regs );
  GetLastErrorCode := regs.B;
End;

(**
  * Get the error message based on MSX-DOS error code passed by
  * parameter;
  * @param nErrorCode The error code to get the message string;
  * @param strErrMsg A reference to string that will receive the error
  * message;
  *)
Procedure GetErrorMessage( nErrorCode : Byte; Var strErrMsg : TMSXDOSString );
Var
      regs      : TRegs;
      szErrMsg  : Array[0..ctMSXDOSMsgSize] Of Char;
      nZeroPos  : Byte;

Begin
  strErrMsg := '';
  regs.C    := ctExplainErrorCode;
  regs.B    := nErrorCode;
  regs.DE   := Addr( szErrMsg );
  MSXBDOS( regs );

  If( ( regs.B = 0 ) Or ( regs.B = nErrorCode ) )  Then
  Begin
    nZeroPos := Pos( #0, szErrMsg );

    If( nZeroPos > 0 )  Then
    Begin
      strErrMsg[0] := Char( nZeroPos );
      Move( szErrMsg, strErrMsg[1], nZeroPos );
    End;
  End;
End;

