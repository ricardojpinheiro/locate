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

{$i d:memory.inc}
{$i d:types.inc}
{$i d:dos.inc}
{$i d:dos2file.inc}
{$i d:dpb.inc}

const
    tamanho = 2047;

var 
    arq : byte;
    i : byte;
    inicio, fim: integer;
    retorno, j : integer;
    resultado, fechou: boolean;
    nomearquivo: TFileName;
    vetor : Array[0..tamanho] Of Char; 
(*    vetor : string[tamanho];  *)
(**)
        dpb: TDPB;
        nDrive: Byte;
    
BEGIN
    nomearquivo := 'A.hsh';
    arq := FileOpen(nomearquivo,'r');

    nDrive := 0;
    if (GetDPB(nDrive, dpb) = ctError ) then
    begin
        writeln('Erro ao obter o DPB');
        halt;
    end;
    
    for i:=0 to tamanho do
        vetor[i] := ' ';
{      
    with dpb do
    begin
        writeln('DPB: ');
        writeln('Numero do drive: ',DrvNum);
        writeln('Formato do disco: ', DiskFormat);
        writeln('Bytes por setor: ', BytesPerSector);
        writeln('Lados do disco: ', DiskSides);
        writeln('Setores por cluster: ',SectorsbyCluster);
        writeln('Setores reservados: ',ReservedSectors);
        writeln('Numero de FATs: ',FATCount);
        writeln('Entradas de diretorio: ',DirectoryEntries);
        writeln('Clusters no disco: ',DiskClusters);
        writeln('Setores por FAT: ',SectorsByFAT);
    end;
}
    writeln('Abriu: ',arq);
    writeln('Inicio: '); readln(inicio);
    writeln('Fim: '); readln(fim);
    writeln;

    for j := inicio to fim do
    begin
        resultado := FileSeek(arq, ((j * dpb.BytesPerSector) div 2), 0, retorno);
        i := FileBlockRead(arq, vetor, 255);
        writeln(resultado, ' i: ',i);
        write(j,'->');

        for i := 0 to 255 do
            write(vetor[i]);

        writeln;
    end;
    
    fechou := FileClose(arq);
	writeln('Fechou');
	
END.
