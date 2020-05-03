{
   locate03.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
}

program locate03;

const
	tamanhonomearquivo = 40;
	tamanhototalbuffer = 127;
	tamanhodiretorio = 87;
	max = 5000;

type
	absolutepath = string[tamanhodiretorio];
	filename = string[tamanhonomearquivo];
	buffervector = string[tamanhototalbuffer];
	registerfile = file;
	registro = record
		hash: integer;
		nomearquivo: string[tamanhonomearquivo];
		diretorio: string[tamanhodiretorio];
	end;
	registervector = array[1..max] of integer;
	
var
	arquivoregistros: registerfile;
 	nomearquivoregistros: filename;
 	vetorregistros: registervector;
 	vetorbuffer: buffervector;
 	temporario: string[5];
 	pesquisa: filename;
 	b, modulo, tamanho: integer;
 	i, j, hash, resultado: integer;
 	posicao, tentativas: integer;


procedure buscabinarianomearquivo (vetorregistros: registervector; hash: integer; var posicao, tentativas: integer);
var
	comeco, meio, fim: integer;
	encontrou: boolean;
			
begin
	comeco:=1;
	tentativas:=1;
	fim:=filesize(arquivoregistros)-1;
	encontrou:=false;
	while (comeco <= fim) and (encontrou = false) do
	begin
		meio:=(comeco+fim) div 2;

 		writeln('Comeco: ',comeco,' Meio: ',meio,' fim: ',fim,' hash: ',hash,' Pesquisa: ',vetorregistros[meio]);
		
		if (hash = vetorregistros[meio]) then
			encontrou:=true
		else
			if (hash < vetorregistros[meio]) then
				fim:=meio-1
			else
				comeco:=meio+1;
		tentativas:=tentativas+1;
	end;
	if encontrou = true then
		posicao:=meio;
end;

function existearquivo (var arquivoregistros: registerfile; nomearquivoregistros: filename): boolean;
begin
	assign(arquivoregistros,nomearquivoregistros);
	{$i-}
	reset(arquivoregistros); 
	{$i+}
	existearquivo:=(IOResult = 0);
end;

procedure abrearquivoregistros (nomearquivoregistros: filename);
begin
	assign(arquivoregistros,nomearquivoregistros);
	reset(arquivoregistros);
end;

procedure fechaarquivoregistros;
begin
	close(arquivoregistros);
end;

procedure learquivoregistros (var arquivoregistros: registerfile; var vetorregistros: registervector);
var
	i, retorno: integer;
	vetorbuffer: buffervector;
	temporario: string[5];
	
begin
	retorno:=0;
	for i:=1 to filesize(arquivoregistros) do
	begin
		temporario:=' ';
		seek(arquivoregistros,i-1);
		blockread(arquivoregistros,vetorbuffer,1);
{	Pega o hash e coloca no vetor. }		
		temporario:=copy(vetorbuffer,1,pos(',',vetorbuffer)-1);
		val(temporario,vetorregistros[i],retorno);
{
  		writeln('Registro ',i-1,': ',vetorregistros[i-1]);
}
	end;
	vetorregistros[i]:=maxint;
end;

procedure leregistronoarquivo(var arquivoregistros: registerfile; var vetorbuffer: buffervector; posicao: integer);

begin
	seek(arquivoregistros,posicao-1);
	blockread(arquivoregistros,vetorbuffer,1);
	writeln(vetorbuffer);
end;

function calculahash (nomearquivo: filename): integer;
var
	i, hash: integer;
	a, hash2: real;
	
begin
	hash:=0;
	hash2:=0.0;
	for i:=1 to length(nomearquivo) do
	begin
{	Aqui temos um problema. A funcao modulo nao pode ser usada com reais
		e foi necessario usar reais porque o valor e muito grande para
		trabalhar com inteiros - estoura o limite.
		Modulo = resto da divisao inteira: c <- a - b * (a / b).
}
		a := (hash2 * b + ord(nomearquivo[i]));
		hash2 := (a - modulo * int(a / modulo));
		hash:=round(hash2);
	end;
	calculahash:=hash;
end;

BEGIN
	nomearquivoregistros:='teste.dat';
{ Abre o arquivo, informa números dele e vai pra busca	}
 	writeln('Abre arquivo de registros');
	abrearquivoregistros(nomearquivoregistros);
{
 	tamanho:=filesize(arquivoregistros);
	writeln('Tamanho: ',tamanho); 
}
{ Vai no fim do arquivo e pega os valores de b e modulo, para calcular o hash }
	seek(arquivoregistros,filesize(arquivoregistros)-1);
	blockread(arquivoregistros,vetorbuffer,1);
	temporario:=copy(vetorbuffer,1,pos(',',vetorbuffer)-1);
	val(temporario,b,resultado);
	delete(vetorbuffer,1,pos(',',vetorbuffer));
	temporario:=copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
	val(temporario,modulo,resultado);

	writeln('b: ',b,' modulo: ',modulo);
	
{ Le o arquivo todo, pegando todos os numeros de hash e salvando num vetor } 
	writeln('Le arquivo de registros');
	learquivoregistros(arquivoregistros,vetorregistros);
{ Pede o nome exato de um arquivo a ser procurado }
	write('Insira o nome exato do arquivo: ');
	readln(pesquisa);
{ Calcula o hash do nome da pesquisa } 
	hash:=calculahash(pesquisa);
	writeln('Hash: ',hash);
{ Faz a busca binaria no vetor }
	buscabinarianomearquivo(vetorregistros, hash, posicao, tentativas);
	writeln('Posicao: ',posicao,' tentativas: ',tentativas);
{ Tendo a posicao certa, le o registro e apresenta os dados na tela. 
  Ou entao, diz que nao tem aquele nome no arquivo }
	leregistronoarquivo(arquivoregistros,vetorbuffer,posicao);
	if posicao <> 0 then
		writeln('Posicao: ',posicao)
	else
		writeln('Arquivo nao encontrado.');
{ Fecha o arquivo } 
	fechaarquivoregistros;
END.
