program testeleitura;
{ 
* }

const
	tamanhonomearquivo = 48;
	tamanhocaminho = 128;
	max = 100;

type
	absolutepath = string[tamanhocaminho];
	filename = string[tamanhonomearquivo];
	registerfile = file of absolutepath;
	textfile = text;
	registro = record
		hash: integer;
		nomearquivo: string[tamanhonomearquivo];
		diretorio: string[tamanhocaminho];
	end;
	
var
	arquivoentradas: registerfile;
 	nome, nomearquivoentradas: filename;
 	ficha: absolutepath;
 	i, j: integer;

BEGIN
	nome:='teste.txt';
	nomearquivoentradas:='teste.dat';
 	writeln('Abre arquivo de registros de novo');
	assign(arquivoentradas,nomearquivoentradas);
	reset(arquivoentradas);
	writeln('Total de registros: ',filesize(arquivoentradas));
	randomize;
 	for i:=1 to 10 do
	begin
		j:=round(random(max));
		seek(arquivoentradas,j);
		read(arquivoentradas,ficha);
		writeln('Entrada ',j,': ',ficha);
	end;
	close(arquivoentradas);
END.
