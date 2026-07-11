(*
   locate.pas
   
   Copyright 2026 Ricardo Jurczyk Pinheiro <ricardojpinheiro@gmail.com>
   
   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
   MA 02110-1301, USA.
   
   
*)

program locate;

{$i d:types.pas}
{$i d:msxdos.pas}
{$i d:msxdos2.pas}
{$i d:msxdosdr.pas} 

type
(* 128 byte buffer, used by BlockRead procedure *)
    RegBuffer = array[1..128] of Byte;

var
(*	Files, and supporting variables. *)
    ArqBin                      : file;
    Buffer                      : RegBuffer;
    Line                        : TString;
    MSXDOSVersion               : TMSXDOSVersion;
    Parameters                  : TTinyString;
	DriveLetter      			: char;

(*	Filenames, and search entries. *)    
    
    SearchName, UppercaseName,  
    DatFileName                 : TString;

(*	Hashes. *)
    HashOriginal, TargetHash    : Real;
    
(*	Path. *)

	NewPath, OriginalPath		: String[ctMaxPath];

(*	Supporting variables. *)
    
    FirstLetter, c, option		: char; 
    i, Matches, Result          : integer;
  
(* Binary search control variables. *)
    First, Last, Lower, Upper, 
    Middle, Steps, ReadBlocks   : Integer;
    Found                       : Boolean;

(*	Statistics. *)

	TotalPerDB, Total			: Real;
  
(* Field division *)
    P1, P2, Code                : Integer;
    HashString                  : String[15];
    HashRegister                : Real;
    FilenameRegister            : String[36];
    PathRegister                : String[80];
    Registers                   : TRegs;

(* Command help *)

procedure LocateHelp;
begin
    WriteLn('Usage: locate <filename> <parameters>.');
    WriteLn('Find files by name in a quick way.');
    WriteLn;
    WriteLn('locate finds all files on the system');
    WriteLn('matching the given filename. It uses');
    WriteLn('some index files created by a Python');
    WriteLn('Python script, updatedbmsx.py, which');
    WriteLn('should be previously created in a ');
    WriteLn('Windows, Mac OS or Linux machine.');
    WriteLn;
    WriteLn('Parameters: ');
    WriteLn('/a  - Show all matches found.          ');
    WriteLn('/c  - Prints how many matches found.   ');
    WriteLn('/dX - Show matches which are related   ');
    WriteLn('      with the given drive letter (X). ');
    WriteLn('/f  - Prints filename, path and hash.  ');
    WriteLn('/ln - Stop after n matches.            ');
    WriteLn('/h  - Display this help and exit.      ');
    WriteLn('/v  - Show version information & exit. ');
    WriteLn;
    Halt;
end;

(* Command version.*)

procedure LocateVersion;
begin
    WriteLn('locate version 0.9'); 
    WriteLn('Copyright (c) 2026 Brazilian MSX Crew.');
    WriteLn('Some rights reserved.');
    WriteLn;
    WriteLn('License GPLv3+: GNU GPL v. 3 or later ');
    WriteLn('<https://gnu.org/licenses/gpl.html>');
    WriteLn('This is free software: you are free to');
    WriteLn('change and redistribute it. There is ');
    WriteLn('NO WARRANTY to the extent permitted ');
    WriteLn('by law.');
    WriteLn;
    Halt;
end;

(* Uppercase string. *)

function UpperCase (S: TString): TString;
var
    Idx: Integer;
begin
	for Idx := 1 to Length(S) do
		if (S[Idx] >= 'a') and (S[Idx] <= 'z') then
            S[Idx] := Upcase(S[Idx]);
    UpperCase := S;
end;

(* Convert raw bytes from BlockRead into a string. *)

procedure ConvertBufferToString (Buf: RegBuffer; var S: TString);
var
    Len, Idx: Integer;
begin
    Len := Buf[1];
    if Len > 127 then
        Len := 127;
    S[0] := Chr(Len);
    for Idx := 1 to Len do
        S[Idx] := Chr(Buf[Idx + 1]);
end;

(* Evaluate Hash using the DJB2 algorithm. *)

function DJB2HashCalculate (S: TString): Real;
var
    H   : Real;
    Idx : Integer;
begin
    H := 5381.0;
    for Idx := 1 to Length(S) do
    begin
        (* H * 33 + Ord(S[Idx]) *)
        H := (H * 33.0) + Ord(S[Idx]);
    
        (* Simulate the 32-bit upper limit (& 0xFFFFFFFF) which is 4294967296 *)
        H := H - (Int (H / 4294967296.0) * 4294967296.0);
    end;
    DJB2HashCalculate := H;
