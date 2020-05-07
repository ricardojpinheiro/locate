(*<types.pas>
 * New types definition and function to extend and
 * compatibilize Turbo Pascal 3 with new Pascal
 * and Delphi versions.
 * CopyLeft (c) since 1995 by PopolonY2k.
 *)

(**
  *
  * $Id: types.pas 98 2015-08-21 01:28:40Z popolony2k $
  * $Author: popolony2k $
  * $Date: 2015-08-21 01:28:40 +0000 (Fri, 21 Aug 2015) $
  * $Revision: 98 $
  * $HeadURL: file:///svn/p/oldskooltech/code/msx/trunk/msxdos/pascal/types.pas $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * -
 *)

(* Module useful constants *)

Const                  ctMaxPath = 127;    { Maximum path size - MSXDOS2 }


(**
  * New types definitions
  *)
Type TInt24         = Array[0..2] Of Byte;     { 24Bit integer }
     TInt32         = Array[0..3] Of Byte;     { 32Bit integer }
     TTinyString    = String[40];              { String 40 byte size }
     PTinyString    = ^TTinyString;            { TTinyString pointer }
     TShortString   = String[80];              { String 80 byte size }
     PShortString   = ^TShortString;           { TShortString pointer }
     TString        = String[255];             { String 255 byte size }
     PString        = ^TString;                { TString pointer }
     TFileName      = String[ctMaxPath];       { File name path type }
     PFileName      = ^TFileName;              { TFileName pointer }
     THexadecimal   = String[2];               { Hexadecimal type }
     Pointer        = ^Byte;                   { Pointer generic type }
     TDynByteArray  = Array [0..1] Of Byte;    { Dynamic byte array }
     PDynByteArray  = ^TDynByteArray;          { Dynamic byte array pointer }
     TDynIntArray   = Array [0..1] Of Integer; { Dynamic int array }
     PDynIntArray   = ^TDynIntArray;           { Dynamic int array pointer }
     TSlotNumber    = Byte;                    { Slot identification }

(**
  * Date and time structures for MSXDOS functions
  *)
Type TTime = Record
  nHours,
  nMinutes,
  nSeconds,
  nCentiSeconds  : Byte;
End;

Type TDate = Record
  nDay,
  nMonth         : Byte;
  nYear          : Integer;
End;

Type TDateTime = Record
  date : TDate;
  time : TTime;
End;

(**
  * Z80 registers struct/union definition
  *)
Type TRegs = Record
  IX       : Integer;             { 16Bit index registers }
  IY       : Integer;

  Case Byte Of    { 8Bit registers and 16Bit registers - WORD_REGS }
    0 : ( C,B,E,D,L,H,F,A  : Byte );      { 8bit registers  }
    1 : ( BC,DE,HL,AF      : Integer );   { 16bit registers }
End;
