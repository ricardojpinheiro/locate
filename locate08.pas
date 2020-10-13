{
   locate.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
  
* Este código so funciona no MSX. Voce passa um padrao de pesquisa. Ele 
* le o arquivo de hashes (compactado com um metodo RLE) e joga para um 
* vetor na memoria. O programa passa o padrao em maiusculas, calcula
* o hash desse padrao, faz uma busca binaria nesse vetor de hashes e, 
* achando, le o registro no arquivo de registros, colocando a informacao 
* na tela. Ele ainda procura por colisoes (com base no hash) e imprime 
* todas as entradas identicas.
}

program locate;

{$i d:types.inc}
{$i d:memory.inc}
{$i d:dos.inc}
{$i d:dos2err.inc}
{$i d:dos2file.inc}
{$i d:dpb.inc}
{$i d:fastwrit.inc}
    
const
    TamanhoBuffer = 255;
    TamanhoString = 255;
    TamanhoNomeArquivo = 40;
    TamanhoDiretorio = 127;
    MaximoRegistros = 8700;
    HashesPorLinha = 36;

type
    Registro = record
        hash: integer;
        NomeDoArquivo: string[TamanhoNomeArquivo];
        Diretorio: string[TamanhoDiretorio];
    end;
    HashVector = array[1..MaximoRegistros] of integer;
    
var
(*  Variaveis relacionadas aos arquivos. *)
    ResultadoSeek: boolean;
    ResultadoBlockRead: byte;
    ArquivoRegistros, ArquivoHashes: byte;
    NovaPosicao: integer;
    NomeArquivoRegistros, NomeArquivoHashes: TFileName;
    Caminho: TFileName;
    parametro: byte;
    letra: char;
    
(*  Usado pelas rotinas que verificam a versão do MSX-DOS e a letra de drive. *)
    VersaoMSXDOS: TMSXDOSVersion;
    Registros: TRegs;
    LetraDeDrive: char;
    
(*  Vetores, de hashes e de parâmetros.  *)    
    VetorHashes: HashVector;
    VetorParametros: array [1..4] of string[TamanhoNomeArquivo];
    HashEmTexto, TemporarioNumero: string[8];
    Ficha: Registro;

(*  Inteiros. *)
    Posicao, Tamanho, Tentativas, Acima, Abaixo, RetornoDoVal: integer;
    LimiteDeBuscas, comeco, fim: integer;
    i, j, b, ModuloDoHash, TotalDeRegistros, HashTemporario: integer;
    hash, contador: integer;

(*  Caracteres. *)
    Caractere, PrimeiraLetra: char;

(*  O buffer usado para leitura de dados nos arquivos. *)
    Buffer: array[0..TamanhoBuffer] of byte;
    frase: string[TamanhoString];
    pesquisa, temporario: TFileName;
    fimdoarquivo: boolean;

(* Função que localiza a ultima ocorrencia de um caractere numa string. *)

function LastPos(Caractere: char; Frase: TString): integer;
var
    i: integer;
    Encontrou: boolean;
begin
    i := length(Frase);
    Encontrou := false;
    repeat
        if Frase[i] = Caractere then
        begin
            LastPos := i + 1;
            Encontrou := true;
        end;
        i := i - 1;
    until Encontrou = true;
end;

(* Busca binária no vetor de hashes. *)

procedure BuscaBinariaNomeDoArquivo (hash, fim: integer; var Posicao, Tentativas: integer);
var
    comeco, meio: integer;
    Encontrou: boolean;
    
begin
    comeco		:=	1;
    Tentativas	:=	1;
    fim			:=	TotalDeRegistros;
    Encontrou	:=	false;

    while (comeco <= fim) and (Encontrou = false) do
    begin
        meio:=(comeco + fim) div 2;

        if (hash = VetorHashes[meio]) then
            Encontrou := true
        else
            if (hash < VetorHashes[meio]) then
                fim := meio - 1
            else
                comeco := meio + 1;
        Tentativas := Tentativas + 1;
    end;
    if Encontrou = true then
        Posicao := meio;
end;

(* Aqui usamos o MSX-DOS 2 para fazer o tratamento de erros. Joga pra 
* ele o problema. *)

procedure CodigoDeErro (SaiOuNao: boolean);
var
    NumeroDoCodigoDeErro: byte;
    MensagemDeErro: TMSXDOSString;
    
