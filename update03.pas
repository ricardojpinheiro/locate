program update03;
{ Este código deve ser executado no PC. O programa vai puxar toda a 
* base de dados do arquivo texto e transformar ele num arquivo tipado, 
* para que o locate faça a busca. A ordenação e separação dos dados já
* é feita pelo script em shell. O MSX é que cria o arquivo tipado.
* }

const
	tamanhonomearquivo = 40;
	tamanhototalbuffer = 127;
	tamanhodiretorio = tamanhototalbuffer - tamanhonomearquivo;
	max = 5000;

type
	absolutepath = string[tamanhodiretorio];
	filename = string[tamanhonomearquivo];
	buffervector = string[tamanhototalbuffer];
	registerfile = file;
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
	nomearquivotexto, nomearquivoregistros: filename;
 	vetorregistros: registervector;
 	vetorbuffer: buffervector;
 	temporario1, temporario2: string[5];
 	i, b, modulo: integer;
 	
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

procedure fechaarquivotexto;
begin
	close(arquivotexto);
end;

procedure fechaarquivoregistros;
begin
	close(arquivoregistros);
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

begin
	hash:=0;
	for i:=1 to length(nomearquivo) do
		hash := (hash * b + ord(nomearquivo[i])) mod modulo;
	calculahash:=hash;
end;

procedure learquivotexto;
var
	i: integer;
	vetorbuffer: buffervector;
	temporarionomearquivo: filename;
	temporariodiretorio: absolutepath;
	
begin
	i:=1;
	fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
	while not seekeof(arquivotexto) and (i<=max) do
	begin
		{ Le o arquivo texto }
		readln(arquivotexto,vetorbuffer);
		{ Copia o nome do arquivo e apaga o que nao sera usado }
 		temporarionomearquivo:=copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
		delete(vetorbuffer,1,pos(',',vetorbuffer));
		{ Copia o diretorio e apaga o que nao sera usado }
		temporariodiretorio:=copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
		{ Joga tudo no registro, no vetor. }
		vetorregistros[i].nomearquivo:=temporarionomearquivo;
		vetorregistros[i].diretorio:=temporariodiretorio;
		vetorregistros[i].hash:=calculahash(temporarionomearquivo);
		i:=i+1;
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
	writeln('Abre arquivos');
 	abrearquivotexto(nomearquivotexto);
	abrearquivoregistros(nomearquivoregistros);
{
	Os valores de b e modulo (usados 
}
{
 	b:=primo(255);
	modulo:=primo(max);
	writeln('modulo: ',modulo);
}
	writeln('Le arquivo texto');
	learquivotexto;
	writeln('Fecha arquivo texto');
	fechaarquivotexto;
	writeln('Ordena vetor de entradas');
	quicksort(vetorregistros,1,max);
{
 	for i:=1 to max do
		writeln('Registro ',i,': ',vetorregistros[i].hash,' - ',vetorregistros[i].nomearquivo,' - ',vetorregistros[i].diretorio);
}
 	writeln('Grava arquivo com vetor de entradas');
	gravaarquivoregistros(vetorregistros,max);
	vetorbuffer:='';
	temporario1:='';
	temporario2:='';
	str(b,temporario1);
	str(modulo,temporario2);
	vetorbuffer:=concat(temporario1,',',temporario2,',');
	blockwrite(arquivoregistros,vetorbuffer,1);
	writeln('Fecha arquivo de registros');
	fechaarquivoregistros;
  	writeln('Abre arquivo de registros de novo');
	assign(arquivoregistros,nomearquivoregistros);
	reset(arquivoregistros);
	writeln('Total de registros: ',filesize(arquivoregistros));
	randomize;
 	for i:=1 to max do
	begin
		seek(arquivoregistros,i-1);
		blockread(arquivoregistros,vetorbuffer,1);
		writeln('Entrada ',i,': ',vetorbuffer);
	end;
 
	close(arquivoregistros);
END.
