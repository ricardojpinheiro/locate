{
   locate07.pas
   
   Copyright 2020 Ricardo Jurczyk Pinheiro <ricardo@aragorn>
  
* Temos aqui os seguintes passos: teste se é MSX-DOS 2 ou não; leitura
* da variável de ambiente; leitura dos parâmetros passados pelo usuário
* (se não tiver nenhum, ele exibe o help); Com base no padrão a ser 
* procurado (o programa coloca o padrão todo em maiúsculas - o MSX-DOS
* não diferencia), ele vai ler o arquivo correspondente e vai importar
* pra memória o arquivo de hashes (que esta compactado com um metódo de
* compressão RLE), jogando-o para um vetor na memória. A busca é feita
* com base no hash: Ele calcula o hash do padrao e faz uma busca binária
* no vetor. Achando, ele faz a busca pelas colisões, pega os registros
* no arquivo de registros e coloca a informacao na tela. Agora estamos
* usando bibliotecas (enxugadas) dos irmãos Lammassaari (fastwrit.inc)
* e do PopolonY2K (types.inc e dos.inc).
}

program locate07;

{$i d:types.inc}
{$i d:dos.inc}
{$i d:fastwrit.inc}

const
    tamanhonomearquivo = 40;
    tamanhototalbuffer = 127;
    tamanhodiretorio = 87;
    max = 9000;
    porlinha = 15;

type
    absolutepath = string[tamanhodiretorio];
    filename = string[tamanhonomearquivo];
    buffervector = string[tamanhototalbuffer];
    registerfile = file;
    hashfile = file;
    registro = record
        hash: integer;
        nomearquivo: string[tamanhonomearquivo];
        diretorio: string[tamanhodiretorio];
    end;
    registervector = array[1..max] of integer;
    
var
    arquivoregistros: registerfile;
    arquivohashes: hashfile;
    nomearquivoregistros, nomearquivohashes: filename;
    caminho, vetorbuffer: buffervector;
    vetorhashes: registervector;
    entradadocomando: array [1..4] of filename;
    pesquisa: filename;
    temporario, temporario2: string[9];
    ficha: registro;
    b, modulo, tamanho, posicao, tentativas, maximo, retorno: integer;
    j, hash, hashtemporario, cima, baixo, limite: integer;
    parametro: byte;
    caractere, primeiraletra: char;
    versao : TMSXDOSVersion;
    
    registros: TRegs;
    letradedrive: char;
    
procedure buscabinarianomearquivo (hash, fim: integer; var posicao, tentativas: integer);
var
    comeco, meio: integer;
    encontrou: boolean;
            
begin
    comeco      :=  1;
    tentativas  :=  1;
    fim         :=  maximo;
    encontrou   :=  false;
    while (comeco <= fim) and (encontrou = false) do
    begin
        meio:=(comeco+fim) div 2;
{
        writeln('Comeco: ',comeco,' Meio: ',meio,' fim: ',fim,' hash: ',hash,' Pesquisa: ',vetorhashes[meio]);
}       
        if (hash = vetorhashes[meio]) then
            encontrou:=true
        else
            if (hash < vetorhashes[meio]) then
                fim:=meio-1
            else
                comeco:=meio+1;
        tentativas:=tentativas+1;
    end;
    if encontrou = true then
        posicao:=meio;
end;

procedure leregistronoarquivo(var arquivoregistros: registerfile; var vetorbuffer: buffervector; posicao: integer);
var
    hash: integer;
    hashemtexto: string[5];
    
begin
    retorno:=0;
    hashemtexto:='';
    seek(arquivoregistros,posicao - 1);
    blockread(arquivoregistros,vetorbuffer,1);
{
    writeln(vetorbuffer);
}

(* Copia o hash do nome do arquivo e apaga o que nao sera usado *)      

    fillchar(hashemtexto,length(hashemtexto),byte( ' ' ));
    hashemtexto := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    val(hashemtexto,hash,retorno);
    ficha.hash := hash;

(* Copia o nome do arquivo e apaga o que nao sera usado *)
    fillchar(ficha.nomearquivo,length(ficha.nomearquivo),byte( ' ' ));
    ficha.nomearquivo := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));

(* Copia o diretorio e apaga o que nao sera usado *)
    fillchar(ficha.diretorio,length(ficha.diretorio),byte( ' ' ));
    ficha.diretorio := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));

end;

function calculahash (nomearquivo: filename): integer;
var
    i, hash: integer;
    a, hash2: real;
    
begin
    hash:=0;
    hash2:=0.0;
    for i:=1 to length(nomearquivo) do
    begin
