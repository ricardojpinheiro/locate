{ 
   update06.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
*  
* Este código deve ser executado no PC. O programa vai puxar toda a base
* de dados do arquivo texto, gerar os hashes de cada nome de arquivo,
* colocar tudo em um vetor e ordena-lo. Ele cria um arquivo nao tipado 
* (para ser lido com blockread), contendo o hash, o nome do arquivo e o 
* diretorio - tudo em maiusculas porque o MSX-DOS nao diferencia. 
* O programa tambem cria um segundo arquivo, somente com os hashes, e 
* faz uma compressao desse arquivo usando o metodo RLE - Run Length 
* Encoding.
* }

program update06;

const
	tamanhonomearquivo = 40;
	tamanhototalbuffer = 127; (* Mas é possível reduzir o buffer para 94.*)
	tamanhodiretorio = 87;
	max = 1500;
	porlinha = 15;

type
	absolutepath = string[tamanhodiretorio];
	filename = string[tamanhonomearquivo];
	buffervector = string[tamanhototalbuffer];
	registerfile = file;
	hashfile = file;
	textfile = text;
	registro = record
		hash: integer;
		nomearquivo: string[tamanhonomearquivo];
		diretorio: string[tamanhodiretorio];
	end;
	registervector = array[1..maxint] of registro;
	
var
	arquivotexto: textfile;
	arquivoregistros: registerfile;
	arquivohashes: hashfile;
 	nomedoexecutavel, temporario: buffervector;
 	entradadocomando: array [1..3] of buffervector;
 	nomearquivotexto, nomearquivoregistros, nomearquivohashes: filename;
 	vetorregistros: registervector;
 	b, modulo, maximo: integer;
 	parametro: byte;
 	caractere: char;
 	
procedure abrearquivotexto (nomearquivotexto: filename);
begin
	assign(arquivotexto,nomearquivotexto);
	reset(arquivotexto); 
end;

procedure abrearquivoregistros (nomearquivoregistros: filename);
begin
	assign(arquivoregistros,nomearquivoregistros);
	rewrite(arquivoregistros);
end;

procedure abrearquivohashes (nomearquivohashes: filename);
begin
	assign(arquivohashes,nomearquivohashes);
	rewrite(arquivohashes);
end;

procedure fechaarquivotexto;
begin
	close(arquivotexto);
end;

procedure fechaarquivoregistros;
begin
	close(arquivoregistros);
end;

procedure fechaarquivohashes;
begin
	close(arquivohashes);
end;

function primo (numero: integer): integer;
var
	raiz, i, j: integer;
begin
	j:=0;
	i:=2;
	primo:=1;
	repeat
		raiz:=round(sqrt(numero));
		while i<=raiz do
		begin
			j:=numero mod i;
			if j = 0 then
			begin
				numero := numero - 1;
				raiz:=round(sqrt(numero));
				j:=0;
				i:=1;
			end;
			i:=i+1;
		end;
		primo := numero;
	until (numero <> 0) and (primo <> 0);
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
		hash := round(hash2);
	end;
	calculahash := hash;
end;

procedure learquivotexto;
var
	i, j: integer;
	caractere: char;
	vetorbuffer: buffervector;
	temporarionomearquivo: filename;
	temporariodiretorio: absolutepath;
		
begin
	i := 1;
	fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
	while not eof(arquivotexto) do
	begin
		{ Le o arquivo texto }
		readln(arquivotexto,vetorbuffer);
		{ Passa tudo para letra maiuscula }
		for j := 1 to length(vetorbuffer) do
		begin
			caractere:=vetorbuffer[j];
			vetorbuffer[j]:=upcase(caractere);
		end;
		{ Copia o nome do arquivo e apaga o que nao sera usado }
 		temporarionomearquivo := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
		delete(vetorbuffer,1,pos(',',vetorbuffer));
		{ Copia o diretorio e apaga o que nao sera usado }
		temporariodiretorio := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
		{ Joga tudo no registro, no vetor. }
		vetorregistros[i].nomearquivo := temporarionomearquivo;
		vetorregistros[i].diretorio := temporariodiretorio;
		vetorregistros[i].hash := calculahash(temporarionomearquivo);
		i := i + 1;
	end;
	maximo := i;
end;

procedure geraarquivohashes (maximo: integer);
var
	i, j, k, hash, proximohash, contador, retorno: integer;
	vetorbuffer: buffervector;
	hashemtexto, temporario1, temporario2, temporario3: string[6];
	
