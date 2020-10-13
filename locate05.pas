{
   locate05.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
  
* Este código pode ate ser rodado no PC, mas a prioridade e o MSX.
* Ele vai ler o arquivo de hashes e jogar para um vetor na memoria.
* O programa vai pedir um padrao de busca. O programa coloca o padrao
* todo em maiusculas - o MSX-DOS nao diferencia. Ele calcula o hash 
* desse padrao de busca, faz-se uma busca binaria nesse vetor e achando,
* le o registro no arquivo de registros, colocando a informacao na tela.
* Acrescentei um trecho de codigo para procurar por colisoes (com
* base no hash) e imprimir todas as entradas identicas.
}

program locate05;

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
 	nomedoexecutavel, temporario: buffervector;
 	entradadocomando: array [1..4] of filename;
 	pesquisa: filename;
 	ficha: registro;
 	b, modulo, tamanho, posicao, tentativas: integer;
 	j, hash, hashtemporario, cima, baixo, limite: integer;
 	parametro: byte;
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

procedure helpdocomando;
begin
	writeln(' Uso: locate <padrao> <parametros>.');
	writeln(' Faz buscas em um banco de dados criado com a lista de arquivos do dispositivo.');
	writeln;
	writeln(' Padrao: Padrao a ser buscado no banco de dados.');
	writeln;
	writeln(' Parametros: ');
	writeln(' /a ou /change	 	- Muda para o diretorio onde o arquivo esta.');
	writeln(' /c ou /count 		- Mostra quantas entradas foram encontradas.');
	writeln(' /h ou /help 		- Traz este texto de ajuda e sai.');
	writeln(' /l n ou /limit n 	- Limita a saida para n entradas.');
	writeln(' /p ou /prolix	 	- Mostra tudo o que o comando está fazendo.');
	writeln(' /s ou /stats 		- Exibe estatisticas do banco de dados.');
	writeln(' /v ou /version 	- Exibe a versão do comando e sai.');
	writeln;
	halt;
end;

procedure versaodocomando;
begin
	writeln('locate versao 0.005'); 
	writeln('Copyright (c) 2020 Brazilian MSX Crew.');
	writeln('Alguns direitos reservados.');
	writeln('Este software ainda nao se decidiu se sera distribuido sobre a GPL v. 2 ou nao.');
	writeln;
	writeln('Este programa e fornecido sem garantias na medida do permitido pela lei.');
	writeln;
	writeln('Notas de versao: ');
	writeln('No momento, esse comando apenas faz busca por nomes exatos de arquivos');
	writeln('no banco de dados. Ele ainda nao faz buscas em nomes incompletos ou em');
	writeln('diretorios. Ele tambem so faz uso de um parametro por vez.');
	writeln('No futuro, teremos o uso de dois ou mais parametros, faremos a busca em');
	writeln('nomes incompletos, diretorios e sera possivel executar o comando CD para');
	writeln('o diretorio onde o arquivo esta.');
	writeln;
	writeln('Configuracao: ');
	writeln('A principio o banco de dados do locate esta localizado em a:\UTILS\LOCATE\DB.');
	writeln('Se quiser trocar o caminho, voce deve alterar a variavel de ambiente LOCALEDB,');
	writeln('no MSX-DOS. Faca essas alteracoes no AUTOEXEC.BAT, usando o comando SET.');
	writeln;
	halt;
end;	

BEGIN
	parametro := 0;
	limite := 0;
	for b := 1 to 4 do
		entradadocomando[b] := paramstr(b);

(* Sem parametros o comando apresenta o help. *)

	if paramcount = 0 then
		helpdocomando;

(* Antes de tratar como seria com um parametro, pega tudo e passa *)
(* para maiusculas. *)
	
	for j := 1 to 3 do
	begin
		temporario := paramstr(j);
		if pos('/',temporario) <> 0 then
			parametro := j;
		for b := 1 to length(temporario) do
			temporario[b] := upcase(temporario[b]);
		entradadocomando[j] := temporario;
	end;

