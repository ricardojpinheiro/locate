program crivoerastotenes;
const
	max = 32000;
var
	a: integer;
	raiz, top: integer;
	i, j: integer;
begin
	write('Valor: '); readln(top);
	raiz:=round(sqrt(top));
	if top<=max then
	begin
		a:=i;
		for i:=2 to top do
			if (a[i]=i) then
			begin
				write(' ',i);
				j:=i+i;
				while j<=top do
				begin
					a[j]:=0;
					j:=j+i;
				end;
			end;
	end;
end.
