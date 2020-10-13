{
   teste de leitura popolony2k.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
   
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
   
   
}

program popolony2k;

{$X+}
{$W1}
{$A+}
{$R-}

{$i d:types.inc}
{$i d:dos.inc}
{$i d:dos2file.inc}

var 
    arq : byte;
    i : byte;
    inicio, fim, retorno, j : integer;
    resultado, fechou: boolean;
    nomearquivo: TFileName;
    vetor : Array[0..511] Of Char;

BEGIN
    nomearquivo := 'A.hsh';
    arq := FileOpen(nomearquivo,'r');
    writeln('Abriu: ',arq);
    writeln('Inicio: '); readln(inicio);
    writeln('Fim: '); readln(fim);
    writeln;

    for j := inicio to fim do
    begin
        for i := 0 to 511 do
            vetor[i] := ' ';
        resultado := FileSeek(arq, ( j * SizeOf( vetor ) ), 0, retorno);
        i := FileBlockRead(arq, vetor, 511);
        write('j: ', j, ' -> ');
        for i := 0 to 511 do
            write(vetor[i]);
        writeln;
    end;
    fechou := FileClose(arq);
	writeln('Fechou');
	
END.