end;

(* Here we find which file would be opened. *)

procedure AskForFileName;
begin
(*  Uppercase the searched filename *)  
    UppercaseName := UpperCase(SearchName);

(*  Which is the first letter?*)
    FirstLetter := UppercaseName[1];
    if (FirstLetter >= 'A') and (FirstLetter <= 'Z') then
        DatFileName := FirstLetter + '.DAT'
    else
        DatFileName := 'NUM.DAT';
end;

(* Opens the corresponding file - there are some tests too. *)

procedure OpenFileName (Operation: Byte);
begin
	Case Operation of
		0:	begin
				Assign(ArqBin, DatFileName);
				{$I-}
				Reset(ArqBin);
				{$I+}

				if IOresult <> 0 then
				begin
					WriteLn('Error: Could not read the ', DatFileName, ' filename.');
					Halt;
				end;

			(* If the datfile is empty. *)

				if FileSize(ArqBin) = 0 then
				begin
					WriteLn('Error: Filename ', DatFileName, ' is empty.');
					Close(ArqBin);
					Halt;
				end;
			end;
		1: Close(ArqBin);
	end;
end;

(* Here goes all magic.*)
procedure BinarySearch;
begin
(* Evaluate stable hash *)
    TargetHash := DJB2HashCalculate(UppercaseName);

(* Binary Search by Hash: Init *)
    Steps := 0;
    Found := False;
    Lower := 0;
    Upper := FileSize(ArqBin) - 1;

    while (Lower <= Upper) and (not Found) do
    begin
        Steps := Steps + 1;
        Middle := (Lower + Upper) div 2;

        Seek(ArqBin, Middle);
        FillChar (Buffer, SizeOf(Buffer), chr(32));
        BlockRead(ArqBin, Buffer, 1, ReadBlocks);
        
        if ReadBlocks = 1 then
        begin
            FillChar (Line, SizeOf(Line), chr(32));
            ConvertBufferToString(Buffer, Line);

(* Cut the readed string in hash, filename and path *)
          
            P1 := Pos(',', Line);
            if P1 > 0 then
            begin
                HashString := Copy(Line, 1, P1 - 1);
                Val(HashString, HashRegister, Code);
                if Code <> 0 then HashRegister := -1;
                
(* If the calculated hash and the hash from the register are the same... *)

                if HashRegister = TargetHash then
                begin

