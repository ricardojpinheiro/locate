(*<msxdos.pas>
 * MSXDOS and CP/M structures definitions and functions.
 * Some data structures were converted from ASCII Corp. MSX-C Compiler and
 * others from books and specifications about MSX disk management.
 * CopyLeft (c) since 1995 by PopolonY2k.
 *)

(**
  *
  * $Id: msxdos.pas 103 2020-06-17 00:40:53Z popolony2k $
  * $Author: popolony2k $
  * $Date: 2020-06-17 00:40:53 +0000 (Wed, 17 Jun 2020) $
  * $Revision: 103 $
  * $HeadURL: file:///svn/p/oldskooltech/code/msx/trunk/msxdos/pascal/msxdos.pas $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * - types.pas;
 *)

(* BDOS/MSXDOS functions list - Official function names *)

Const   
        ctSetDrive             = $E;    { set default drive               }
        ctOpen                 = $F;    { open file                       }
        ctGetDrive             = $19;   { get default drive               }

(**
  * Execute a MSX BDOS function.
  * @param regs The registers needed to call a specific DOS2 function;
  *)
Procedure MSXBDOS( Var regs : TRegs );
Var
        nHL, nDE, nBC,
        nIX, nIY       : Integer;
        nA, nF         : Byte;
Begin
  nA  := regs.A;
  nHL := regs.HL;
  nDE := regs.DE;
  nBC := regs.BC;
  nIX := regs.IX;
  nIY := regs.IY;

  InLine( $F5/                  { PUSH AF      ; Push all registers  }
          $C5/                  { PUSH BC                            }
          $D5/                  { PUSH DE                            }
          $E5/                  { PUSH HL                            }
          $DD/$E5/              { PUSH IX                            }
          $FD/$E5/              { PUSH IY                            }
          $3A/nA/               { LD A , (nA )                       }
          $ED/$4B/nBC/          { LD BC, (nBC)                       }
          $ED/$5B/nDE/          { LD DE, (nDE)                       }
          $2A/nHL/              { LD HL, (nHL)                       }
          $DD/$2A/nIX/          { LD IX, (nIX)                       }
          $FD/$2A/nIY/          { LD IY, (nIY)                       }
          $CD/$05/$00/          { CALL 0005H - BDOS call             }
          $32/nA/               { LD (nA ), A                        }
          $ED/$43/nBC/          { LD (nBC), BC                       }
          $ED/$53/nDE/          { LD (nDE), DE                       }
          $22/nHL/              { LD (nHL), HL                       }
          $DD/$22/nIX/          { LD (nIX), IX                       }
          $FD/$22/nIY/          { LD (nIY), IY                       }
          $F5/                  { PUSH AF                            }
          $E1/                  { POP HL                             }
          $22/nF/               { LD (nF), HL                        }
          $FD/$E1/              { POP YI       ; Pop all registers   }
          $DD/$E1/              { POP IX                             }
          $E1/                  { POP HL                             }
          $D1/                  { POP DE                             }
          $C1/                  { POP BC                             }
          $F1                   { POP AF                             }
        );

  (* Update caller register struct *)
  regs.A  := nA;
  regs.F  := nF;
  regs.BC := nBC;
  regs.DE := nDE;
  regs.HL := nHL;
  regs.IY := nIY;
  regs.IX := nIX;
End;
