{
   locate04.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
  
* Este código pode ate ser rodado no PC, mas a prioridade e o MSX.
* Ele vai ler o arquivo de hashes e jogar para um vetor na memoria.
* O programa vai pedir um padrao de busca. O programa coloca o padrao
* todo em maiusculas - o MSX-DOS nao diferencia. Ele calcula o hash 
* desse padrao de busca, faz-se uma busca binaria nesse vetor e achando,
* le o registro no arquivo de registros, colocando a informacao na tela.
* Acrescentei um trecho de codigo para procurar por coincidencias (com
* base no hash) e imprimir todas as ocorrencias.
}

program locate04;

const
	tamanhonomearquivo = 40;
	tamanhototalbuffer = 127;
	tamanhodiretorio = 87;
	max = 1000;

type
	absolutepath = string[tamanhodiretorio];
	filename = string[tamanhonomearquivo];
	buffervector = string[tamanhototalbuffer];
	registerfile = file;
	hashfile = file;
	registro = record
		hash: integer;
		nomearquivo: string[tamanhonomearquivo];
		diretorio: string[tamanhodiretorio];
	end;
	registervector = array[1..max] of integer;
	
var
	arquivoregistros: registerfile;
 	arquivohashes: hashfile;
 	nomearquivoregistros: filename;
 	nomearquivohashes: filename;
 	vetorhashes: registervector;
 	vetorbuffer: buffervector;
 	pesquisa: filename;
 	ficha: registro;
 	b, modulo, tamanho, posicao, tentativas: integer;
 	j, hash, hashtemporario, cima, baixo: integer;
 	caractere: char;

procedure buscabinarianomearquivo (vetorhashes: registervector; hash: integer; var posicao, tentativas: integer);
var
	comeco, meio, fim: integer;
	encontrou: boolean;
			
begin
	comeco:=1;
	tentativas:=1;
	fim:=max;
	encontrou:=false;
	while (comeco <= fim) and (encontrou = false) do
	begin
		meio:=(comeco+fim) div 2;
{
 		writeln('Comeco: ',comeco,' Meio: ',meio,' fim: ',fim,' hash: ',hash,' Pesquisa: ',vetorhashes[meio]);
}		
		if (hash = vetorhashes[meio]) then
			encontrou:=true
		else
			if (hash < vetorhashes[meio]) then
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

procedure abrearquivohashes (nomearquivohashes: filename);
begin
	assign(arquivohashes,nomearquivohashes);
	reset(arquivohashes);
end;

procedure fechaarquivoregistros;
begin
	close(arquivoregistros);
end;

procedure fechaarquivohashes;
begin
	close(arquivohashes);
end;

procedure leregistronoarquivo(var arquivoregistros: registerfile; var vetorbuffer: buffervector; posicao: integer);
var
	hash, retorno: integer;
	hashemtexto: string[5];
	
begin
	retorno:=0;
	hashemtexto:='';
	seek(arquivoregistros,posicao-1);
	blockread(arquivoregistros,vetorbuffer,1);
{
 	writeln(vetorbuffer);
}

(* Copia o hash do nome do arquivo e apaga o que nao sera usado *)		

		fillchar(hashemtexto,length(hashemtexto),byte( ' ' ));
		hashemtexto := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
		delete(vetorbuffer,1,pos(',',vetorbuffer));
		val(hashemtexto,hash,retorno);
		ficha.hash := hash;

(* Copia o nome do arquivo e apaga o que nao sera usado *)
		fillchar(ficha.nomearquivo,length(ficha.nomearquivo),byte( ' ' ));
 		ficha.nomearquivo := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
		delete(vetorbuffer,1,pos(',',vetorbuffer));

(* Copia o diretorio e apaga o que nao sera usado *)
		fillchar(ficha.diretorio,length(ficha.diretorio),byte( ' ' ));
 		ficha.diretorio := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
		delete(vetorbuffer,1,pos(',',vetorbuffer));

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
(*	Aqui temos um problema. A funcao modulo nao pode ser usada com
	reais e foi necessario usar reais porque o valor e muito grande
	para trabalhar com inteiros - estoura o limite.
	Modulo = resto da divisao inteira: c <- a - b * (a / b).
*)
		a := (hash2 * b + ord(nomearquivo[i]));
		hash2 := (a - modulo * int(a / modulo));
		hash := round(hash2);
	end;
	calculahash := hash;
end;

procedure learquivohashes;
var
	i, j, k, hash, retorno: integer;
	vetorbuffer: buffervector;
	hashemtexto, temporario1, temporario2: string[5];
	
