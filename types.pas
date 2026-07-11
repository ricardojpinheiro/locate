(*<types.pas>
 * New types definition and function to extend and
 * compatibilize Turbo Pascal 3 with new Pascal
 * and Delphi versions.
 * CopyLeft (c) since 1995 by PopolonY2k.
 *)

(**
  *
  * $Id: types.pas 103 2020-06-17 00:40:53Z popolony2k $
  * $Author: popolony2k $
  * $Date: 2020-06-17 00:40:53 +0000 (Wed, 17 Jun 2020) $
  * $Revision: 103 $
  * $HeadURL: file:///svn/p/oldskooltech/code/msx/trunk/msxdos/pascal/types.pas $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * -
 *)

(* Module useful constants *)

Const                  ctMaxPath         = 127; { Maximum path size - MSXDOS2 }

(**
  * New types definitions
  *)
Type    TTinyString     =   String[40];             { String 40 byte size }
        TString        =    String[255];            { String 255 byte size }
        TFileName      =    String[ctMaxPath];      { File name path type }

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