begin
    NumeroDoCodigoDeErro := GetLastErrorCode;
    GetErrorMessage (NumeroDoCodigoDeErro, MensagemDeErro);
    WriteLn (MensagemDeErro);
    if SaiOuNao = true then
        Exit;
end;

(* Le a ficha no arquivo de registros. *)

procedure LeFichaNoArquivoRegistros (Posicao: integer; var Ficha: Registro);
var
    lidos: integer;

begin
    RetornoDoVal := 0;
    HashEmTexto := ' ';
    fillchar(Buffer, sizeof (Buffer), ' ' );
    fillchar(frase, sizeof (frase), ' ' );

(*  Aponta para o início do arquivo. *)
    ResultadoSeek := FileSeek (ArquivoRegistros, 0, ctSeekSet, NovaPosicao);

(*  Move até a posição desejada. *)
    For contador := 1 To Posicao + 1 do
        If (not FileSeek(ArquivoRegistros, TamanhoBuffer, ctSeekCur, NovaPosicao)) Then
            CodigoDeErro (true);

(*  Lê o registro desejado. *)
    ResultadoBlockRead := FileBlockRead(ArquivoRegistros, Buffer, TamanhoBuffer);

    contador := 0; 

(*  Localiza início e fim do registro, e apaga o que sobra. *)
    
    while letra <> '#' do
    begin
        letra := char(Buffer[contador]);
        contador := contador + 1;
    end;
    
    comeco := contador;
    contador := TamanhoBuffer;
    
    while letra <> '%' do
    begin
        letra := char(Buffer[contador]);
        contador := contador - 1;
    end;
    
    fim := contador + 1; 

    delete(frase, 1, TamanhoBuffer);

(*  Copia para uma string, setando o tamanho na posição 0. *)

    for contador := comeco to fim do
    begin
        letra := char(Buffer[contador]);
        frase:= concat(frase, letra);
    end;
    frase[0] := char(fim - comeco);

(* Copia o diretorio e apaga o que nao sera usado *)
    Ficha.Diretorio := copy(frase, LastPos(',', frase), TamanhoString);
    delete(frase, LastPos(',', frase) - 1, TamanhoString);

(* Copia o nome do arquivo e apaga o que nao sera usado *)
    Ficha.NomeDoArquivo := copy(frase, LastPos(',', frase), TamanhoString);
    delete(frase, LastPos(',', frase) - 1, TamanhoString);

(* Copia o hash do nome do arquivo e apaga o que nao sera usado *)      
    fillchar(HashEmTexto, length(HashEmTexto), byte( ' ' ));
    HashEmTexto := copy(frase, LastPos(',', frase), TamanhoString);
    delete(frase, LastPos(',', frase) - 1, TamanhoString);
    val(HashEmTexto, hash, RetornoDoVal);
    Ficha.hash := hash;

end;

(*  Calcula o hash de um padrao. *)

function CalculaHash (Padrao: TFileName): integer;
var
    i, hash: integer;
    a, hash2: real;
    
begin
    hash := 0;
    hash2 := 0.0;
    for i := 1 to length(Padrao) do
    begin
(*  A funcao CalculaHash nao pode ser usada com reais e e preciso usar
    reais porque o valor e muito grande para trabalhar com inteiros.
    Estoura o maxint. A solucao foi fazer:
    Modulo = resto da divisao inteira: c <- a - b * (a / b).
*)
        a := (hash2 * b + ord(Padrao[i]));
        hash2 := (a - ModuloDoHash * int(a / ModuloDoHash));
        hash := round(hash2);
    end;
    CalculaHash := hash;
end;

(*  Le o arquivo de hashes, descompactando-o e montando o vetor. *)

procedure LeArquivoDeHashes(hash, Tamanho, TotalDeRegistros: integer);
var
    registros, entradas, posicao, linha, repeticoes: integer;
    SizeBuffer: integer;
    HashEmTexto: string[8];
    
begin
    linha := 1;
    entradas := 0;
    HashEmTexto := ' ';
    fimdoarquivo := false;
    SizeBuffer := sizeof(Buffer);
    fillchar(VetorHashes, sizeof (VetorHashes), 0);

(*  Enquanto o arquivo não fecha, faça isto. *)
	while ( not fimdoarquivo ) do
    begin
        fillchar(Buffer, sizeof (Buffer), ' ' );

