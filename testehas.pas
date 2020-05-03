{
   testehash.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>   
}


program testehash;

type
	phrase = string[255];

var 
	b, modulo : integer;
	frase: phrase;

function calculahashsimples (palavra: phrase; b, modulo: integer): integer;
var
	i, hash: integer;
	a, hash2: real;
	
begin
	hash:=0;
	hash2:=0.0;
	for i:=1 to length(palavra) do
	begin
{	Aqui temos um problema. A funcao modulo nao pode ser usada com reais
		e foi necessario usar reais porque o valor e muito grande para
		trabalhar com inteiros - estoura o limite.
		Modulo = resto da divisao inteira: c <- a - b * (a / b).
}
		a := (hash2 * b + ord(palavra[i]));
		hash2 := (a - modulo * int(a / modulo));
		hash:=round(hash2);
	end;
	calculahashsimples:=hash;
end;

function calculahashfnv0 (palavra: phrase): integer;
const
	fnvprime = 16777619;
	fnvoffset = 2166136261;
	
var
	i, hash: longint;
	hash2: longint;
		
begin
	hash:=0;
	hash2:=0;
	for i:=1 to length(palavra) do
	begin
{	Aqui temos um problema. A funcao modulo nao pode ser usada com reais
		e foi necessario usar reais porque o valor e muito grande para
		trabalhar com inteiros - estoura o limite.
		Modulo = resto da divisao inteira: c <- a - b * (a / b).
}
		hash2 := hash2 * fnvprime; 
		hash2 := hash2 XOR ord(palavra[i]);
		hash:=round(hash2);
	end;
	calculahashfnv0:=hash;
end;

function calculahashfnv1 (palavra: phrase): integer;
const
	fnvprime = 16777619;
	fnvoffset = 2166136261;
	
var
	i, hash: integer;
	hash2: integer;
		
begin
	hash:=fnvoffset;
	for i:=1 to length(palavra) do
	begin
{	Aqui temos um problema. A funcao modulo nao pode ser usada com reais
		e foi necessario usar reais porque o valor e muito grande para
		trabalhar com inteiros - estoura o limite.
		Modulo = resto da divisao inteira: c <- a - b * (a / b).
}
		hash2 := hash2 XOR ord(palavra[i]);
		hash2 := hash2 * fnvprime; 
		hash:=round(hash2);
	end;
	calculahashfnv1:=hash;
end;

BEGIN
	write('Frase a ser inserida: ');
	readln(frase);
	write('Módulo (use um número primo): '); 
	readln(modulo);
	write('Base da representação (use um número primo próximo a 255): '); 
	readln(b);
	writeln('Hash simples=',calculahashsimples(frase,b,modulo),' b=',b,' modulo=',modulo);
	writeln('Hash FNV-0 =',calculahashfnv0(frase));
	writeln('Hash FNV-1a =',calculahashfnv1(frase));
END.

