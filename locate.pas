{
	Programa para localizar arquivos.
	A ideia desse comando é apresentar onde um arquivo está, dentro do HD.
	Claro que tem limitações de espaço e memória (afinal, é para MSX),
	então algumas (muitas) otimizações serão necessárias.
	Estamos usando busca binária, para acelerar o processo.
	Versão 0.0001	-	Ricardo Jurczyk Pinheiro	-	2015
}
program locate (input,output);

uses crt;

var
	updatedb	:	file of string;
	inicio,meio,fim	:	integer;
	vezes		:	integer;
	Chave		:	string;
	Alvo		:	string;
	BuscaBinaria	:	integer;

begin
	assign(updatedb,'saida.lst');
	{$i-}
	reset(updatedb);
	{$i+}
	inicio := 1;
	vezes := 0;
	fim := filesize(updatedb);
	Chave := '';
	Alvo := '';
	BuscaBinaria := -1;
	writeln('O que você procura?');
	readln(Chave);
	repeat
		meio := (inicio+fim) div 2;
		seek(updatedb,meio);
		read(updatedb,Alvo);
		if (Chave = Alvo) then
		begin
			BuscaBinaria := meio;
			inicio:=fim+1;
		end;
			if (Chave < Alvo) then fim:=(meio-1); 
			if (Chave > Alvo) then inicio:=(meio+1);
		vezes:=vezes+1;
	until (inicio > fim);
	writeln('Posição ',BuscaBinaria, ' Palavra ',Alvo, ' Tentativas: ',vezes); 
	close(updatedb);
end.