(*  Posiciona no início do arquivo. *)
        ResultadoSeek := FileSeek (ArquivoHashes, 0, ctSeekSet, NovaPosicao);

(*  Move o ponteiro pro registro a ser lido e o le. *)
        for contador := 1 to linha do
            if not (FileSeek (ArquivoHashes, SizeBuffer, ctSeekCur, NovaPosicao)) then
                CodigoDeErro (true);
        ResultadoBlockRead := FileBlockRead (ArquivoHashes, Buffer, SizeBuffer);

(*  Trata o erro no MSX-DOS 2.*)        
        if (ResultadoBlockRead = ctReadWriteError) then
        begin
            CodigoDeErro (false);
            fimdoarquivo := true;
        end;

(*  Tem q zerar esses 2 primeiros registros pra não dar problema. *)
        Buffer[0] := ord('0');
        Buffer[1] := ord('0');

(*  Damos um chega pra cá no vetor. *)        
        for posicao := 2 to (SizeBuffer - 1) do
        begin
            letra := Char(Buffer[posicao]);
            Buffer[posicao - 2] := ord(letra);
        end;

(*  Vasculharemos todo o arquivo para pegar os hashes. *)
        letra := ' ';
   
        for posicao := 1 to HashesPorLinha do
        begin

(*  Pegamos os dados do vetor de bytes. *)
            contador := 0;
            fillchar(HashEmTexto, sizeof(HashEmTexto), ' ' );
            while letra <> ',' do
            begin
                letra := chr(Buffer[(contador + 7 * (posicao - 1))]);
                HashEmTexto[contador + 1] := letra;                
                contador := contador + 1;
            end;
            HashEmTexto[0] := chr(length(HashEmTexto));

            letra := HashEmTexto[contador - 1];
            delete(HashEmTexto, contador - 1, length(HashEmTexto));
            val(HashEmTexto, hash, RetornoDoVal);
            VetorHashes[entradas] := hash;

(*  Aqui 'descompactamos' as posicoes do vetor. *)

            for repeticoes := 1 to (ord ( letra ) - 64) do
                VetorHashes[entradas + repeticoes] := hash;               
            
            entradas := entradas + repeticoes;
        end;
        linha := linha + 1;
        if (linha = Tamanho) then
            fimdoarquivo := true;
    end;
end;

(*  Ajuda do programa.*)
procedure LocateAjuda;
begin
    fastwriteln(' Uso: locate <padrao> <parametros>.');
    fastwriteln(' Faz buscas em um banco de dados criado com a lista de arquivos do dispositivo.');
    fastwriteln(' ');
    fastwriteln(' Padrao: Padrao a ser buscado no banco de dados.');
    fastwriteln(' ');
    fastwriteln(' Parametros: ');
    fastwriteln(' /a ou /change    - Muda para o diretorio onde o arquivo esta.');
    fastwriteln(' /c ou /count     - Mostra quantas entradas foram encontradas.');
    fastwriteln(' /h ou /help      - Traz este texto de ajuda e sai.');
    fastwriteln(' /l n ou /limit n - Limita a saida para n entradas.');
    fastwriteln(' /p ou /prolix    - Mostra tudo o que o comando esta fazendo.');
    fastwriteln(' /s ou /stats     - Exibe estatisticas do banco de dados.');
    fastwriteln(' /v ou /version   - Exibe a versao do comando e sai.');
    fastwriteln(' ');
    exit;
end;

(*  Versao do programa.*)
procedure LocateVersao;
begin
    fastwriteln('locate Versao 0.8'); 
    fastwriteln('Copyright (c) 2020 Brazilian MSX Crew.');
    fastwriteln('Alguns direitos reservados.');
    fastwriteln('Este software e distribuido segundo a licenca GPL.');
    fastwriteln(' ');
    fastwriteln('Este programa e fornecido sem garantias na medida do permitido pela lei.');
    fastwriteln(' ');
    fastwriteln('Notas de versao: ');
    fastwriteln('Esse comando busca por nomes exatos de arquivos no banco ');
    fastwriteln('de dados. Ele nao faz buscas em nomes incompletos ou em');
    fastwriteln('diretorios. Ele tambem so faz uso de um parametro por vez.');
    fastwriteln('No futuro, teremos o uso de dois ou mais parametros, ');
    fastwriteln('faremos a busca em nomes incompletos e diretorios. ');
    fastwriteln(' ');
    fastwriteln('Configuracao: ');
    fastwriteln('O banco de dados do locate esta em a:\UTILS\LOCATE\DB.');
    fastwriteln('Se quiser trocar o caminho, altere a variavel de ambiente ');
    fastwriteln('LOCATEDB no MSX-DOS. Faca essas alteracoes no AUTOEXEC.BAT');
    fastwriteln('usando o comando SET. Ex.: SET LOCATEDB=a:\UTILS\LOCATE\DB\.');
    fastwriteln(' ');
    exit;
