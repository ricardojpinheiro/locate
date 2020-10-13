{
   locate02.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
    
   
}

program locate02;

const
	tamanhostring = 12;
	max = 100;

type
	filenameregistro = array[1..48] of char;
	filename = string[12];
	registro = record
			nomedoarquivo: filenameregistro;
			diretorio: array[1..80] of char;
	end;
	registerfile = file of registro;
	textfile = text;
	stringunica = string[1];
		
var
	i, j, posicao, tamanho, tentativas: integer;
	pesquisa: registro;
	arquivoregistros: registerfile;
	temporario, nomeregistros: filename;

procedure buscabinarianomearquivo (var pesquisa: registro; var posicao, tentativas: integer);
var
	comeco, meio, fim: integer;
	encontrou: boolean;
	ficha: registro;
	pesquisado, aserprocurado: string[tamanhostring];
	
begin
	comeco:=0;
	tentativas:=1;
	fim:=filesize(arquivoregistros);
	encontrou:=false;
	writeln('Fim: ',fim);
	for i:=1 to tamanhostring do
		pesquisado[i]:=pesquisa.nomedoarquivo[i];
		
	while (comeco < fim) and (encontrou = false) do
	begin
		meio:=(comeco+fim) div 2;
		seek(arquivoregistros,meio);
		read(arquivoregistros,ficha);

 		writeln('Meio: ',meio,' valor: ',ficha.nomedoarquivo,' Pesquisa: ',pesquisa.nomedoarquivo);

		for i:=1 to tamanhostring do
			aserprocurado[i]:=ficha.nomedoarquivo[i];

		if (pesquisado = aserprocurado) then
			encontrou:=true
		else
			if (pesquisado < aserprocurado) then
				fim:=meio-1
			else
				comeco:=meio+1;
		tentativas:=tentativas+1;
	end;
	if encontrou = true then
	begin
		posicao:=meio;
		pesquisa.nomedoarquivo:=ficha.nomedoarquivo;
	end;
end;

function existearquivo (nomeregistros: filename): boolean;
begin
	assign(arquivoregistros,nomeregistros);
	{$i-}
	reset(arquivoregistros); 
	{$i+}
	existearquivo:=(IOResult = 0);
end;

procedure fechaarquivo;
begin
	close(arquivoregistros);
end;

BEGIN
	nomeregistros:='teste.dat';
{ Abre o arquivo, informa números dele e vai pra busca	}
 	writeln('Abre arquivo de registros');
	assign(arquivoregistros,nomeregistros);
	reset(arquivoregistros);
	tamanho:=filesize(arquivoregistros);
	writeln('Tamanho: ',tamanho); 
		
	randomize;
	for i:=1 to 10 do
	begin
		j:=round(random(max));
		seek(arquivoregistros,j);
		read(arquivoregistros,pesquisa);
		writeln('Nome ',j,': ',pesquisa.nomedoarquivo,' Diretorio: ',pesquisa.diretorio);
	end;
		
	writeln('Tamanho: ',tamanho); 
	write('Nome a ser encontrado: ');
	readln(temporario);
	for i:=1 to tamanhostring do
		pesquisa.nomedoarquivo[i]:=temporario[i];
	buscabinarianomearquivo(pesquisa,posicao,tentativas);
	if posicao = 8294 then
		writeln('O numero ',pesquisa.nomedoarquivo,' nao esta no vetor')
	else
		writeln('O numero ',pesquisa.nomedoarquivo,' esta no vetor, Posicao: ',posicao,' apos ',tentativas,' tentativas.');
	fechaarquivo;
END.