begin
{ Joga num arquivo separado o hash }
{ Grava no arquivo de hashes, na posicao 0, o valor de b e o modulo. }
	temporario1:=' ';
	fillchar(temporario1,length(temporario1),byte( ' ' ));
	temporario2:=' ';
	fillchar(temporario2,length(temporario2),byte( ' ' ));
	temporario3:=' ';
	fillchar(temporario1,length(temporario3),byte( ' ' ));
	vetorbuffer:=' ';
	fillchar(vetorbuffer,length(vetorbuffer),byte( ' ' ));
	str(b,temporario1);
	str(modulo,temporario2);
	str(maximo,temporario3);
	vetorbuffer := concat(temporario1,',',temporario2,',',temporario3,',');
 	seek(arquivohashes,0);
	blockwrite(arquivohashes,vetorbuffer,1,retorno);
{	
	writeln('b: ',b,' modulo: ',modulo,' maximo: ',maximo);
  	writeln(vetorbuffer);
}	
{ Joga num arquivo separado o hash }	
{ Como o arquivo trabalha com registros de 128 bytes (arquivo sem tipo), 
  vamos colocar 6 hashes por registro } 
{ Uma mudanca aqui e introduzir a compressao RLE. A ideia e reduzir o 
  tamanho do vetor a ser lido. Logo, ao lado de cada hash teremos um 
  caracter que marca quantas vezes ele se repete. Logo, 35g significa 
  que o hash 35 se repete 7 vezes (g e a setima letra do alfabeto).
}
	i := 1;
	j := 1;
	hashemtexto := ' ';
	repeat 
		fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
		k := 1;
		while (k <= porlinha) do
		begin
			contador := 0;
			if j < maximo then
			begin
				hash := vetorregistros[j].hash;
				proximohash := hash;
				while (hash = proximohash) do
				begin
					contador := contador + 1;
					proximohash := vetorregistros[j + contador].hash;
				end;
			end
			else
				hash := 0;
			fillchar(hashemtexto,length(hashemtexto),byte( ' ' ));
			str(hash,hashemtexto);
			hashemtexto := concat(hashemtexto,chr ( contador + 64 ));
			vetorbuffer := concat(vetorbuffer,hashemtexto,',');
			j := j + contador;
			k := k + 1;
		end;
		seek(arquivohashes,i);
		blockwrite(arquivohashes,vetorbuffer,1,retorno);
		i := i + 1;
{
		writeln('maximo: ',maximo,' i: ',i,' j: ',j,' vetorbuffer: ',vetorbuffer);
}
	until j >= maximo;
end;

procedure quicksort(var vetor: registervector; comeco, fim: integer);
var 
	i, j, meio, pivo: integer;
	aux: registro;
	
begin
  i := comeco;
  j := fim;
  meio := (comeco + fim) div 2;
  pivo := vetor[meio].hash;

  while (i <= j) do
  begin
    while (vetor[i].hash < pivo) and (i < fim) do
      i := i + 1;

    while (vetor[j].hash > pivo) and (j > comeco) do
      j := j-1;

    if (i <= j) then
    begin
      aux := vetor[i];
      vetor[i] := vetor[j];
      vetor[j] := aux;
      i := i+1;
      j := j-1;
    end;
  end;

  if (j > comeco) then
    quicksort(vetor, comeco, j);

  if (i < fim) then
    quicksort(vetor, i, fim);
end;

{$A+}

procedure gravaarquivoregistros (vetorregistros: registervector; fim: integer);
var
	i, retorno: integer;
	vetorbuffer: buffervector;
	hashemtexto: string[5];
begin
	hashemtexto:='';
	for i:=1 to fim do
	begin
	{	Transformar todo o conteudo do registro em uma string. }
	{	Hash vira texto. }
		str(vetorregistros[i].hash,hashemtexto);
	{ 	Zera a variavel, enche de espacos em branco. } 
		fillchar(vetorbuffer,tamanhototalbuffer,Byte( ' ' ));
	{ Coloca o tamanho da string no primeiro byte (0) }	
		vetorbuffer[0] := #0;
	{ Monta a string que sera salva. }		
		vetorbuffer:=concat(hashemtexto,',',vetorregistros[i].nomearquivo,',',vetorregistros[i].diretorio,',');
	{ Grava no arquivo de registros. }
		blockwrite(arquivoregistros,vetorbuffer,1,retorno);
	end;
end;

procedure helpdocomando;
begin
	writeln(' Uso: ',nomedoexecutavel,' <parametros> <tipo> <nome do arquivo>.');
	writeln(' Atualiza a base de dados do locate.');
	writeln;
	writeln(' Tipo: Origem do arquivo gerado, se e Windows ou Linux/Unix.');
	writeln(' Nome do arquivo: Arquivo que contem a lista no qual');
	writeln(' a base de dados do locate se baseia.');
	writeln;
	writeln(' Parametros: ');
	writeln(' /h ou /help - Apresenta este texto de ajuda e sai.');
	writeln(' /v ou /version - Apresenta a versão do comando e sai.');
	writeln(' /p ou /prolix - Informa tudo o que o programa está fazendo.');
	writeln;
	halt;
