{
   busca.pas
     
}
program busca;

const
	max = 100;
	maxpattern = 128;

type
	filenamevector = array[1..max] of string[maxpattern];
	filename = string[12];
	pattern = string[maxpattern];
	textfile = text;
	found = record
		linha, posicao, vezes: byte;
	end;
		
var
	arquivotexto: textfile;
	vetornomedearquivo: filenamevector;
	nomedearquivo: filename;
	i, total, posicao: integer;
	encontrou: array[1..max] of found;
	padrao: pattern;
	
procedure abrearquivotexto (var arquivotexto: textfile; nome: filename);
begin
	assign(arquivotexto,nome);
	reset(arquivotexto); 
end;

function existearquivo (var arquivotexto: textfile; nome: filename): boolean;
begin
	assign(arquivotexto,nome);
	{$i-}
	reset(arquivotexto); 
	{$i+}
	existearquivo:=(IOResult = 0);
end;

procedure fechaarquivotexto(var arquivotexto: textfile);
begin
	close(arquivotexto);
end;

function learquivotexto(var arquivotexto: textfile): integer;
var
	i: integer;
begin
	i:=0;
	while not seekeof(arquivotexto) do
	begin
		i:=i+1;
		readln(arquivotexto,vetornomedearquivo[i]);

		writeln(i,' ',vetornomedearquivo[i]);

	end;
	learquivotexto:=i;
end;

procedure buscainocente(padrao: pattern; comparativo: pattern; linhasnovetor: integer);
{
* 	No momento só está buscando o primeiro padrão em cada linha. 
* 	Precisa ser melhorado para buscar n padrões na mesma linha.
}

var
	i, posicaonotexto, tamanhovetor, tamanhopadrao, comparacoes, vezes: integer;
	saida: boolean;
begin
	i:=0;
	posicaonotexto:=1;
	tamanhopadrao:=length(padrao);
	tamanhovetor:=maxpattern;
	comparacoes:=0;
	saida:=false;
	while (((posicaonotexto+tamanhopadrao)-1) <= tamanhovetor) do
	begin
		vezes:=0;
		if padrao[i+1] = comparativo[posicaonotexto+i] then
		begin
			while (padrao[i+1] = comparativo[posicaonotexto+i]) and (saida = false) do
			begin
				comparacoes:=comparacoes+1;
				i:=i+1;
				if i = tamanhopadrao then
				begin
					vezes:=vezes+1;
					encontrou[linhasnovetor].linha:=linhasnovetor;
					encontrou[linhasnovetor].posicao:=posicaonotexto;
					encontrou[linhasnovetor].vezes:=vezes;
					saida:=true;
				end;
			end;
		end;
		comparacoes:=comparacoes+1;
		i:=0;
		posicaonotexto:=posicaonotexto+1;
	end;
end;

function randomprime (seed: integer): integer;
var
	numero, divisores, i: integer;
begin
	divisores := 0;
	randomize;
	numero := random(seed);
	while numero mod 2 = 0 do
		numero := numero + 1;
	for i:=1 to numero do
		if numero mod i = 0 then
			divisores := divisores + 1;
	if divisores = 2 then
			randomprime := numero;
end;

function rabinkarp (padrao: pattern; comparativo: pattern): integer;
var
  b, hashpadrao, hashcomparativo, Bm, j, tamanhopadrao, tamanhocomparativo: integer;
  achou: boolean;
  
begin
  b:=randomprime(maxpattern);
  achou:=false;
  rabinkarp:=0;
  tamanhopadrao:=length(padrao);
  if tamanhopadrao = 0 then
  begin
    rabinkarp:=1;
    achou:=true
  end;

  Bm:=1;
  hashpadrao:=0;
  hashcomparativo:=0;
  tamanhocomparativo:=length(comparativo);
  if tamanhocomparativo >= tamanhopadrao then
    { preprocessamento }
    for j:=1 to tamanhopadrao do
    begin
      Bm:=Bm * b;
      hashpadrao:=hashpadrao * b + ord (padrao[j]);
      hashcomparativo:=hashcomparativo * b + ord (comparativo[j]);
    end;

  j:=tamanhopadrao;
  { procura }
  while not achou do
  begin
    if (hashpadrao = hashcomparativo) and (padrao = copy(comparativo,j-tamanhopadrao+1,tamanhopadrao)) then
    begin
      rabinkarp := j - tamanhopadrao;
      achou := true
    end;
    if j < tamanhocomparativo then
    begin
      j := j + 1;
      hashcomparativo:=hashcomparativo * b - ord(comparativo[j-tamanhopadrao]) * Bm + ord (comparativo[j]);
    end
    else
      achou:=true;
  end
end;

BEGIN
	nomedearquivo:='1.txt';
	writeln('Abre arquivo');
 	if not existearquivo(arquivotexto,nomedearquivo) then
		begin
			writeln('Arquivo ',nomedearquivo,' nao existe.');
			halt;
		end;
	abrearquivotexto(arquivotexto,nomedearquivo);
	writeln('Le arquivo texto');
	total:=learquivotexto(arquivotexto);
	writeln('Total de linhas: ',total);
	writeln('Fecha arquivo texto');
	fechaarquivotexto(arquivotexto);
	writeln('Padrao a ser encontrado:');
	readln(padrao);
	writeln('Busca por força bruta:');
	for i:=1 to max do
	begin
		encontrou[i].linha:=0;
		encontrou[i].vezes:=0;
		encontrou[i].posicao:=0;
		buscainocente(padrao,vetornomedearquivo[i],i);
		if encontrou[i].vezes > 0 then
{
			writeln('Padrao ',padrao,' nao encontrado na linha ',i)
		else
}		
	writeln('Padrao: ',padrao,' Vez: ',encontrou[i].vezes,' Linha: ',encontrou[i].linha,' Posicao: ',encontrou[i].posicao);
	end;
	writeln('Busca com o algoritmo de Rabin-Karp:');
	for i:=1 to max do
	begin
		posicao:=rabinkarp(padrao,vetornomedearquivo[i]);
		if posicao > 0 then
			writeln('Padrao: ',padrao,' Linha: ',i,' Posicao: ',posicao+1);
	end;
END.
