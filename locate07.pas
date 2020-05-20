{
   locate07.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
  
* Este código pode ate ser rodado no PC, mas a prioridade e o MSX.
* Ele vai ler o arquivo de hashes (que esta compactado com um metodo de
* RLE) e jogar para um vetor na memoria. O programa vai pedir um padrao 
* de busca. O programa coloca o padrao todo em maiusculas - o MSX-DOS 
* nao diferencia. Ele calcula o hash desse padrao de busca, faz-se uma 
* busca binaria nesse vetor de hashes e, achando, le o registro no 
* arquivo de registros, colocando a informacao na tela. Acrescentei um 
* trecho de codigo para procurar por colisoes (com base no hash) e 
* imprimir todas as entradas identicas.
}

program locate07;

{$i d:types.inc}
{$i d:memory.inc}
{$i d:dos.inc}
{$i d:dos2file.inc}
{$i d:dos2err.inc}
{$i d:dpb.inc}
{$i d:fastwrit.inc}
    
const
    TamanhoNomeArquivo = 40;
    TamanhoTotalBuffer = 255;
    TamanhoDiretorio = 87;
    MaximoRegistros = 8700;
    HashesPorLinha = 15;

type
    BufferVector = string[TamanhoTotalBuffer];
    Registro = record
        hash: integer;
        NomeDoArquivo: string[TamanhoNomeArquivo];
        Diretorio: string[TamanhoDiretorio];
    end;
    RegisterVector = array[1..MaximoRegistros] of integer;
    
var
(*  Variaveis relacionadas aos arquivos. *)
    ResultadoSeek: boolean;
    ResultadoBlockRead: byte;
    ArquivoRegistros, ArquivoHashes: byte;
    NovaPosicao: integer;
    NomeArquivoRegistros, NomeArquivoHashes: TFileName;
    
(*  Usado pelas rotinas que verificam a versão do MSX-DOS e a letra de drive. *)
    VersaoMSXDOS : TMSXDOSVersion;
    Registros: TRegs;
    LetraDeDrive: char;
    
(*  Vetores, de hashes e de parâmetros.  *)    
    VetorHashes: RegisterVector;
    VetorParametros: array [1..4] of TFilename;
    HashEmTexto: string[6];

(*  Inteiros. *)
    Posicao, Tamanho, Tentativas, Acima, Abaixo, RetornoDoVal: integer;
    LimiteDeBuscas: integer;
    b, ModuloDoHash, TotalDeRegistros, HashTemporario: integer;
    Ficha: Registro;

(*  Caracteres. *)
    Caractere, PrimeiraLetra: char;

(*  Ainda tem que faxinar esse trecho aqui. *)    
(*  Mudar esse bando de temporarios para um vetor de temporarios *)    
    vetorbuffer: BufferVector;
    temporario: TFileName;
    Caminho: TFileName;
    pesquisa, temporario1, temporario2, temporario3, temporario4: TFileName;
    j, hash: integer;
    parametro: byte;

procedure BuscaBinariaNomeDoArquivo (hash, fim: integer; var Posicao, Tentativas: integer);
var
    comeco, meio: integer;
    encontrou: boolean;
    
begin
    comeco		:=	1;
    Tentativas	:=	1;
    fim			:=	TotalDeRegistros;
    encontrou	:=	false;
    while (comeco <= fim) and (encontrou = false) do
    begin
        meio:=(comeco + fim) div 2;
{
        writeln('Comeco: ',comeco,' Meio: ',meio,' fim: ',fim,' hash: ',hash,' Pesquisa: ',VetorHashes[meio]);
}       
        if (hash = VetorHashes[meio]) then
            encontrou := true
        else
            if (hash < VetorHashes[meio]) then
                fim := meio - 1
            else
                comeco := meio + 1;
        Tentativas := Tentativas + 1;
    end;
    if encontrou = true then
        Posicao := meio;
end;

procedure CodigoDeErro (SaiOuNao: boolean);
var
    NumeroDoCodigoDeErro: byte;
    MensagemDeErro     : TMSXDOSString;
    
begin
    NumeroDoCodigoDeErro := GetLastErrorCode;
    GetErrorMessage( NumeroDoCodigoDeErro, MensagemDeErro );
    WriteLn( MensagemDeErro );
    if SaiOuNao = true then
        Exit;
end;

procedure LeFichaNoArquivoRegistros (Posicao: integer);
var
    lidos, contador: integer;
    fimdoarquivo: boolean;

