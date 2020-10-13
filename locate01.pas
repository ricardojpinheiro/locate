program locate01;
type
	nomearquivo = string[12];
	palavrapesquisada = string[20];
	registro = record
				palavra: palavrapesquisada;
				end;
var
	i, posicao, tentativas: integer;
	pesquisa: palavrapesquisada;
	arquivoregistros: file of registro;
	ficha: registro;
	nome, nomeregistros: nomearquivo;
		
procedure buscabinariaarquivo (var pesquisa: palavrapesquisada; var posicao, tentativas: integer);
var
	comeco, meio, fim: integer;
	encontrou: boolean;
	valor: registro;
begin
	comeco:=0;
	tentativas:=1;
	fim:=filesize(arquivoregistros);
	encontrou:=false;
	writeln('Fim: ',fim);
	while (comeco <= fim) and (encontrou = false) do
	begin
		meio:=(comeco+fim) div 2;
		seek(arquivoregistros,meio);
		read(arquivoregistros,valor);
		writeln('Meio: ',meio,' valor: ',valor.palavra,' Pesquisa: ',pesquisa);
		if (pesquisa = valor.palavra) then
			encontrou:=true
		else
			if (pesquisa < valor.palavra) then
				fim:=meio-1
			else
				comeco:=meio+1;
		tentativas:=tentativas+1;
	end;
	if encontrou = true then
	begin
		posicao:=meio;
		pesquisa:=valor.palavra;
	end;
end;

function existearquivo (nome: nomearquivo): boolean;
var
	arquivo: file;
begin
	assign(arquivoregistros,nomeregistros);
	{$i-}
	reset(arquivoregistros); 
	{$i+}
	existearquivo:=(IOResult = 0);
end;

procedure abrearquivo;
begin
	assign(arquivoregistros,nomeregistros);
	if existearquivo(nome) = false then
		rewrite(arquivoregistros)
	else
		reset(arquivoregistros);
end;

procedure fechaarquivo;
begin
	close(arquivoregistros);
end;

BEGIN
	nomeregistros:='teste.dat';
{ Abre o arquivo, informa números dele e vai pra busca	}
 	abrearquivo;
	write('Nome a ser encontrado: ');
	readln(pesquisa);
	buscabinariaarquivo(pesquisa,posicao,tentativas);
	if posicao = 0 then
		writeln('O numero ',pesquisa,' nao esta no vetor')
	else
		writeln('O numero ',pesquisa,' esta no vetor, Posicao: ',posicao,' apos ',tentativas,' tentativas.');
	fechaarquivo;
END.

