program update04;
{ Este código deve ser executado no PC. O programa vai puxar toda a base
* de dados do arquivo texto, gerar os hashes de cada nome de arquivo,
* colocar tudo em um vetor e ordena-lo. Ele cria um arquivo nao tipado 
* (para ser lido com blockread), contendo o hash, o nome do arquivo e o 
* diretorio - tudo em maiusculas porque o MSX-DOS nao diferencia. 
* O programa tambem cria um segundo arquivo, somente com os hashes.
* }

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
	textfile = text;
	registro = record
		hash: integer;
		nomearquivo: string[tamanhonomearquivo];
		diretorio: string[tamanhodiretorio];
	end;
	registervector = array[1..max] of registro;
	
var
	arquivotexto: textfile;
	arquivoregistros: registerfile;
	arquivohashes: hashfile;
 	nomearquivotexto, nomearquivoregistros, nomearquivohashes: filename;
 	vetorregistros: registervector;
 	b, modulo: integer;
 	
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
	while not seekeof(arquivotexto) and (i <= max) do
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
end;

procedure geraarquivohashes;
var
	i, j, k, hash, retorno: integer;
	vetorbuffer: buffervector;
	hashemtexto, temporario1, temporario2: string[5];
	
begin
{ Joga num arquivo separado o hash }
{ Grava no arquivo de hashes, na posicao 0, o valor de b e o modulo. }
	temporario1:=' ';
	fillchar(temporario1,length(temporario1),byte( ' ' ));
	temporario2:=' ';
	fillchar(temporario2,length(temporario2),byte( ' ' ));
	vetorbuffer:=' ';
	fillchar(vetorbuffer,length(vetorbuffer),byte( ' ' ));
	str(b,temporario1);
	str(modulo,temporario2);
	vetorbuffer := concat(temporario1,',',temporario2,',');
 	seek(arquivohashes,0);
	blockwrite(arquivohashes,vetorbuffer,1,retorno);
{	
	writeln('b: ',b,' modulo: ',modulo);
	writeln(vetorbuffer);
}	
{ Joga num arquivo separado o hash }	
{ Como o arquivo trabalha com registros de 128 bytes (arquivo sem tipo), 
  vamos colocar 6 hashes por registro } 
	i := 1;
	j := 1;
	hashemtexto := ' ';
	while i <= ((max div 6)+1) do
	begin
		fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
		for k := 1 to 6 do
		begin
			hash := vetorregistros[j].hash;
			fillchar(hashemtexto,length(hashemtexto),byte( ' ' ));
			str(hash,hashemtexto);
			vetorbuffer := vetorbuffer + hashemtexto + ',';
			j := j + 1;
		end;
{
		writeln(vetorbuffer);
}
		seek(arquivohashes,i);
		blockwrite(arquivohashes,vetorbuffer,1,retorno);
		fillchar(vetorbuffer,length(vetorbuffer),byte( ' ' ));
		i := i + 1;
	end;
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

BEGIN
	nomearquivotexto:='teste.txt';
	nomearquivoregistros:='teste.dat';
	nomearquivohashes:='teste.hsh';
	writeln('Abre arquivos');
 	abrearquivotexto(nomearquivotexto);
	abrearquivoregistros(nomearquivoregistros);
	abrearquivohashes(nomearquivohashes);

(*	Os valores de b e modulo (usados para calculo do hash) *)

 	b:=primo(255);
	modulo:=primo(max);
	writeln('Le arquivo texto');
	learquivotexto;
	writeln('Fecha arquivo texto');
	fechaarquivotexto;
	writeln('Ordena vetor de entradas');
	quicksort(vetorregistros,1,max);
	writeln('Gera arquivo de hashes');
	geraarquivohashes;

 	for b:=1 to max do
		writeln('Registro ',b,': ',vetorregistros[b].hash,' - ',vetorregistros[b].nomearquivo,' - ',vetorregistros[b].diretorio);

 	writeln('Grava arquivo com vetor de entradas');
	gravaarquivoregistros(vetorregistros,max);
	writeln('Fecha arquivo de registros');
	fechaarquivoregistros;
	fechaarquivohashes;
END.
