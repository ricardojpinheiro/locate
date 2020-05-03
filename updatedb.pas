{
	Programa para criar a lista que será vasculhada pelo locate.
	Ricardo Jurczyk Pinheiro - 2015-10-28	-	Versão 0.001.
}
Program Updatedb;
var
	Texto		:	Text;
	Saida		:	file of string;
	Alvo		:	string;
	fim		:	integer;
begin
	fim:=0;
	assign(Texto,'teste.lst');
	assign(Saida,'saida.lst');
	{$i-}
	reset(Texto);
	rewrite(Saida);
	{$i+}
	while (not EOF(Texto)) do
	begin
		readln(Texto,Alvo);
		write(Saida,Alvo);
		fim:=fim+1;
	end;
	writeln('No. de linhas: ',fim);
	close(Saida);
	close(Texto);
end.