(*  Aqui temos um problema. A funcao modulo nao pode ser usada com
    reais e foi necessario usar reais porque o valor e muito grande
    para trabalhar com inteiros - estoura o limite.
    Modulo = resto da divisao inteira: c <- a - b * (a / b).
*)
        a := (hash2 * b + ord(nomearquivo[i]));
        hash2 := (a - modulo * int(a / modulo));
        hash := round(hash2);
    end;
    calculahash := hash;
end;

procedure learquivohashes(hash, tamanho, maximo: integer);
var
    registros, entradas, posicao, linha, repeticoes, contador: integer;
    letra: char;
    hashemtexto: string[6];
    
begin
(* Le com um blockread e separa, jogando cada hash em uma posicao em um vetor. *)

    linha := 1;
    entradas := 1;
    hashemtexto := ' ';
    fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
    fillchar(hashemtexto,6,byte( ' ' ));
{
    writeln('hash: ',hash,' tamanho: ',tamanho,' maximo: ',maximo);
}
    while (linha < (tamanho - 1)) or (entradas < maximo) do 
    begin
        seek(arquivohashes,linha);
        blockread(arquivohashes,vetorbuffer,1,retorno);
        delete(vetorbuffer,1,32);
{
        writeln('vetorbuffer: ',vetorbuffer);
}
        posicao := 1;
        while (posicao <= porlinha) do
        begin
            contador := 0;
            fillchar(hashemtexto,6,byte( ' ' ));
            hashemtexto := copy(vetorbuffer,1,pos(',',vetorbuffer));
            delete(vetorbuffer,1,pos(',',vetorbuffer));
            letra := hashemtexto[pos(',',hashemtexto) - 1];
            delete(hashemtexto,pos(',',hashemtexto) - 1,(pos(',',hashemtexto)));
            val(hashemtexto,hash,retorno);
{
            writeln('Hash em texto: ',hashemtexto,' hash: ',hash,' letra: ',letra);
}
            for repeticoes := 0 to (ord ( letra ) - 65) do
            begin
                vetorhashes[entradas + repeticoes] := hash;
                contador := contador + 1;
{
                writeln('vetorhashes[',entradas + repeticoes,']=',vetorhashes[entradas + repeticoes]);
}
            end;
          
            entradas := entradas + contador;
            posicao := posicao + 1;
        end;
{
        writeln('Linha: ',linha,' maximo: ',maximo,' entrada: ',entradas,' tamanho: ',tamanho);
}
        fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
        linha := linha + 1;
    end;
end;

procedure helpdocomando;
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
    halt;
end;

procedure versaodocomando;
begin
    fastwriteln('locate versao 0.5'); 
    fastwriteln('Copyright (c) 2020 Brazilian MSX Crew.');
    fastwriteln('Alguns direitos reservados.');
    fastwriteln('Este software e distribuido segundo a licenca GPL.');
    fastwriteln(' ');
    fastwriteln('Este programa e fornecido sem garantias na medida do permitido pela lei.');
    fastwriteln(' ');
    fastwriteln('Notas de versao: ');
    fastwriteln('No momento, esse comando apenas faz busca por nomes exatos de arquivos');
    fastwriteln('no banco de dados. Ele ainda nao faz buscas em nomes incompletos ou em');
    fastwriteln('diretorios. Ele tambem so faz uso de um parametro por vez.');
    fastwriteln('No futuro, teremos o uso de dois ou mais parametros, faremos a busca em');
    fastwriteln('nomes incompletos, diretorios e sera possivel executar o comando CD para');
    fastwriteln('o diretorio onde o arquivo esta.');
    fastwriteln(' ');
    fastwriteln('Configuracao: ');
    fastwriteln('A principio o banco de dados do locate esta localizado em a:\UTILS\LOCATE\DB.');
    fastwriteln('Se quiser trocar o caminho, voce deve alterar a variavel de ambiente LOCALEDB,');
    fastwriteln('no MSX-DOS. Faca essas alteracoes no AUTOEXEC.BAT, usando o comando SET.');
    fastwriteln(' ');
    halt;
end;

