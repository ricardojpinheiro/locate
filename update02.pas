program update02;
{ Este código deve ser executado no PC. O programa vai puxar toda a 
* base de dados do arquivo texto e transformar ele num arquivo tipado, 
* para que o locate faça a busca. A ordenação e separação dos dados já
* é feita pelo script em shell. O MSX é que cria o arquivo tipado.
* }

const
	max = 100;

type
	filenameregistro = array[1..48] of char;
	filename = string[12];
	registro = record
			nomedoarquivo: filenameregistro;
			diretorio: array[1..80] of char;
	end;
	registerfile = file of registro;
	textfile = text;
	stringunica = string[1];
	
var
	arquivotexto: textfile;
	arquivoregistros: registerfile;
 	nome, nomeregistros: filename;
	i, j: integer;
	ficha: registro;

procedure abrearquivotexto (nome: filename);
begin
	assign(arquivotexto,nome);
	reset(arquivotexto); 
end;

procedure abrearquivoregistros (nome: filename);
begin
	assign(arquivoregistros,nome);
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

procedure learquivotexto;
var
	caractere: char;
	i, j, k: integer;
	ficha: registro;
begin
	j:=1;
	while (eof(arquivotexto)=false) and (j<max) do
	begin
		i:=1;
		caractere:=' ';
		with ficha do
		begin
			for k:=1 to 48 do
				nomedoarquivo[k]:=' ';
			for k:=1 to 80 do
				diretorio[k]:=' ';				
		end;
		repeat
			ficha.nomedoarquivo[i]:=upcase(caractere);
			read(arquivotexto,caractere);
			i:=i+1;
		until (caractere = ',') or (caractere = ' ');
		caractere:=' ';
		repeat
			ficha.diretorio[i]:=upcase(caractere);
			read(arquivotexto,caractere);
			i:=i+1;
		until (caractere = ',') or (caractere = ' ');
		writeln('Nome ',j,': ',ficha.nomedoarquivo,' Diretorio: ',ficha.diretorio);
		write(arquivoregistros,ficha);
		readln(arquivotexto);
		j:=j+1;
	end;
end;

BEGIN
	nome:='teste.txt';
	nomeregistros:='teste.dat';
 	writeln('Abre arquivos');
 	abrearquivotexto(nome);
	abrearquivoregistros(nomeregistros);
	writeln('Le arquivo texto');
	learquivotexto;
	writeln('Fecha arquivo texto');
	fechaarquivotexto;
	writeln('Fecha arquivo de registros');
	fechaarquivoregistros;
  	writeln('Abre arquivo de registros de novo');
	assign(arquivoregistros,nomeregistros);
	reset(arquivoregistros);
	writeln('Total de registros: ',filesize(arquivoregistros));
	randomize;
 	for i:=1 to 10 do
	begin
		j:=round(random(max));
		seek(arquivoregistros,j);
		read(arquivoregistros,ficha);
		writeln('Nome ',j,': ',ficha.nomedoarquivo,' Diretorio: ',ficha.diretorio);
	end;
	close(arquivoregistros);
	writeln(sizeof(ficha));
END.