end;

(*  Trecho que se repete, então faz a busca ate a virgula.*)
procedure BuscaAteAVirgula;
begin
    HashEmTexto := ' ';
    letra :=  ' ';
    repeat
        HashEmTexto := concat(HashEmTexto, letra);
        contador := contador + 1;
        letra := chr(Buffer[contador]);
    until letra = ',';
    
    HashEmTexto[0] := char(length(HashEmTexto));
    
    for j := 1 to 2 do
        HashEmTexto[j] := '0';
end;

BEGIN
    parametro := 0;
    LimiteDeBuscas := 0;
    temporario := ' ';

(*  Testa se está rodando no MSX-DOS 2. Se sim, então vai ler a variável
*   de ambiente LOCATEDB. Senão... Tchau.*)

    GetMSXDOSVersion (VersaoMSXDOS);

    if (VersaoMSXDOS.nKernelMajor < 2) then
    begin
        fastwriteln('MSX-DOS 1.x não suportado.');
        exit;
    end
    else 
        begin
            fillchar(Caminho, TamanhoString, byte( ' ' ));
            temporario[0] := 'l';
            temporario[1] := 'o';
            temporario[2] := 'c';
            temporario[3] := 'a';
            temporario[4] := 't';
            temporario[5] := 'e';
            temporario[6] := 'd';
            temporario[7] := 'b';
            temporario[8] := #0;
           
            Caminho[0] := #0;
            with Registros do
            begin
                B := sizeof (Caminho);
                C := ctGetEnvironmentItem;
                HL := addr (temporario);
                DE := addr (Caminho);
            end;
       
            MSXBDOS (Registros);
            LetraDeDrive := Caminho[0];
            insert(LetraDeDrive, Caminho, 1);
        end;

    if (Registros.HL > 0) then Caminho := 'a:\utils\locate\db\'; 

(*  Parametros a serem lidos. *)
    for i := 1 to 4 do
        VetorParametros[i] := paramstr(i);

(* Sem parametros o comando entrega o help. *)
    if paramcount = 0 then LocateAjuda;

(* Antes de tratar os parametros, passa tudo para maiusculas. *)
    for i := 1 to 3 do
    begin
        temporario := paramstr(i);
        if pos('/',temporario) <> 0 then
            parametro := i;
        for j := 1 to length(temporario) do
            temporario[j] := upcase(temporario[j]);
        VetorParametros[i] := temporario;
    end;

(* Com um parametro. Se for o /h ou /help, apresenta o help.    *)  
(* Se for o /v ou /version, apresenta a versao do programa.     *)  
    Caractere:=' ';
    if (VetorParametros[parametro] = '/A') or (VetorParametros[parametro] = '/CHANGE')    then Caractere := 'A';
    if (VetorParametros[parametro] = '/C') or (VetorParametros[parametro] = '/COUNT')     then Caractere := 'C';
    if (VetorParametros[parametro] = '/H') or (VetorParametros[parametro] = '/HELP')      then LocateAjuda;
    if (VetorParametros[parametro] = '/L') or (VetorParametros[parametro] = '/LIMIT')     then Caractere := 'L';
    if (VetorParametros[parametro] = '/P') or (VetorParametros[parametro] = '/PROLIX')    then Caractere := 'P';
    if (VetorParametros[parametro] = '/S') or (VetorParametros[parametro] = '/STATS')     then Caractere := 'S';
    if (VetorParametros[parametro] = '/V') or (VetorParametros[parametro] = '/VERSION')   then LocateVersao;

(* Se for /l<numero>, limite o numero de buscas. *)
    if Caractere = 'L' then
    begin
        val(VetorParametros[parametro + 1], LimiteDeBuscas, RetornoDoVal);
        LimiteDeBuscas := LimiteDeBuscas - 1;
    end;