BEGIN
    parametro := 0;
    limite := 0;

    clrscr;

    GetMSXDOSVersion ( versao );

    if ( versao.nKernelMajor < 2 ) then
    begin
        fastwriteln('MSX-DOS 1.x não suportado.');
        halt;
    end
    else 
    begin
        fillchar(temporario,length(temporario),byte( ' ' ));
        fillchar(caminho,tamanhototalbuffer,byte( ' ' ));
        temporario[0] := 'l';
        temporario[1] := 'o';
        temporario[2] := 'c';
        temporario[3] := 'a';
        temporario[4] := 'l';
        temporario[5] := 'e';
        temporario[6] := 'd';
        temporario[7] := 'b';
        temporario[8] := #0;
       
        caminho[0] := #0;
        with registros do
        begin
            B := sizeof ( caminho );
            C := ctGetEnvironmentItem;
            HL := addr ( temporario );
            DE := addr ( caminho );
        end;
   
        MSXBDOS ( registros );
        letradedrive := caminho[0];
        insert(letradedrive,caminho,1);
    end;
   
    for b := 1 to 4 do entradadocomando[b] := paramstr(b);

(* Sem parametros o comando apresenta o help. *)

    if paramcount = 0 then helpdocomando;

(* Antes de tratar como seria com um parametro, pega tudo e passa *)
(* para maiusculas. *)
    
    for j := 1 to 3 do
    begin
        vetorbuffer := paramstr(j);
        if pos('/',vetorbuffer) <> 0 then
            parametro := j;
        for b := 1 to length(vetorbuffer) do
            vetorbuffer[b] := upcase(vetorbuffer[b]);
        entradadocomando[j] := vetorbuffer;
    end;

(* Com um parametro. Se for o /h ou /help, apresenta o help.    *)  
(* Se for o /v ou /version, apresenta a versao do programa.     *)  
    
    caractere:=' ';
    if (entradadocomando[parametro] = '/A') or (entradadocomando[parametro] = '/CHANGE')    then caractere := 'A';
    if (entradadocomando[parametro] = '/C') or (entradadocomando[parametro] = '/COUNT')     then caractere := 'C';
    if (entradadocomando[parametro] = '/H') or (entradadocomando[parametro] = '/HELP')      then helpdocomando;
    if (entradadocomando[parametro] = '/L') or (entradadocomando[parametro] = '/LIMIT')     then caractere := 'L';
    if (entradadocomando[parametro] = '/P') or (entradadocomando[parametro] = '/PROLIX')    then caractere := 'P';
    if (entradadocomando[parametro] = '/S') or (entradadocomando[parametro] = '/STATS')     then caractere := 'S';
    if (entradadocomando[parametro] = '/V') or (entradadocomando[parametro] = '/VERSION')   then versaodocomando;

    if caractere = 'L' then
    begin
        val(entradadocomando[parametro + 1],limite,retorno);
        limite := limite - 1;
    end;
    
    for b := 1 to 2 do
        if pos('.',entradadocomando[b]) <> 0 then parametro := b;

(* O 1o parametro e o nome a ser pesquisado. *)
    
    pesquisa := entradadocomando[parametro];
{
    nomearquivoregistros := 'teste.dat';
    nomearquivohashes := 'teste.hsh';
}
    primeiraletra := upcase(pesquisa[1]);
    
    retorno := ord(primeiraletra);
    
    if (retorno >= 65) and (retorno <= 90) and (retorno >= 97) and (retorno <= 122) then
        primeiraletra := '0';
    
    fillchar(nomearquivoregistros,length(nomearquivoregistros),byte( ' ' ));
    fillchar(nomearquivohashes,length(nomearquivohashes),byte( ' ' ));
    
    nomearquivoregistros := concat(primeiraletra,'.dat');
    nomearquivohashes := concat(primeiraletra,'.hsh');
    
(* Abre o arquivo, informa números dele e vai pra busca *)

    if caractere = 'P' then fastwriteln('Abre arquivo de registros');
    assign(arquivoregistros,nomearquivoregistros);
    reset(arquivoregistros);
    
    if caractere = 'P' then fastwriteln('Abre arquivo de hashes');
    assign(arquivohashes,nomearquivohashes);
    reset(arquivohashes);