end;

procedure versaodocomando;
begin
	writeln(nomedoexecutavel,' (locate) 0.1'); 
	writeln('Copyright (c) 2020 Brazilian MSX Crew.');
	writeln('Alguns direitos reservados.');
	writeln('Este software ainda não se decidiu se será distribuido');
	writeln('sobre a GPL v. 2 ou não...');
	writeln;
	writeln('Este programa é fornecido sem garantias na medida do ');
	writeln('permitido pela lei.');
	halt;
end;	

BEGIN
	parametro := 0;
	for b := 1 to 3 do
		entradadocomando[b] := paramstr(b);
		
(*	Todo esse trecho aqui e para apresentar o funcionamento do programa. *)
(*	Essas diretivas de compilacao sao necessarias para saber qual *)
(*	sistema esta executando o script, e definir como proceder. O que eu *)	
(*	fiz aqui e uma perfumaria, para fazer com que ele pegue sempre o *)
(*  nome do executavel (mesmo que seja renomeado) e coloque no help. *)
	
	{$IFDEF Linux}
	nomedoexecutavel := 'Linux';
	{$ENDIF}
	
	{$IFDEF Windows}
	nomedoexecutavel := 'Windows';
	{$ENDIF}
	
	if nomedoexecutavel = 'Windows' then
		caractere := '\'
	else
		caractere := '/';
	nomedoexecutavel := paramstr(0);
	b := length(paramstr(0));
	while nomedoexecutavel[b] <> caractere do
		b := b - 1;
	modulo := b;
	delete(nomedoexecutavel,1,modulo);

(* Sem parametros o comando apresenta o help. *)

	if paramcount = 0 then
		helpdocomando;
		
(* Antes de tratar como seria com um parametro, pega tudo e passa *)
(* para maiusculas. *)
	
	for modulo := 1 to 3 do
	begin
		temporario := paramstr(modulo);
		if pos('/',temporario) <> 0 then
			parametro := modulo;
		for b := 1 to length(temporario) do
			temporario[b] := upcase(temporario[b]);
		entradadocomando[modulo] := temporario;
	end;
		
(* Com um parametro. Se for o /h ou /help, apresenta o help.	*)	
(* Se for o /v ou /version, apresenta a versao do programa.		*)
	
	caractere:=' ';
	
	case entradadocomando[parametro] of
		'/H': helpdocomando;
		'/P': caractere := 'P';
		'/V': versaodocomando;
		'/HELP': helpdocomando;
		'/PROLIX': caractere := 'P';
		'/VERSION': versaodocomando;
	end;
	
	if paramcount >= 1 then
	begin
		for b := 1 to 3 do
			if pos('.',entradadocomando[b]) <> 0 then
				parametro := b;
{
 		for b := 1 to 3 do
			writeln('entradadocomando[',b,']=',entradadocomando[b]);
}			
		nomearquivotexto := paramstr(parametro);
		temporario := copy(nomearquivotexto,1,pos('.',nomearquivotexto)-1);
		nomearquivoregistros := concat(temporario,'.dat');
		nomearquivohashes := concat(temporario,'.hsh');

		if caractere = 'P' then
			writeln('Abre arquivos');

		abrearquivotexto(nomearquivotexto);
		abrearquivoregistros(nomearquivoregistros);
		abrearquivohashes(nomearquivohashes);

(*	Os valores de b e modulo (usados para calculo do hash) *)

		b := primo(255);
		modulo := primo(max);
		
		if caractere = 'P' then
			writeln('Multiplicador para o hash: ',b,' Modulo: ',modulo);
		
		if caractere = 'P' then
			writeln('Le arquivo texto');
			
		learquivotexto;

		if caractere = 'P' then
			writeln('Fecha arquivo texto');
			
		fechaarquivotexto;
		
		if caractere = 'P' then		
			writeln('Ordena vetor de entradas');
			
		quicksort(vetorregistros,1,maximo);

		if caractere = 'P' then
			writeln('Grava arquivo com vetor de entradas');
			
		gravaarquivoregistros(vetorregistros,maximo);

		if caractere = 'P' then
			writeln('Gera arquivo de hashes');

		geraarquivohashes(maximo);

		if caractere = 'P' then
		begin
			writeln('Registro:     Hash:   Nome:           Diretorio:');
			for b := 1 to maximo do
				writeln('Registro ',b,':   ',vetorregistros[b].hash,'   -   ',vetorregistros[b].nomearquivo,' - ',vetorregistros[b].diretorio);
		end;
		
		if caractere = 'P' then		
			writeln('Fecha arquivos');
			
		fechaarquivoregistros;
		fechaarquivohashes;
	end;
END.