(*  O 1o parametro e o nome a ser pesquisado.       *)
(*  Aqui definimos qual será o arquivo a ser lido.  *)

    pesquisa := paramstr(1);
    for i := 1 to length(pesquisa) do
        pesquisa[i] := upcase(pesquisa[i]);
    PrimeiraLetra := pesquisa[1];

(*  Se o parametro 1 nao for o arquivo, entao da um erro. *)

    If PrimeiraLetra = '/' then LocateAjuda;

(*  Se a primeira letra não for de A a Z, troca para 0. *)

    if (not (PrimeiraLetra in ['A'..'Z'])) then PrimeiraLetra := '0';
    
    fillchar(NomeArquivoRegistros, sizeof(NomeArquivoRegistros), byte( ' ' ));
    fillchar(NomeArquivoHashes, sizeof(NomeArquivoHashes), byte( ' ' ));
    
    delete(Caminho, LastPos('\',Caminho), sizeof(Caminho));
    
    NomeArquivoRegistros := concat(Caminho, PrimeiraLetra, '.dat');
    NomeArquivoHashes := concat(Caminho, PrimeiraLetra, '.hsh');

    for j := 1 to length(NomeArquivoRegistros) do
        NomeArquivoRegistros[j] := upcase(NomeArquivoRegistros[j]);

    for j := 1 to length(NomeArquivoHashes) do
        NomeArquivoHashes[j] := upcase(NomeArquivoHashes[j]);

(*  Se o parametro passado for H, V, S, P ou C, limpa a tela. *)
    if (Caractere in ['H', 'V', 'S', 'P', 'C']) then clrscr;

(* Abre os arquivos de registros e de hashes *)
    if Caractere = 'P' then fastwriteln('Abre arquivo de registros');
    ArquivoRegistros := FileOpen (NomeArquivoRegistros, 'r');

    if Caractere = 'P' then fastwriteln('Abre arquivo de hashes');
    ArquivoHashes := FileOpen (NomeArquivoHashes, 'r');

(* Testa se há algum problema com os arquivos. Se há, encerra. *)
    if (ArquivoRegistros in [ctInvalidFileHandle, ctInvalidOpenMode]) then CodigoDeErro (true);
    if (ArquivoHashes in [ctInvalidFileHandle, ctInvalidOpenMode]) then CodigoDeErro (true);

(* Le de um arquivo separado o hash *)
(* Na posicao 0 temos b, modulo, o número de entradas e o número de registros. *)
    fillchar(Buffer, TamanhoBuffer, byte( ' ' ));
    ResultadoSeek := FileSeek (ArquivoHashes, 0, ctSeekSet, NovaPosicao);
    ResultadoBlockRead := FileBlockRead (ArquivoHashes, Buffer, TamanhoBuffer);

(*  Aqui, pegamos os dados do vetor de bytes. *)
    contador := 0;

    BuscaAteAVirgula;
    val(HashEmTexto, b, RetornoDoVal);

    BuscaAteAVirgula;
    val(HashEmTexto, ModuloDoHash, RetornoDoVal);

    BuscaAteAVirgula;
    val(HashEmTexto, TotalDeRegistros, RetornoDoVal);

    BuscaAteAVirgula;
    val(HashEmTexto, Tamanho, RetornoDoVal);
   
    if Caractere = 'P' then
    begin
        str(TotalDeRegistros, HashEmTexto);
        temporario := concat('Numero de registros: ', HashEmTexto, ' registros.');
        fastwriteln(temporario);
    end;

(* Pede o nome exato de um arquivo a ser procurado *)
    if Caractere = 'P' then
    begin
        temporario := concat('Nome do arquivo: ', pesquisa);
        fastwriteln(temporario);
    end;
        
(* Calcula o hash do nome da pesquisa *)
    hash := CalculaHash(pesquisa);

(*  Estatísticas. *)

    if Caractere = 'S' then
    begin
        temporario := concat('Arquivo com os registros: ', NomeArquivoRegistros);
        fastwriteln(temporario);
        temporario := concat('Arquivo com os hashes: ', NomeArquivoHashes);
        fastwriteln(temporario);
        str(b, HashEmTexto);
        temporario := concat('Multiplicador para o hash: ', HashEmTexto);
        fastwriteln(temporario);
        str(ModuloDoHash, HashEmTexto);
        temporario := concat('Modulo do hash: ', HashEmTexto);
        fastwriteln(temporario);
        str(Tamanho, HashEmTexto);
        temporario := concat('Grupos de registros: ', HashEmTexto);
        fastwriteln(temporario);
        str(TotalDeRegistros, HashEmTexto);
        temporario := concat('Numero de registros: ', HashEmTexto);
        fastwriteln(temporario);
        temporario := concat('Nome a ser pesquisado: ', pesquisa);
        fastwriteln(temporario);
        str(hash, HashEmTexto);
        temporario := concat('Hash do nome pesquisado: ', HashEmTexto);
        fastwriteln(temporario);
        exit;
    end;

    if Caractere = 'P' then
    begin
        str(hash, HashEmTexto);
        temporario := concat('Hash do nome pesquisado: ', HashEmTexto);
        fastwriteln(temporario);
    end;

(* Le o arquivo de hashes, pegando todos os hashes e salvando num vetor *)
    if Caractere = 'P' then fastwriteln('Le arquivo de hashes');
    LeArquivoDeHashes(hash, Tamanho, TotalDeRegistros);
    
(* Faz a busca binaria no vetor *)
    if Caractere = 'P' then fastwriteln('Faz busca.');
    BuscaBinariaNomeDoArquivo(hash, TotalDeRegistros, Posicao, Tentativas);
 
(* Tendo a posicao certa, le o registro e verifica se o nome bate. *)
(*  Pode ser que haja colisoes. Agora o programa procura por elas tambem. *)
(*  Ou entao, diz que nao tem aquele nome no arquivo *)
    if Posicao <> 0 then
    begin
        if Caractere = 'P' then 
        begin
            fastwriteln('Arquivo encontrado.');
            str(Posicao, HashEmTexto);
            temporario := concat('Posicao: ', HashEmTexto);
            fastwriteln(temporario);
        end;
        
        j := Posicao;
        HashTemporario := hash;

(*  Aqui vemos as colisoes 'acima'. *)
    while HashTemporario = hash do
        begin
            j := j - 1;
            HashTemporario := VetorHashes[j];
        end;
        Abaixo := j + 1;

(*  Aqui vemos as colisoes 'abaixo'. *)
        j := Posicao;
        HashTemporario := hash;
        while HashTemporario = hash do
        begin
            j := j + 1;
            HashTemporario := VetorHashes[j];
        end;
        Acima := j - 1;
        
        if Caractere = 'C' then
        begin
            str(((Acima - Abaixo) + 1), HashEmTexto);
            temporario := concat('Numero de entradas encontradas: ', HashEmTexto);
            fastwriteln(temporario);
            exit;
        end;
                
        if Caractere = 'L' then Acima := Abaixo + LimiteDeBuscas;

(*      Faz a busca no arquivo de registros. *)
        for j := Abaixo to Acima do
        begin
            LeFichaNoArquivoRegistros (j, Ficha);
            if pesquisa = Ficha.NomeDoArquivo then
            begin
                if Caractere = 'P' then
                begin
                    str(j, HashEmTexto);
                    str(Tentativas, TemporarioNumero);
                    temporario := concat('Posicao: ', HashEmTexto,' Tentativas: ', TemporarioNumero,
                    ' Nome do arquivo: ', Ficha.NomeDoArquivo, ' Diretorio: ', Ficha.Diretorio);
                    writeln(temporario);
                end
                else
                    begin
                        writeln(Ficha.Diretorio, '\', Ficha.NomeDoArquivo);
                    end;
            end;
        end;
    end
        else
            fastwriteln('Arquivo nao encontrado.');
    
    if Caractere = 'A' then
    begin
        LetraDeDrive := Ficha.Diretorio[1];
        Caminho := copy (Ficha.Diretorio, 3, TamanhoDiretorio);
        ChDrv (ord(LetraDeDrive) - 65);
        ChDir (caminho);
    end;

(* Fecha os arquivos *)
    if Caractere = 'P' then
        fastwriteln('Fecha arquivo.');
    
    if (not FileClose(ArquivoRegistros)) then CodigoDeErro(true);
    if (not FileClose(ArquivoHashes)) then CodigoDeErro(true);

END.
