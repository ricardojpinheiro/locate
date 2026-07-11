(*<msxdosdr.pas>
 * MSXDOSdr function call structures definitions and functions.
 * CopyLeft (c) since 1995 by RJP.
 *)

(**
  *
  * $Id: msxdosdr.pas 98 2026-07-08 02:23:38Z RJP $
  * $Author: RJP $
  * $Date: 2026-07-08 02:23:38 +0000 (Wed, 08 Jul 2026) $
  * $Revision: 98 $
  * $HeadURL: file:///svn/p/oldskooltech/code/msx/trunk/msxdos/pascal/msxdosdr.pas $
  *)

(*
 * This module depends on folowing include files (respect the order):
 * - types.pas;
 * - msxdos.pas;
 * - msxdos2.pas;
 *)

(*
 * Return the current directory.
 *)

function GetCurrentDirectory: TFileName;
var
    OriginalPath: String[ctMaxPath];
    szOriginalPath: array [0..ctMaxPath] of Byte;
<<<<<<< HEAD
	DriveLetter: Char;
	i: Integer;
	Registers: TRegs;

begin
	FillChar (OriginalPath, 	SizeOf (OriginalPath)	, chr(32));
	FillChar (szOriginalPath, 	SizeOf (szOriginalPath)	, chr(32));
=======
    DriveLetter: Char;
    i: Integer;
    Registers: TRegs;

begin
    FillChar (OriginalPath,     SizeOf (OriginalPath)   , chr(32));
    FillChar (szOriginalPath,   SizeOf (szOriginalPath) , chr(32));
>>>>>>> origin/main

    with Registers do
    begin
        C := ctGetDrive;
    end;
    MSXBDOS (Registers);

<<<<<<< HEAD
	DriveLetter := chr(Registers.A + 65);
=======
    DriveLetter := chr(Registers.A + 65);
>>>>>>> origin/main

    with Registers do
    begin
        C := ctGetCurrentDir;
        B := 0;
        DE := addr ( szOriginalPath );
    end;
    MSXBDOS (Registers);

    i := 0;
<<<<<<< HEAD
    while 	(chr(szOriginalPath[i]) <> chr(0)) 	AND
			(chr(szOriginalPath[i]) <> chr(32)) do
	begin
		OriginalPath[i + 1] := chr(szOriginalPath[i]);
		i := i + 1;
	end;

	OriginalPath[i] := chr(szOriginalPath[i - 1]);

	Insert (DriveLetter + chr(58) + chr(92), OriginalPath, 1);

	GetCurrentDirectory := OriginalPath;
=======
    while   (chr(szOriginalPath[i]) <> chr(0))  AND
            (chr(szOriginalPath[i]) <> chr(32)) do
    begin
        OriginalPath[i + 1] := chr(szOriginalPath[i]);
        i := i + 1;
    end;

    OriginalPath[i] := chr(szOriginalPath[i - 1]);

    Insert (DriveLetter + chr(58) + chr(92), OriginalPath, 1);

    GetCurrentDirectory := OriginalPath;
>>>>>>> origin/main
end;

(*
 * Changes the directory. It's a function because it returns the status byte.
 *)

function ChangeDirectory(Path: TString): Byte;
var
<<<<<<< HEAD
	Parameters: String[ctMaxPath];
	DriveLetter, i: Byte;
	Registers: TRegs;

begin
	DriveLetter := (ord( Copy (Path, 1, 1) ) - 65);

	with Registers do
	begin
		C := ctSetDrive;
		E := DriveLetter;
	end;

	MSXBDOS (Registers);

	FillChar(Parameters, 	ctMaxPath, chr(32));

	for i := 1 to Length(Path) do
		Parameters[i - 1] := Path[i];
	Parameters[i] := #0;

	with Registers do
	begin
		C := ctChangeCurrentDir;
		DE := addr (Parameters);
	end;
	MSXBDOS (Registers);

	ChangeDirectory := Registers.A;
=======
    Parameters: String[ctMaxPath];
    DriveLetter, i: Byte;
    Registers: TRegs;

begin
    DriveLetter := (ord( Copy (Path, 1, 1) ) - 65);

    with Registers do
    begin
        C := ctSetDrive;
        E := DriveLetter;
    end;

    MSXBDOS (Registers);

    FillChar(Parameters,    ctMaxPath, chr(32));

    for i := 1 to Length(Path) do
        Parameters[i - 1] := Path[i];
    Parameters[i] := #0;

    with Registers do
    begin
        C := ctChangeCurrentDir;
        DE := addr (Parameters);
    end;
    MSXBDOS (Registers);

    ChangeDirectory := Registers.A;
>>>>>>> origin/main
end;

(*
 * Return the directory which is written into a MSX-DOS 2 environment variable.
 *)

function GetPathFromEnvironmentVariable (EnvironmentVariable: TString): TFileName;
var
<<<<<<< HEAD
	Parameters, Path: String[ctMaxPath];
	DriveLetter: Char;
	i: Integer;
	Registers: TRegs;

begin
	FillChar(Path, 			ctMaxPath, chr(32));
	FillChar(Parameters, 	ctMaxPath, chr(32));

	for i := 1 to Length(EnvironmentVariable) do
		Parameters[i - 1] := EnvironmentVariable[i];
	Parameters[i] := #0;
=======
    Parameters, Path: String[ctMaxPath];
    DriveLetter: Char;
    i: Integer;
    Registers: TRegs;

begin
    FillChar(Path,          ctMaxPath, chr(32));
    FillChar(Parameters,    ctMaxPath, chr(32));

    for i := 1 to Length(EnvironmentVariable) do
        Parameters[i - 1] := EnvironmentVariable[i];
    Parameters[i] := #0;
>>>>>>> origin/main

    Path[0] := #0;

    with Registers do
    begin
        B := sizeof ( Path );
        C := ctGetEnvironmentItem;
        HL := addr ( Parameters );
        DE := addr ( Path );
    end;

    MSXBDOS ( Registers );

    DriveLetter := Path[0];

    insert(DriveLetter, Path, 1);

    GetPathFromEnvironmentVariable := Path;

end;

