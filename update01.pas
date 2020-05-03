program update01;
type
	nomearquivo = string[12];
	registro = record
				palavra: string[20];
				end;
var
	arquivo: text;
	arquivoregistros: file of registro;
	caractere: char;
	frase: string[20];
	ficha: registro;
	nome, nomeregistros: nomearquivo;
	i: integer;

function existearquivo (nome: nomearquivo): boolean;
var
	arquivo: file;
begin
	assign(arquivo,nome);
	{$i-}
	reset(arquivo); 
	{$i+}
	existearquivo:=(IOResult = 0);
end;

procedure abrearquivo;
begin
	assign(arquivo,nome);
	if existearquivo(nome) = false then
		rewrite(arquivo)
	else
		reset(arquivo);
end;

procedure fechaarquivo;
begin
	close(arquivo);
end;

BEGIN
	nome:='a.txt';
	nomeregistros:='a.dat';
 	abrearquivo;
	assign(arquivoregistros,nomeregistros);
	rewrite(arquivoregistros);
	frase:='';
	while not eof(arquivo) do
	begin
		while not eoln(arquivo) do
		begin
			read(arquivo,caractere);
			frase:=frase+caractere;
		end;
		ficha.palavra:=frase;
		frase:='';
		write(arquivoregistros,ficha);
		readln(arquivo);
	end;
	fechaarquivo;
	close(arquivoregistros);
	assign(arquivoregistros,nomeregistros);	
	reset(arquivoregistros);
	frase:='';
	writeln('Total de registros: ',filesize(arquivoregistros));
 	for i:=0 to 10 do
	begin
		read(arquivoregistros,ficha);
		writeln('Registro ',i,': ',ficha.palavra);
	end;
	close(arquivoregistros);

END.

