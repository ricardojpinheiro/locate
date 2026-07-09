(*<msxdos2.pas>
 * MSXDOS2 function call structures definitions and functions.
 * CopyLeft (c) since 1995 by PopolonY2k.
 *)

(**
  *
  * $Id: msxdos2.pas 98 2015-08-21 01:28:40Z popolony2k $
  * $Author: popolony2k $
  * $Date: 2015-08-21 01:28:40 +0000 (Fri, 21 Aug 2015) $
  * $Revision: 98 $
  * $HeadURL: file:///svn/p/oldskooltech/code/msx/trunk/msxdos/pascal/msxdos2.pas $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * - types.pas;
 * - msxdos.pas;
 *)

(*
 * MSXDOS2 function call list - Official function names.
 * Thanks to MSX Assembly pages at:
 * http://map.grauw.nl/resources/dos2_functioncalls.php
 *)

Const     
          ctGetCurrentDir                 = $59;
          ctChangeCurrentDir              = $5A;
          ctGetEnvironmentItem            = $6B;
          ctGetMSXDOSVersionNumber        = $6F;


(**
  * The struct representing the MSXDOS version number.
  *)
Type TMSXDOSVersion = Record
  nKernelMajor,
  nKernelMinor,
  nSystemMajor,
  nSystemMinor    : Byte;
End;


(**
  * Return the MSXDOS version.
  * @param version The @see TMSXDOSVersion reference to
  * the struct to receive the MSXDOSVersion;
  *)
Procedure GetMSXDOSVersion( Var version : TMSXDOSVersion );
Var
       regs  : TRegs;
Begin
  FillChar( regs, SizeOf( regs ), 0 );
  regs.C:= ctGetMSXDOSVersionNumber;
  MSXBDOS( regs );

  If( regs.A = 0 )  Then
    With version Do
    Begin
      nKernelMajor := regs.B;
      nKernelMinor := regs.C;
      nSystemMajor := regs.D;
      nSystemMinor := regs.E;
    End;
End;