(* Le de um arquivo separado o hash *)
(* Na posicao 0 temos o valor de b, o modulo, o máximo de entradas *)
(* e o numero de linhas. *)

    fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
    seek(arquivohashes,0);
    blockread(arquivohashes,vetorbuffer,1,retorno);
    
    fillchar(temporario,tamanhonomearquivo,byte( ' ' ));
    temporario := copy(vetorbuffer,1,(pos(',',vetorbuffer) - 1));
    val(temporario,b,retorno);
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    
    fillchar(temporario,tamanhonomearquivo,byte( ' ' ));
    temporario := copy(vetorbuffer,1,(pos(',',vetorbuffer) - 1));
    val(temporario,modulo,retorno);
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    
    fillchar(temporario,tamanhonomearquivo,byte( ' ' ));
    temporario := copy(vetorbuffer,1,(pos(',',vetorbuffer) - 1));
    val(temporario,maximo,retorno);
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    
    fillchar(temporario,tamanhonomearquivo,byte( ' ' ));
    temporario := copy(vetorbuffer,1,(pos(',',vetorbuffer) - 1));
    val(temporario,tamanho,retorno);
    delete(vetorbuffer,1,pos(',',vetorbuffer));
  
    if caractere = 'S' then
    begin
        str(b,temporario);
        str(modulo,temporario2);
        vetorbuffer := concat('b: ',temporario,' modulo: ',temporario2);
        fastwriteln(vetorbuffer);
        vetorbuffer := concat('Arquivo com os registros: ',nomearquivoregistros);
        fastwriteln(vetorbuffer);
        vetorbuffer := concat('Arquivo com os hashes: ',nomearquivohashes);
        fastwriteln(vetorbuffer);
        str(maximo,temporario);
        vetorbuffer := concat('Tamanho: ',temporario, ' registros.');
        fastwriteln(vetorbuffer);
        str(tamanho,temporario);
        vetorbuffer := concat('Numero de linhas: ',temporario);
        fastwriteln(vetorbuffer);
    end;
    
    if caractere = 'P' then
    begin
        str(tamanho,temporario);
        vetorbuffer := concat('Tamanho: ',temporario, ' registros.');
        fastwriteln(vetorbuffer);
    end;

(* Le o arquivo de hashes, pegando todos os numeros de hash e salvando num vetor *)

    if caractere = 'P' then fastwriteln('Le arquivo de hashes');
    learquivohashes(hash,tamanho,maximo);

(* Pede o nome exato de um arquivo a ser procurado *)

    if caractere = 'P' then
    begin
        vetorbuffer := concat('Nome do arquivo: ', pesquisa);
        fastwriteln(vetorbuffer);
    end;
        
(* Calcula o hash do nome da pesquisa *)

    hash:=calculahash(pesquisa);
    if caractere = 'P' then
    begin
        str(hash,temporario);
        vetorbuffer := concat('Hash do nome pesquisado: ',temporario);
        fastwriteln(vetorbuffer);
    end;
    
(* Faz a busca binaria no vetor *)

    if caractere = 'P' then fastwriteln('Faz busca.');
    buscabinarianomearquivo(hash, maximo, posicao, tentativas);
 
(* Tendo a posicao certa, le o registro e verifica se o nome bate. *)
(*  Ou entao, diz que nao tem aquele nome no arquivo *)

    if posicao <> 0 then
    begin
        j := posicao;
        hashtemporario := hash;
        while hashtemporario = hash do
        begin
            j := j - 1;
            hashtemporario := vetorhashes[j];
        end;
{
        writeln(' Existem mais ',(posicao - j) - 1,' entradas iguais, de ',j + 1,' a ',posicao,' - acima');
}
        baixo := j + 1;
        j := posicao;
        hashtemporario := hash;
        while hashtemporario = hash do
        begin
            j := j + 1;
            hashtemporario := vetorhashes[j];
        end;
{
        writeln(' Existem mais ',(j - posicao) - 1,' entradas iguais, de ',posicao,' a ',j - 1,' - abaixo');
}
        cima := j - 1;
        
        if caractere = 'C' then
        begin
            str(((cima - baixo) + 1),temporario);
            vetorbuffer := concat('Numero de entradas encontradas: ',temporario);
            fastwriteln(vetorbuffer);
        end;
                
        if caractere = 'L' then cima := baixo + limite;
            
        for j := baixo to cima do
        begin
            leregistronoarquivo(arquivoregistros,vetorbuffer,j);
            if pesquisa = ficha.nomearquivo then
            begin
                if caractere = 'P' then
                begin
                    str(j,temporario);
                    str(tentativas,temporario2);
                    vetorbuffer := concat('Posicao: ',temporario,' tentativas: ',temporario2,
                    ' Nome do arquivo: ',ficha.nomearquivo,' Diretorio: ',ficha.diretorio);
                    fastwriteln(vetorbuffer);
                end
                else
                begin
                    vetorbuffer := concat(ficha.diretorio,'\',ficha.nomearquivo);
                    fastwriteln(vetorbuffer);
                end;
            end;
        end;
    end
        else
            fastwriteln('Arquivo nao encontrado.');

(* Fecha o arquivo *)
    if caractere = 'P' then fastwriteln('Fecha arquivos.');
    close(arquivohashes);
    close(arquivoregistros);
END.