(* First we need to get the path and the filename from the register. *)

                    PathRegister := Copy(Line, P1 + 1, Length(Line) - P1);
                    P2 := Pos(',', PathRegister);
                  
                    if P2 > 0 then
                        FilenameRegister := Copy(PathRegister, 1, P2 - 1)
                    else
                        FilenameRegister := '';

    (* If it's right... *)
                    
                        if FilenameRegister = UppercaseName then
                        begin
                            Found := True;
                            PathRegister := Copy(PathRegister, P2 + 1, Length(PathRegister) - P2);
                        end
                        else

    (* Maybe there is a hash collision. So... *)              

                            Lower := Middle + 1;
                end
                else
                    if HashRegister < TargetHash then
                        Lower := Middle + 1
                    else
                        Upper := Middle - 1;
            end
            else
                Lower := Middle + 1;
        end
        else
          Upper := Middle - 1;
    end;
end;

procedure SearchForElements(Element: Integer);
begin
    Seek(ArqBin, Element);
    FillChar (Buffer, SizeOf(Buffer), chr(32));
    BlockRead(ArqBin, Buffer, 1, ReadBlocks);
    
    if ReadBlocks = 1 then
    begin
        FillChar (Line, SizeOf(Line), chr(32));
        ConvertBufferToString(Buffer, Line);
        P1 := Pos(',', Line);
        if P1 > 0 then
        begin
            HashString := Copy(Line, 1, P1 - 1);
            Val(HashString, HashRegister, Code);
            if Code <> 0 then HashRegister := -1;
        end;
    end;
end;

procedure LookForMoreMatches (Option: Char);
begin
(* Checking for the upper side of Middle. *)
    Upper := Middle;
    Lower := Middle;
    HashOriginal := HashRegister;

(* Checking for the lower side of Middle + 1. *)
    while HashRegister = TargetHash do
    begin
        Lower := Lower + 1;
        SearchForElements (Lower);
    end;
    Last := Lower - 1;

    HashRegister := HashOriginal;
    
    while HashRegister = TargetHash do
    begin
        Upper := Upper - 1;
        SearchForElements (Upper);
    end;
    
    First := Upper + 1; 

    case option of
        'C': WriteLn ((Last - First) + 1, ' matches.');
        'L': if (First + Matches - 1) <= Last then
                    Last := First + Matches - 1;
		'A': for i := First to Last do
				begin
					SearchForElements (i);

					PathRegister := Copy(Line, P1 + 1, Length(Line) - P1);
					P2 := Pos(',', PathRegister);
						  
					if P2 > 0 then
						FilenameRegister := Copy(PathRegister, 1, P2 - 1)
					else
						FilenameRegister := '';
					PathRegister := Copy(PathRegister, P2 + 1, Length(PathRegister) - P2);
						
					WriteLn(PathRegister,'\',FilenameRegister);
				end;
	end;
end;

(* Print results, with some variations.*)
procedure PrintResults;
begin
    case option of
        'A':    LookForMoreMatches ('A');
        'C':    LookForMoreMatches ('C');
        'L':    LookForMoreMatches ('L');
        'F':    begin
                    WriteLn('Filename: ', FilenameRegister);
                    WriteLn('Hash    : ', HashString);
                    WriteLn('Path    : ', PathRegister);
                    WriteLn('Steps   : ', Steps);
                end;
        'D':    begin
                    c := PathRegister[1];
                    if DriveLetter = c then
                        WriteLn(PathRegister,'\',FilenameRegister);
                end;
        else
            WriteLn(PathRegister,'\',FilenameRegister);
    end;
end;

(* Show statistics of the database. *)
procedure Statistics;
begin
	TotalPerDB := 0;
	Total:= 0;

	OriginalPath := GetCurrentDirectory;
	NewPath := Uppercase(GetPathFromEnvironmentVariable ('locatedb'));
	Result := ChangeDirectory (NewPath);

	for i := 64 to 90 do
	begin
		if i = 64 then
			DatFileName := 'NUM.DAT' 
		else
			DatFileName := chr(i) + '.DAT'; 

		Assign(ArqBin, DatFileName);
		{$I-}
		Reset(ArqBin);
		{$I+}

		if IOresult = 0 then
		begin
			TotalPerDB := FileSize(ArqBin);
			
			WriteLn(DatFileName, ': ', TotalPerDB:0:0, ' entries.');
			
			Total := Total + TotalPerDB;

		end
		else
			WriteLn('Error: Could not read the ', DatFileName, ' filename.');
		
	end;
	
	Close(ArqBin);
	
	Writeln('Total: ', Total:0:0, ' entries.');

	Result := ChangeDirectory (OriginalPath);
	
	Halt;
end;

(* Main code.*)
begin
    GetMSXDOSVersion (MSXDOSVersion);

    if (MSXDOSVersion.nKernelMajor < 2) then
    begin
        WriteLn('MSX-DOS 1.x not supported.');
        Halt;
    end
    else
    begin
        for i := 1 to paramcount do
        begin
            Parameters := UpperCase(paramstr(i));
            c := Parameters[2];
            if Parameters[1] = '/' then
            begin
                delete(Parameters, 1, 2);
            (*  Parameters. *)
                case c of
                    'H': LocateHelp;        (* 	Help         			*)
                    'V': LocateVersion;     (* 	Version      			*)
                    'F': option := c;       (* 	All info     			*)
                    'S': Statistics;		(*	Statistics				*)
                    'D': begin
                            option := c;    (* 	Drive letter 			*)
                            DriveLetter := Parameters[3];
                         end;
                    'L': begin
                            option := c;    (* Stops at n matches.		*)
                            Val (Parameters, Matches, Code);
                         end;
                    'C': option := c;       (* Shows how many matches.	*)
                    'A': option := c;       (* Shows all matches.		*)
                    else LocateVersion; 
                end;
            end
            else
                SearchName := Uppercase(ParamStr(1));
        end;

		OriginalPath := GetCurrentDirectory;
		NewPath := Uppercase(GetPathFromEnvironmentVariable ('locatedb'));
		Result := ChangeDirectory (NewPath);

		AskForFileName;
        OpenFileName(0);
        BinarySearch;
        if Found then
            PrintResults;
        OpenFileName(1);

		Result := ChangeDirectory (OriginalPath);
    end;
end.