(* Com um parametro. Se for o /h ou /help, apresenta o help.	*)	
(* Se for o /v ou /version, apresenta a versao do programa.		*)	
	
	caractere:=' ';
		
	if (entradadocomando[parametro] = '/A') or (entradadocomando[parametro] = '/CHANGE') then
		caractere := 'A';
	if (entradadocomando[parametro] = '/C') or (entradadocomando[parametro] = '/COUNT') then
		caractere := 'C';
	if (entradadocomando[parametro] = '/H') or (entradadocomando[parametro] = '/HELP') then
		helpdocomando;
	if (entradadocomando[parametro] = '/L') or (entradadocomando[parametro] = '/LIMIT') then
		caractere := 'L';
	if (entradadocomando[parametro] = '/P') or (entradadocomando[parametro] = '/PROLIX') then
		caractere := 'P';
	if (entradadocomando[parametro] = '/S') or (entradadocomando[parametro] = '/STATS') then
		caractere := 'S';
	if (entradadocomando[parametro] = '/V') or (entradadocomando[parametro] = '/VERSION') then
		versaodocomando;

	if caractere = 'L' then
		val(entradadocomando[parametro + 1],limite,b);
	
	for b := 1 to 2 do
		if pos('.',entradadocomando[b]) <> 0 then
			parametro := b;

(* O 1o parametro e o nome a ser pesquisado. *)
	
	pesquisa:=entradadocomando[parametro];

	nomearquivoregistros:='teste.dat';
	nomearquivohashes:='teste.hsh';

(* Abre o arquivo, informa números dele e vai pra busca	*)

 	if caractere = 'P' then	writeln('Abre arquivo de registros');
	abrearquivoregistros(nomearquivoregistros);
	
	if caractere = 'P' then	writeln('Abre arquivo de hashes');
	abrearquivohashes(nomearquivohashes);

 	tamanho:=filesize(arquivoregistros);

 	if caractere = 'S' then
 	begin
		writeln('Arquivo com os registros: ',nomearquivoregistros);
		writeln('Arquivo com os hashes: ',nomearquivohashes);
		writeln('Tamanho: ',tamanho, ' registros.'); 
 	end;
 	
	if caractere = 'P' then	writeln('Tamanho do arquivo: ',tamanho,' registros.'); 

(* Le o arquivo de hashes, pegando todos os numeros de hash e salvando num vetor *)

	if caractere = 'P' then	writeln('Le arquivo de hashes');
	learquivohashes;

(* Pede o nome exato de um arquivo a ser procurado *)

	if caractere = 'P' then	writeln('Nome do arquivo: ', pesquisa);

(* Calcula o hash do nome da pesquisa *)

	hash:=calculahash(pesquisa);
	if caractere = 'P' then	writeln('Hash do nome pesquisado: ',hash);

(* Faz a busca binaria no vetor *)

	if caractere = 'P' then	writeln('Faz busca.');
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
		baixo := j + 1;
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
		cima := j - 1;
		
		if caractere = 'C' then writeln('Numero de entradas encontradas: ',(cima - baixo) - 1);
		
		if caractere = 'L' then cima := baixo + limite;
			
		for j := baixo to cima do
		begin
			leregistronoarquivo(arquivoregistros,vetorbuffer,j);
			if pesquisa = ficha.nomearquivo then
			begin
				if caractere = 'P' then	
					writeln('Posicao: ',j,' tentativas: ',tentativas,' Nome do arquivo: ',ficha.nomearquivo,
					' Diretorio: ',ficha.diretorio)
				else
					writeln(ficha.diretorio,'\',ficha.nomearquivo);
			end;
		end;
	end
		else
			writeln('Arquivo nao encontrado.');

(* Fecha o arquivo *)
	if caractere = 'P' then
		writeln('Fecha arquivo.');
	fechaarquivoregistros;
END.
