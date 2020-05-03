program buscabinaria;
const
	max = 10;
type
	lista = array[1..max] of integer;
var
	matriz: lista;
	pesquisa, posicao, primeira, segunda: integer;
	
procedure initmatriz (var matriz: lista);
var
	i: integer;
begin
	randomize;
	for i:=1 to max do
		matriz[i]:=random(10);
end;

procedure shellsort (var matriz: lista; n: integer);
var
	i, j, passo, temporario: integer;
begin
	passo:=n div 2;
	while passo > 0 do
	begin
		for i:=passo to n do
		begin
			temporario:=matriz[i];
			j:=i;
			while (j >= passo) and (matriz[j-passo] > temporario) do
			begin
				matriz[j]:=matriz[j-passo];
				j:=j-passo;
			end;
			matriz[j]:=temporario;
		end;
		passo:=passo div 2;
	end;
end;

{$A-}

procedure quicksort(var matriz: lista; comeco, fim: integer);
var 
	i, j, meio, pivo, aux: integer;
begin
  i := comeco;
  j := fim;
  meio := (comeco + fim) div 2;
  pivo := matriz[meio];

  while (i <= j) do
  begin
    while (matriz[i] < pivo) and (i < fim) do
      i := i + 1;

    while (matriz[j] > pivo) and (j > comeco) do
      j := j-1;

    if (i <= j) then
    begin
      aux := matriz[i];
      matriz[i] := matriz[j];
      matriz[j] := aux;
      i := i+1;
      j := j-1;
    end;
  end;

  if (j > comeco) then
    quicksort(matriz, comeco, j);

  if (i < fim) then
    quicksort(matriz, i, fim);
end;

procedure buscasequencial (var matriz: lista; var pesquisa, posicao: integer);
var
	comeco, meio, fim: integer;
	encontrou: boolean;
begin
	encontrou:=false;
	while (posicao <= max) and (encontrou = false) do
	begin
		if (pesquisa = matriz[posicao]) then
			encontrou:=true
		else
			posicao:=posicao+1;
	end;
	if encontrou = false then
		posicao:=0;
end;

procedure buscabinaria (var matriz: lista; var pesquisa, posicao: integer);
var
	comeco, meio, fim: integer;
	encontrou: boolean;
begin
	comeco:=1;
	fim:=max;
	encontrou:=false;
	while (comeco <= fim) and (encontrou = false) do
	begin
		meio:=(comeco+fim) div 2;
		if (pesquisa = matriz[meio]) then
			encontrou:=true
		else
			if (pesquisa < matriz[meio]) then
				fim:=meio-1
			else
				comeco:=meio+1;
	end;
	if encontrou = true then
	begin
		posicao:=meio;
		pesquisa:=matriz[meio];
	end;
end;

begin
	writeln('Inicializa o vetor, com ',max,' numeros gerados ao acaso');
	initmatriz(matriz);
{
 	writeln('Ordena o vetor com shell sort');
	shellsort(matriz,max);
}
	writeln('Ordena o vetor com quick sort');
	quicksort(matriz,1,max);
	for posicao:=1 to max do
		writeln('Matriz[',posicao,']=',matriz[posicao]);
	pesquisa:=0;
	posicao:=maxint;
	write('Numero a ser buscado: ');
	readln(pesquisa);
	writeln('Busca primeiro elemento');
	buscabinaria(matriz,pesquisa,posicao);
	primeira:=posicao;
	if posicao = maxint then
		writeln('O numero ',pesquisa,' nao esta no vetor')
		else
			writeln('Busca elementos iguais e superiores');
			while posicao <> 0 do
			begin
				writeln('O numero ',pesquisa,' esta no vetor, Posicao: ',posicao:0);
				posicao:=posicao+1;					
				buscasequencial(matriz,pesquisa,posicao);
			end;
			posicao:=primeira;
			writeln('Busca elementos iguais e inferiores');
			while posicao <> 0 do
			begin
				segunda:=posicao;
				writeln('O numero ',pesquisa,' esta no vetor, Posicao: ',posicao:0);
				posicao:=posicao-1;
				buscasequencial(matriz,pesquisa,posicao);
				if segunda = posicao then
					posicao:=0;
			end;
{
 	buscabinaria(matriz,pesquisa,posicao);
	if posicao = 0 then
		writeln('O numero ',pesquisa,' nao esta no vetor')
		else
			begin
				writeln('O numero ',pesquisa,' esta no vetor');
				writeln('Posicao: ',posicao:0);
			end;
}
end.
