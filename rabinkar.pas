program Project1;

type
	filenameregistro = string[80];
	filename = string[12];
	
var
	padrao: filename;
	intervalo: filenameregistro;
	i: integer;

function procura (padrao: filename; ondebuscar: filenameregistro) : integer;
const
	b = 131;
var
	hashpadrao, hashondebuscar, Bm, j, tamanhopadrao, tamanhoondebuscar: integer;
	encontrou: boolean;
begin
	encontrou:=false;
	procura:=0;
	tamanhopadrao:=length(padrao);
	if tamanhopadrao=0 then
	begin
		procura:=1;
		encontrou:=true
	end;

	Bm:=1;
	hashpadrao:=0;
	hashondebuscar:=0;
	tamanhoondebuscar:=length(ondebuscar);
	if tamanhoondebuscar >= tamanhopadrao then
					{ preprocessamento }
		for j:=1 to tamanhopadrao do
		begin
			Bm:=Bm * b;
			hashpadrao:=hashpadrao * b + ord (padrao[j]);
			hashondebuscar:=hashondebuscar * b + ord (ondebuscar[j]);
		end;

	j:=tamanhopadrao;
					{ procura }
	while not encontrou do
	begin
		if (hashpadrao=hashondebuscar) and (padrao=copy(ondebuscar,j-tamanhopadrao+1,tamanhopadrao)) then
		begin
			procura:=j-tamanhopadrao;
			encontrou:=true;
		end;
		if j<tamanhoondebuscar then
		begin
			j := j + 1;
			hashondebuscar:=hashondebuscar * b - ord(ondebuscar[j-tamanhopadrao]) * Bm + ord (ondebuscar[j]);
		end
		else
			encontrou:=true;
  end;
end;

begin
	write('Intervalo: ');
	readln(intervalo); 
	write('Padrao a ser encontrado: ');
	readln(padrao); 
	i:=procura(padrao,intervalo);
	if i <> 0 then
		writeln('Padrao ',padrao,' encontrado a partir da posicao: ',i)
	else
		writeln('Padrao ',padrao,' nao encontrado.');
end.
