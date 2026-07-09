program BuscaDiretoriosDJB2;

type
  { Buffer de 128 bytes isolados para o BlockRead trabalhar }
  RegBuffer = array[1..128] of Byte;
  TString = String[127];

var
  ArqBin      : file; { Arquivo sem tipo (untyped file) }
  Buffer      : RegBuffer;
  Linha       : String[127];
  NomeBuscar  : String[30];
  NomeUpper   : String[30];
  HashAlvo    : Real;
  
  { Variaveis de controle da Busca Binaria }
  Baixo, Alto, Meio : Integer;
  Passos      : Integer;
  Achou       : Boolean;
  BlocosLidos : Integer;
  
  { Divisao e fatiamento de campos da string }
  P1, P2      : Integer;
  HashStr     : String[15];
  HashReg     : Real;
  DirReg      : String[30];
  CaminhoReg  : String[80];
  Code        : Integer;

{ Converte qualquer string para letras maiusculas (Padrao Turbo Pascal 3.0) }
function UpperCase(S: TString): TString;
var Idx: Integer;
begin
  for Idx := 1 to Length(S) do
    if (S[Idx] >= 'a') and (S[Idx] <= 'z') then
      S[Idx] := Chr(Ord(S[Idx]) - 32);
  UpperCase := S;
end;

{ Transforma os bytes puros do bloco do disco na string dinamica do Pascal }
procedure ConverterBufferParaString(Buf: RegBuffer; var S: TString);
var Len, Idx: Integer;
begin
  Len := Buf[1];
  if Len > 127 then Len := 127;
  S[0] := Chr(Len); { O Byte 0 define o tamanho real da string em Pascal }
  for Idx := 1 to Len do
    S[Idx] := Chr(Buf[Idx + 1]);
end;

{ Calcula o Hash DJB2 de 32 bits simulado em Real para nao estourar os 16 bits }
function CalcularHashDJB2(S: TString): Real;
var
  H : Real;
  Idx : Integer;
begin
  H := 5381.0;
  for Idx := 1 to Length(S) do
  begin
    H := (H * 33.0) + Ord(S[Idx]);
    { Aplica a mascara binaria de 32 bits (Modulo 4294967296) }
    H := H - (Int(H / 4294967296.0) * 4294967296.0);
  end;
  CalcularHashDJB2 := H;
end;

begin
  ClrScr;
  WriteLn('======================================================================');
  WriteLn('     SISTEMA DE BUSCA BINARIA DE DIRETORIOS - TURBO PASCAL 3.0        ');
  WriteLn('======================================================================');
  WriteLn;
  
  Assign(ArqBin, 'DIRS.DAT');
  {$I-}
  Reset(ArqBin); { Forca os registros a medirem exatamente 128 bytes }
  {$I+}
  
  if IOresult <> 0 then
  begin
    WriteLn('Erro: Nao foi possivel abrir o arquivo "DIRS.DAT" no diretorio atual.');
    Halt;
  end;

  { Protecao contra arquivo gerado sem nenhum registro }
  if FileSize(ArqBin) = 0 then
  begin
    WriteLn('Erro: O arquivo "DIRS.DAT" esta completamente vazio.');
    Close(ArqBin);
    Halt;
  end;

  Write('Digite o NOME DO DIRETORIO que deseja localizar: ');
  ReadLn(NomeBuscar);
  
  if Length(NomeBuscar) = 0 then
  begin
    Close(ArqBin);
    Halt;
  end;

  { Padroniza e calcula o Hash de busca }
  NomeUpper := UpperCase(NomeBuscar);
  HashAlvo  := CalcularHashDJB2(NomeUpper);

  WriteLn('----------------------------------------------------------------------');
  WriteLn('Buscando Hash DJB2: ', HashAlvo:10:0);
  WriteLn('----------------------------------------------------------------------');

  { Inicializacao dos ponteiros da Busca Binaria }
  Passos := 0;
  Achou  := False;
  Baixo  := 0;
  Alto   := FileSize(ArqBin) - 1;

  while (Baixo <= Alto) and (not Achou) do
  begin
    Passos := Passos + 1;
    Meio := (Baixo + Alto) div 2;
    
    Seek(ArqBin, Meio);
    BlockRead(ArqBin, Buffer, 1, BlocosLidos);
    
    if BlocosLidos = 1 then
    begin
      ConverterBufferParaString(Buffer, Linha);
      
      { Fatia a string no formato: HASH,DIRETORIO,CAMINHO }
      P1 := Pos(',', Linha);
      if P1 > 0 then
      begin
        HashStr := Copy(Linha, 1, P1 - 1);
        Val(HashStr, HashReg, Code);
        if Code <> 0 then HashReg := -1; { Erro de conversao de seguranca }
        
        { Se a matematica do Hash casar... }
        if HashReg = HashAlvo then
        begin
          { Isola o nome para garantir que nao e uma colisao residual }
          CaminhoReg := Copy(Linha, P1 + 1, Length(Linha) - P1);
          P2 := Pos(',', CaminhoReg);
          
          if P2 > 0 then
            DirReg := Copy(CaminhoReg, 1, P2 - 1)
          else
            DirReg := '';
            
          if DirReg = NomeUpper then
          begin
            Achou := True;
            CaminhoReg := Copy(CaminhoReg, P2 + 1, Length(CaminhoReg) - P2);
          end
          else
            Baixo := Meio + 1; { Desempata colisao }
        end
        else if HashReg < HashAlvo then
          Baixo := Meio + 1
        else
          Alto := Meio - 1;
      end
      else
        Baixo := Meio + 1; { Registro corrompido, ignora }
    end
    else
      Alto := Meio - 1; { Falha fisica de leitura, aborta janela }
  end;

  { Apresentacao dos resultados obtidos }
  WriteLn('Busca binaria terminada em ', Passos, ' passos.');
  WriteLn('----------------------------------------------------------------------');

  if Achou then
  begin
    WriteLn('SUCESSO! Diretorio encontrado na posicao fisica: ', Meio);
    WriteLn('DIRETORIO : ', DirReg);
    WriteLn('HASH DJB2 : ', HashStr);
    WriteLn('CAMINHO   : ', CaminhoReg);
  end
  else
  begin
    WriteLn('ATENCAO: O diretorio "', NomeUpper, '" nao consta na base DIRS.DAT.');
  end;

  Close(ArqBin);
  WriteLn('----------------------------------------------------------------------');
  Write('Pressione [Enter] para encerrar.');
  ReadLn;
end.
