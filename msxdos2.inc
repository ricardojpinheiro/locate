(*<msxdos2.pas> CopyLeft (c) since 1995 by PopolonY2k. *)
Const
	ctCreateFileHandle              = $44;
	ctCloseFileHandle               = $45;
	ctDuplicateFileHandle           = $47;
	ctEnsureFileHandle              = $46;
	ctMoveFileHandle                = $54;
	ctOpenFileHandle                = $43;
	ctReadFromFileHandle            = $48;
	ctWriteToFileHandle             = $49;

(* The struct representing the MSXDOS version number. *)
Type TMSXDOSVersion = Record
  nKernelMajor,
  nKernelMinor,
  nSystemMajor,
  nSystemMinor    : Byte;
End;

(* Return the MSXDOS version. *)
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