begin
    RetornoDoVal:=0;
    HashEmTexto:='';

    For contador := 1 To Posicao - 1 do
        If (not FileSeek(ArquivoRegistros, TamanhoTotalBuffer, ctSeekCur, NovaPosicao)) Then
            CodigoDeErro (true);
    ResultadoBlockRead := FileBlockRead(ArquivoRegistros, vetorbuffer, 1);
{
    writeln(vetorbuffer);
}
(* Copia o hash do nome do arquivo e apaga o que nao sera usado *)      

    fillchar(HashEmTexto,length(HashEmTexto),byte( ' ' ));
    HashEmTexto := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    val(HashEmTexto,hash,RetornoDoVal);
    Ficha.hash := hash;

(* Copia o nome do arquivo e apaga o que nao sera usado *)
    fillchar(Ficha.NomeDoArquivo,length(Ficha.NomeDoArquivo),byte( ' ' ));
    Ficha.NomeDoArquivo := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));

(* Copia o Diretorio e apaga o que nao sera usado *)
    fillchar(Ficha.Diretorio,length(Ficha.Diretorio),byte( ' ' ));
    Ficha.Diretorio := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));

end;

function CalculaHash (NomeDoArquivo: TFileName): integer;
var
    i, hash: integer;
    a, hash2: real;
    
begin
    hash:=0;
    hash2:=0.0;
    for i:=1 to length(NomeDoArquivo) do
    begin
(*  Aqui temos um problema. A funcao ModuloDoHash nao pode ser usada com
    reais e foi necessario usar reais porque o valor e muito grande
    para trabalhar com inteiros - estoura o LimiteDeBuscas.
    Modulo = resto da divisao inteira: c <- a - b * (a / b).
*)
        a := (hash2 * b + ord(NomeDoArquivo[i]));
        hash2 := (a - ModuloDoHash * int(a / ModuloDoHash));
        hash := round(hash2);
    end;
    CalculaHash := hash;
end;

procedure LeArquivoDeHashes(hash, Tamanho, TotalDeRegistros: integer);
var
    entradas, linha, repeticoes, contador: integer;
    letra: char;

    lidos: integer;
    fimdoarquivo: boolean;
    
begin
(* Le com um blockread e separa, jogando cada hash em uma posicao em um vetor. *)

    linha := 1;
    entradas := 1;
    HashEmTexto := ' ';
    fimdoarquivo := false;
    fillchar(vetorbuffer, TamanhoTotalBuffer, byte( ' ' ));
    fillchar(HashEmTexto, 6, byte( ' ' ));
{
	writeln('hash: ',hash,' Tamanho: ',Tamanho,' TotalDeRegistros: ',TotalDeRegistros);
}
	while (fimdoarquivo = false) or (linha < (Tamanho - 1)) or (entradas < TotalDeRegistros) do 
    begin
        if not (FileSeek (ArquivoHashes, TamanhoTotalBuffer, ctSeekCur, NovaPosicao)) then
            CodigoDeErro (true);
        ResultadoBlockRead := FileBlockRead (ArquivoHashes, vetorbuffer, TamanhoTotalBuffer);
        delete(vetorbuffer,1,32);
{
        writeln('vetorbuffer: ',vetorbuffer);
}
        Posicao := 1;
        while (Posicao <= HashesPorLinha) do
        begin
            contador := 0;
            fillchar(HashEmTexto, 6, byte( ' ' ));
            HashEmTexto := copy(vetorbuffer, 1, pos(',',vetorbuffer));
            delete(vetorbuffer, 1, pos(',',vetorbuffer));
            letra := HashEmTexto[pos(',',HashEmTexto) - 1];
            delete(HashEmTexto, pos(',',HashEmTexto) - 1, (pos(',',HashEmTexto)));
            val(HashEmTexto, hash, RetornoDoVal);
{
            writeln('Hash em texto: ',HashEmTexto,' hash: ',hash,' letra: ',letra);
}
            for repeticoes := 0 to (ord ( letra ) - 65) do
            begin
                VetorHashes[entradas + repeticoes] := hash;
                contador := contador + 1;
{
                writeln('VetorHashes[',entradas + repeticoes,']=',VetorHashes[entradas + repeticoes]);
}
            end;
          
            entradas := entradas + contador;
            Posicao := Posicao + 1;
        end;
{
		writeln('Linha: ',linha,' TotalDeRegistros: ',TotalDeRegistros,' entrada: ',entradas,' Tamanho: ',Tamanho);
}
        fillchar(vetorbuffer, TamanhoTotalBuffer, byte( ' ' ));
        linha := linha + 1;
        
        if (lidos = ctReadWriteError) then
        begin
            CodigoDeErro (false);
            fimdoarquivo := true;
        end;
    end;
