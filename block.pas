{
   block.pas
}

program block;

{PopolonY2k<}
{ No FPC vc precisa definir a Unit crt para usar ClrScr
  Se for compilar no TP 3 do MSX, comentar o Uses Crt;
  abaixo }

{

Uses Crt;

}
{PopolonY2k>}

const
tamanhonomearquivo = 40;
{tamanhototalbuffer = 27;}
tamanhototalbuffer = 127;  { No TP do MSX o reset assume buffer de 128 bytes
                             mas isso e devido ao MSXDOS e nao ao Turbo Pascal
                             Lembrando que a string tem o primeiro byte de
                             tamanho portanto tamanho do caminho eh
                             127 + 1 byte de tamanho }
tamanhodado        = 27;   { O tamanho do dado que vai dentro do buffer acima
                             e menor (para caber no buffer total acima) }
max = 9;

var
arquivoentradas: file;
nomearquivoentradas: string[12];
entradas: string[tamanhototalbuffer];
i, j, k, tamanho, defato: integer;
nPos : Integer;

BEGIN
{
  ClrScr;
}
 
  nomearquivoentradas:='block.dat';
  writeln('Abre arquivo de entradas e coloca ',max, ' registros la.');
  assign(arquivoentradas,nomearquivoentradas);

  {PopolonY2k<}
  rewrite(arquivoentradas);     (* MSX *)
  {PopolonY2k>}
  tamanho:=sizeof(entradas);
  k:=0;
  for i:=1 to max do
  begin
    { Cuidado se vc quiser manipular cada byte de uma string pascal
      nao se esqueca de atualizar o tamanho da string no byte zero
      ou utilize as funcoes de manipulacao do pascal ou o proprio
      operador de concatenacao (+) do Pascal }
    FillChar( entradas, tamanho, Byte( ' ' ) );  { Preenche entrada com espacos }
    entradas[0] := #0; { Coloca o tamanho da string no primeiro byte (0) }

    k:=i+48;
    entradas := entradas + chr(k);

    for j:=1 to ( tamanhodado - 1 ) do
    begin
      k:=j+64;
      entradas := entradas + chr(k);
    end;

    writeLn( entradas ); { Agora o byte de tamanho esta correto - deixe o TP trabalhar pra vc ;) }
    blockwrite(arquivoentradas,entradas,1,defato);

    { Nao precisa mover o ponteiro pois o Sistema Operacional
      deixa o ponteiro na posicao correta da ultima escrita }
    {seek(arquivoentradas,i+1);}
  end;

  writeln('Tamanho do buffer: ',tamanho);
  writeln('Tamanho do arquivo: ',filesize(arquivoentradas));
  writeln('Quantos foram gravados: ',defato);
  close(arquivoentradas);

  writeln('Abre arquivo de entradas e le um registro de la.');
  assign(arquivoentradas,nomearquivoentradas);

  {PopolonY2k<}
  reset(arquivoentradas);             (* MSX *)
  {PopolonY2k>}

  while i<>99 do
  begin
    write('Qual registro deseja? (99 para sair):');
    readln(i);

    If( i <> 99 )  Then
    Begin
      {PopolonY2k<}
      nPos := ( i - 1 );
      { Calcula a posicao do registro em bytes }
      seek(arquivoentradas, nPos);
      {PopolonY2k>}

      blockread(arquivoentradas,entradas,1,defato);
      writeln('Registro no. ',i,' -> ',entradas);
      writeln('Tamanho do buffer: ',tamanho);
      writeln('Tamanho do arquivo: ',filesize(arquivoentradas));
      writeln('Quantos foram lidos: ',defato);
    end;
  end;

  WriteLn( 'Programa terminado' );

  close(arquivoentradas);

end.