begin

(* Le de um arquivo separado o hash *)
(* Na posicao 0 temos o valor de b e o modulo. *)

	temporario1:=' ';
	fillchar(temporario1,length(temporario1),byte( ' ' ));
	temporario2:=' ';
	fillchar(temporario2,length(temporario2),byte( ' ' ));
	vetorbuffer:=' ';
	fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
	seek(arquivohashes,0);
	blockread(arquivohashes,vetorbuffer,1,retorno);
	delete(vetorbuffer,1,(pos(',',vetorbuffer)-5));
	temporario1 := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
	delete(vetorbuffer,1,pos(',',vetorbuffer));
	temporario2 := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
	delete(vetorbuffer,1,pos(',',vetorbuffer));
	val(temporario1,b,retorno);
	val(temporario2,modulo,retorno);
{
	writeln('b: ',b,' modulo: ',modulo);
}
(* Le com um blockread e separa, jogando cada hash em uma posicao em um vetor. *)

	i := 1;
	j := 1;
	hashemtexto := '';
	fillchar(vetorbuffer,length(vetorbuffer),byte( ' ' ));
	while i <= ((max div 6)+1) do
	begin
		seek(arquivohashes,i);
		blockread(arquivohashes,vetorbuffer,1,retorno);
		delete(vetorbuffer,1,(pos(',',vetorbuffer)-5));
{
		writeln('vetorbuffer: ',vetorbuffer);
}
		for k := 1 to 6 do
		begin
			fillchar(hashemtexto,length(hashemtexto),byte( ' ' ));
			hashemtexto := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
			delete(vetorbuffer,1,pos(',',vetorbuffer));
			val(hashemtexto,hash,retorno);
			vetorhashes[j] := hash;
{			
			writeln(retorno,',',vetorhashes[j]);
}			
			j := j + 1;
		end;
		fillchar(vetorbuffer,length(vetorbuffer),byte( ' ' ));
		i := i + 1;
	end;
end;

BEGIN
	nomearquivoregistros:='teste.dat';
	nomearquivohashes:='teste.hsh';

(* Abre o arquivo, informa números dele e vai pra busca	*)

 	writeln('Abre arquivo de registros');
	abrearquivoregistros(nomearquivoregistros);
	writeln('Abre arquivo de hashes');
	abrearquivohashes(nomearquivohashes);

 	tamanho:=filesize(arquivoregistros);
	writeln('Tamanho: ',tamanho); 


(* Le o arquivo de hashes, pegando todos os numeros de hash e salvando num vetor *)

	writeln('Le arquivo de hashes');
	learquivohashes;

(* Pede o nome exato de um arquivo a ser procurado *)

	write('Insira o nome exato do arquivo: ');
	readln(pesquisa);

(* Passa tudo para letra maiuscula *)
	for j := 1 to length(pesquisa) do
	begin
		caractere:=pesquisa[j];
		pesquisa[j]:=upcase(caractere);
	end;

(* Calcula o hash do nome da pesquisa *)

	hash:=calculahash(pesquisa);
	writeln('Hash: ',hash);

(* Faz a busca binaria no vetor *)

	buscabinarianomearquivo(vetorhashes, hash, posicao, tentativas);
 
(* Tendo a posicao certa, le o registro e verifica se o nome bate. *)
(*  Ou entao, diz que nao tem aquele nome no arquivo *)

	if posicao <> 0 then
	begin
		j := posicao;
		hashtemporario := hash;
		while hashtemporario = hash do
		begin
			j := j - 1;
			hashtemporario := vetorhashes[j];
		end;
{
 		writeln(' Existem mais ',(posicao - j) - 1,' entradas iguais, de ',j + 1,' a ',posicao,' - acima');
}
		cima := j + 1;
		j := posicao;
		hashtemporario := hash;
		while hashtemporario = hash do
		begin
			j := j + 1;
			hashtemporario := vetorhashes[j];
		end;
{
 		writeln(' Existem mais ',(j - posicao) - 1,' entradas iguais, de ',posicao,' a ',j - 1,' - abaixo');
}
		baixo := j - 1;
		for j := cima to baixo do
		begin
			leregistronoarquivo(arquivoregistros,vetorbuffer,j);
			if pesquisa = ficha.nomearquivo then
				writeln('Posicao: ',j,' tentativas: ',tentativas,' Nome do arquivo: ',ficha.nomearquivo,' Diretorio: ',ficha.diretorio);
		end;
	end
		else
			writeln('Arquivo nao encontrado.');

(* Fecha o arquivo *)

	fechaarquivoregistros;
END.