end;

procedure LocateAjuda;
begin
    fastwriteln(' Uso: locate <padrao> <parametros>.');
    fastwriteln(' Faz buscas em um banco de dados criado com a lista de arquivos do dispositivo.');
    fastwriteln(' ');
    fastwriteln(' Padrao: Padrao a ser buscado no banco de dados.');
    fastwriteln(' ');
    fastwriteln(' Parametros: ');
    fastwriteln(' /a ou /change    - Muda para o Diretorio onde o arquivo esta.');
    fastwriteln(' /c ou /count     - Mostra quantas entradas foram encontradas.');
    fastwriteln(' /h ou /help      - Traz este texto de ajuda e sai.');
    fastwriteln(' /l n ou /limit n - Limita a saida para n entradas.');
    fastwriteln(' /p ou /prolix    - Mostra tudo o que o comando esta fazendo.');
    fastwriteln(' /s ou /stats     - Exibe estatisticas do banco de dados.');
    fastwriteln(' /v ou /version   - Exibe a VersaoMSXDOS do comando e sai.');
    fastwriteln(' ');
    halt;
end;

procedure LocateVersao;
begin
    fastwriteln('locate VersaoMSXDOS 0.1'); 
    fastwriteln('Copyright (c) 2020 Brazilian MSX Crew.');
    fastwriteln('Alguns direitos reservados.');
    fastwriteln('Este software e distribuido segundo a licenca GPL.');
    fastwriteln(' ');
    fastwriteln('Este programa e fornecido sem garantias na medida do permitido pela lei.');
    fastwriteln(' ');
    fastwriteln('Notas de VersaoMSXDOS: ');
    fastwriteln('No momento, esse comando apenas faz busca por nomes exatos de arquivos');
    fastwriteln('no banco de dados. Ele ainda nao faz buscas em nomes incompletos ou em');
    fastwriteln('diretorios. Ele tambem so faz uso de um parametro por vez.');
    fastwriteln('No futuro, teremos o uso de dois ou mais parametros, faremos a busca em');
    fastwriteln('nomes incompletos, diretorios e sera possivel executar o comando CD para');
    fastwriteln('o Diretorio onde o arquivo esta.');
    fastwriteln(' ');
    fastwriteln('Configuracao: ');
    fastwriteln('A principio o banco de dados do locate esta localizado em a:\UTILS\LOCATE\DB.');
    fastwriteln('Se quiser trocar o Caminho, voce deve alterar a variavel de ambiente LOCALEDB,');
    fastwriteln('no MSX-DOS. Faca essas alteracoes no AUTOEXEC.BAT, usando o comando SET.');
    fastwriteln(' ');
    halt;
end;

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

BEGIN
    parametro := 0;
    LimiteDeBuscas := 0;
    temporario1 := ' ';
    temporario2 := ' ';
    fillchar(temporario1,length(temporario1),byte( ' ' ));
    fillchar(temporario2,length(temporario2),byte( ' ' ));

    clrscr;

    GetMSXDOSVersion ( VersaoMSXDOS );

    if ( VersaoMSXDOS.nKernelMajor < 2 ) then
    begin
        fastwriteln('MSX-DOS 1.x não suportado.');
        halt;
    end
    else 
    begin
        fillchar(temporario,length(temporario),byte( ' ' ));
        fillchar(Caminho,TamanhoTotalBuffer,byte( ' ' ));
        temporario[0] := 'l';
        temporario[1] := 'o';
        temporario[2] := 'c';
        temporario[3] := 'a';
        temporario[4] := 'l';
        temporario[5] := 'e';
        temporario[6] := 'd';
        temporario[7] := 'b';
        temporario[8] := #0;
       
        Caminho[0] := #0;
        with Registros do
        begin
            B := sizeof ( Caminho );
            C := ctGetEnvironmentItem;
            HL := addr ( temporario );
            DE := addr ( Caminho );
        end;
   
        MSXBDOS ( Registros );
        LetraDeDrive := Caminho[0];
        insert(LetraDeDrive, Caminho, 1);
    end;
        
    if Caminho = '' then Caminho := 'a:\utils\locale\db\'; 
   
    for b := 1 to 4 do VetorParametros[b] := paramstr(b);

(* Sem parametros o comando apresenta o help. *)

    if paramcount = 0 then LocateAjuda;

(* Antes de tratar como seria com um parametro, pega tudo e passa *)
(* para maiusculas. *)
    
    for j := 1 to 3 do
    begin
        temporario := paramstr(j);
        if pos('/',temporario) <> 0 then
            parametro := j;
        for b := 1 to length(temporario) do
            temporario[b] := upcase(temporario[b]);
        VetorParametros[j] := temporario;
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

    if Caractere = 'L' then
    begin
        val(VetorParametros[parametro + 1],LimiteDeBuscas,RetornoDoVal);
        LimiteDeBuscas := LimiteDeBuscas - 1;
    end;
    
    for b := 1 to 2 do
        if pos('.',VetorParametros[b]) <> 0 then parametro := b;

(* O 1o parametro e o nome a ser pesquisado. *)
    
    pesquisa := VetorParametros[parametro];
{
    NomeArquivoRegistros := 'teste.dat';
    NomeArquivoHashes := 'teste.hsh';
}
    PrimeiraLetra := upcase(pesquisa[1]);
    
    fillchar(NomeArquivoRegistros,length(NomeArquivoRegistros),byte( ' ' ));
    fillchar(NomeArquivoHashes,length(NomeArquivoHashes),byte( ' ' ));
    
    delete(Caminho,LastPos('\',Caminho),length(Caminho));
    
    NomeArquivoRegistros := concat(Caminho, PrimeiraLetra, '.dat');
    NomeArquivoHashes := concat(Caminho, PrimeiraLetra, '.hsh');

    writeln(NomeArquivoRegistros);
    writeln(NomeArquivoHashes);
    
(* Abre os arquivos de registros e de hashes *)

    if Caractere = 'P' then fastwriteln('Abre arquivo de registros');
    ArquivoRegistros := FileOpen (NomeArquivoRegistros, 'r');

    if Caractere = 'P' then fastwriteln('Abre arquivo de hashes');
    ArquivoHashes := FileOpen (NomeArquivoHashes, 'r');

(* Testa se há algum problema com os arquivos. Se há, encerra. *)

    if (ArquivoRegistros in [ctInvalidFileHandle, ctInvalidOpenMode] )  then
        CodigoDeErro (true);

    if (ArquivoHashes in [ctInvalidFileHandle, ctInvalidOpenMode] )  then
        CodigoDeErro (true);
    
(* Le de um arquivo separado o hash *)
(* Na posicao 0 temos o valor de b, o ModuloDoHash, o máximo de entradas *)
(* e o numero de linhas. *)

    fillchar(vetorbuffer, TamanhoTotalBuffer, byte( ' ' ));
    ResultadoSeek := FileSeek (ArquivoHashes, 0, ctSeekSet, NovaPosicao);
    ResultadoBlockRead := FileBlockRead (ArquivoHashes, vetorbuffer, 1);
    
    fillchar(temporario1, TamanhoNomeArquivo, byte( ' ' ));
    temporario1 := copy(vetorbuffer, 1, (pos(',',vetorbuffer) - 1));
    val(temporario1, b, RetornoDoVal);
    delete(vetorbuffer, 1, pos(',',vetorbuffer));
    
    fillchar(temporario2, TamanhoNomeArquivo, byte( ' ' ));
    temporario2 := copy(vetorbuffer, 1, (pos(',',vetorbuffer) - 1));
    val(temporario2, ModuloDoHash, RetornoDoVal);
    delete(vetorbuffer, 1, pos(',',vetorbuffer));
    
    fillchar(temporario3, TamanhoNomeArquivo, byte( ' ' ));
    temporario3 := copy(vetorbuffer, 1, (pos(',',vetorbuffer) - 1));
    val(temporario3, TotalDeRegistros, RetornoDoVal);
    delete(vetorbuffer, 1, pos(',',vetorbuffer));
    
    fillchar(temporario4,TamanhoNomeArquivo,byte( ' ' ));
    temporario4 := copy(vetorbuffer, 1, (pos(',',vetorbuffer) - 1));
    val(temporario4, Tamanho, RetornoDoVal);
    delete(vetorbuffer, 1, pos(',',vetorbuffer));
  
    if Caractere = 'S' then
    begin
        vetorbuffer := concat('Arquivo com os registros: ',NomeArquivoRegistros);
        fastwriteln(vetorbuffer);
        vetorbuffer := concat('Arquivo com os hashes: ',NomeArquivoHashes);
        fastwriteln(vetorbuffer);
        vetorbuffer := concat('b: ',temporario1,' ModuloDoHash: ',temporario2);
        fastwriteln(vetorbuffer);
        vetorbuffer := concat('Tamanho: ',temporario3, ' registros.');
        fastwriteln(vetorbuffer);
        vetorbuffer := concat('Numero de linhas: ',temporario4);
        fastwriteln(vetorbuffer);
    end;
    
    if Caractere = 'P' then
    begin
        str(Tamanho,temporario1);
        vetorbuffer := concat('Tamanho: ',temporario1, ' registros.');
        fastwriteln(vetorbuffer);
    end;

(* Le o arquivo de hashes, pegando todos os numeros de hash e salvando num vetor *)

    if Caractere = 'P' then fastwriteln('Le arquivo de hashes');
    LeArquivoDeHashes(hash, Tamanho, TotalDeRegistros);

(* Pede o nome exato de um arquivo a ser procurado *)

    if Caractere = 'P' then
    begin
        vetorbuffer := concat('Nome do arquivo: ', pesquisa);
        fastwriteln(vetorbuffer);
    end;
        
(* Calcula o hash do nome da pesquisa *)

    hash := CalculaHash(pesquisa);
    if Caractere = 'P' then
    begin
        str(hash, temporario1);
        vetorbuffer := concat('Hash do nome pesquisado: ', temporario1);
        fastwriteln(vetorbuffer);
    end;
    
(* Faz a busca binaria no vetor *)

    if Caractere = 'P' then fastwriteln('Faz busca.');
    BuscaBinariaNomeDoArquivo(hash, TotalDeRegistros, Posicao, Tentativas);
 
(* Tendo a posicao certa, le o registro e verifica se o nome bate. *)
(*  Ou entao, diz que nao tem aquele nome no arquivo *)

    if Posicao <> 0 then
    begin
        j := Posicao;
        HashTemporario := hash;
        while HashTemporario = hash do
        begin
            j := j - 1;
            HashTemporario := VetorHashes[j];
        end;
{
        writeln(' Existem mais ',(Posicao - j) - 1,' entradas iguais, de ',j + 1,' a ',Posicao,' - acima');
}
        Abaixo := j + 1;
        j := Posicao;
        HashTemporario := hash;
        while HashTemporario = hash do
        begin
            j := j + 1;
            HashTemporario := VetorHashes[j];
        end;
{
        writeln(' Existem mais ',(j - Posicao) - 1,' entradas iguais, de ',Posicao,' a ',j - 1,' - abaixo');
}
        Acima := j - 1;
        
        if Caractere = 'C' then
        begin
            str(((Acima - Abaixo) + 1),temporario1);
            vetorbuffer := concat('Numero de entradas encontradas: ',temporario1);
            fastwriteln(vetorbuffer);
        end;
                
        if Caractere = 'L' then Acima := Abaixo + LimiteDeBuscas;
            
        for j := Abaixo to Acima do
        begin
            LeFichaNoArquivoRegistros (j);
            if pesquisa = Ficha.NomeDoArquivo then
            begin
                if Caractere = 'P' then
                begin
                    str(j,temporario1);
                    str(Tentativas, temporario2);
                    vetorbuffer := concat('Posicao: ', temporario1,' Tentativas: ', temporario2,
                    ' Nome do arquivo: ', Ficha.NomeDoArquivo, ' Diretorio: ', Ficha.Diretorio);
                    fastwriteln(vetorbuffer);
                end
                else
                begin
                    vetorbuffer := concat(Ficha.Diretorio, '\', Ficha.NomeDoArquivo);
                    fastwriteln(vetorbuffer);
                end;
            end;
        end;
    end
        else
            fastwriteln('Arquivo nao encontrado.');

(* Fecha o arquivo *)
    if Caractere = 'P' then fastwriteln('Fecha arquivo.');
    
    if (not FileClose(ArquivoRegistros)) then
        CodigoDeErro(true);
        
    if (not FileClose(ArquivoHashes)) then
        CodigoDeErro(true);

END.
