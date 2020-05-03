{
   locate06.pas
   
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

program locate06;

{$i d:dvram.inc}
    
const
    tamanhonomearquivo = 40;
    tamanhototalbuffer = 127;
    tamanhodiretorio = 87;
    max = 1500;
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
    nomearquivoregistros: filename;
    nomearquivohashes: filename;
    vetorhashes: registervector;
    vetorbuffer: buffervector;
    temporario: buffervector;
    entradadocomando: array [1..4] of filename;
    pesquisa, temporario1, temporario2: filename;
    ficha: registro;
    b, modulo, tamanho, posicao, tentativas, maximo: integer;
    j, hash, hashtemporario, cima, baixo, limite: integer;
    parametro: byte;
    caractere: char;
(**)
    handle: TOutputHandle;

procedure buscabinarianomearquivo (vetorhashes: registervector; hash: integer; var posicao, tentativas: integer);
var
    comeco, meio, fim: integer;
    encontrou: boolean;
            
begin
    comeco:=1;
    tentativas:=1;
    fim:=max;
    encontrou:=false;
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

function existearquivo (var arquivoregistros: registerfile; nomearquivoregistros: filename): boolean;
begin
    assign(arquivoregistros,nomearquivoregistros);
    {$i-}
    reset(arquivoregistros); 
    {$i+}
    existearquivo:=(IOResult = 0);
end;

procedure abrearquivoregistros (nomearquivoregistros: filename);
begin
    assign(arquivoregistros,nomearquivoregistros);
    reset(arquivoregistros);
end;

procedure abrearquivohashes (nomearquivohashes: filename);
begin
    assign(arquivohashes,nomearquivohashes);
    reset(arquivohashes);
end;

procedure fechaarquivoregistros;
begin
    close(arquivoregistros);
end;

procedure fechaarquivohashes;
begin
    close(arquivohashes);
end;

procedure leregistronoarquivo(var arquivoregistros: registerfile; var vetorbuffer: buffervector; posicao: integer);
var
    hash, retorno: integer;
    hashemtexto: string[5];
    
begin
    retorno:=0;
    hashemtexto:='';
    seek(arquivoregistros,posicao-1);
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

procedure learquivohashes;
var
    i, j, k, l, hash, contador, retorno: integer;
    vetorbuffer: buffervector;
    letra: char;
    hashemtexto, temporario1, temporario2, temporario3: string[7];
    
begin

(* Le de um arquivo separado o hash *)
(* Na posicao 0 temos o valor de b e o modulo. *)

    temporario1:=' ';
    fillchar(temporario1,length(temporario1),byte( ' ' ));
    temporario2:=' ';
    fillchar(temporario2,length(temporario2),byte( ' ' ));
    temporario3:=' ';
    fillchar(temporario1,length(temporario3),byte( ' ' ));
    vetorbuffer:=' ';
    fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
    seek(arquivohashes,0);
    blockread(arquivohashes,vetorbuffer,1,retorno);
    temporario1 := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    temporario2 := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    temporario3 := copy(vetorbuffer,1,(pos(',',vetorbuffer)-1));
    delete(vetorbuffer,1,pos(',',vetorbuffer));
    val(temporario1,b,retorno);
    val(temporario2,modulo,retorno);
    val(temporario3,maximo,retorno);
{   
    writeln('b: ',b,' modulo: ',modulo,' maximo: ',maximo);
}
(* Le com um blockread e separa, jogando cada hash em uma posicao em um vetor. *)

    i := 1;
    j := 1;
    hashemtexto := ' ';
    fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
    while j <= maximo do
    begin
        seek(arquivohashes,i);
        blockread(arquivohashes,vetorbuffer,1,retorno);
        delete(vetorbuffer,1,32);
{
        writeln('vetorbuffer: ',vetorbuffer);
}
        k := 1;
        while (k <= porlinha) do
        begin
            contador := 0;
            fillchar(hashemtexto,7,byte( ' ' ));
            hashemtexto := copy(vetorbuffer,1,pos(',',vetorbuffer));
            delete(vetorbuffer,1,pos(',',vetorbuffer));
            letra := hashemtexto[pos(',',hashemtexto) - 1];
            delete(hashemtexto,pos(',',hashemtexto) - 1,(pos(',',hashemtexto)));
            val(hashemtexto,hash,retorno);
{
            writeln('Hash em texto: ',hashemtexto,' hash: ',hash,' letra: ',letra);
}
            for l := 0 to (ord ( letra ) - 65) do
            begin
                vetorhashes[j + l] := hash;
                contador := contador + 1;
{
                writeln('vetorhashes[',j + l,']=',vetorhashes[j + l]);
}
            end;
{
            writeln('i: ',i,' j: ',j,' vetorbuffer: ',vetorbuffer);
}           
            j := j + contador;
            k := k + 1;
        end;
        fillchar(vetorbuffer,tamanhototalbuffer,byte( ' ' ));
        i := i + 1;
    end;
end;

procedure helpdocomando;
begin
    OpenDirectTextMode ( handle );
    writeln(' Uso: locate <padrao> <parametros>.');
    writeln(' Faz buscas em um banco de dados criado com a lista de arquivos do dispositivo.');
    writeln;
    writeln(' Padrao: Padrao a ser buscado no banco de dados.');
    writeln;
    writeln(' Parametros: ');
    writeln(' /a ou /change    - Muda para o diretorio onde o arquivo esta.');
    writeln(' /c ou /count     - Mostra quantas entradas foram encontradas.');
    writeln(' /h ou /help      - Traz este texto de ajuda e sai.');
    writeln(' /l n ou /limit n - Limita a saida para n entradas.');
    writeln(' /p ou /prolix    - Mostra tudo o que o comando está fazendo.');
    writeln(' /s ou /stats     - Exibe estatisticas do banco de dados.');
    writeln(' /v ou /version   - Exibe a versão do comando e sai.');
    writeln;
    CloseDirectTextMode ( handle );
    halt;
end;

procedure versaodocomando;
begin
    writeln('locate versao 0.1'); 
    writeln('Copyright (c) 2020 Brazilian MSX Crew.');
    writeln('Alguns direitos reservados.');
    writeln('Este software ainda nao se decidiu se sera distribuido sobre a GPL v. 2 ou nao.');
    writeln;
    writeln('Este programa e fornecido sem garantias na medida do permitido pela lei.');
    writeln;
    writeln('Notas de versao: ');
    writeln('No momento, esse comando apenas faz busca por nomes exatos de arquivos');
    writeln('no banco de dados. Ele ainda nao faz buscas em nomes incompletos ou em');
    writeln('diretorios. Ele tambem so faz uso de um parametro por vez.');
    writeln('No futuro, teremos o uso de dois ou mais parametros, faremos a busca em');
    writeln('nomes incompletos, diretorios e sera possivel executar o comando CD para');
    writeln('o diretorio onde o arquivo esta.');
    writeln;
    writeln('Configuracao: ');
    writeln('A principio o banco de dados do locate esta localizado em a:\UTILS\LOCATE\DB.');
    writeln('Se quiser trocar o caminho, voce deve alterar a variavel de ambiente LOCALEDB,');
    writeln('no MSX-DOS. Faca essas alteracoes no AUTOEXEC.BAT, usando o comando SET.');
    writeln;
    halt;
end;    

BEGIN
    parametro := 0;
    limite := 0;
    temporario1 := ' ';
    temporario2 := ' ';
    fillchar(temporario1,length(temporario1),byte( ' ' ));
    fillchar(temporario2,length(temporario2),byte( ' ' ));
   
    clrscr;

    OpenDirectTextMode (handle );
   
    for b := 1 to 4 do
        entradadocomando[b] := paramstr(b);

(* Sem parametros o comando apresenta o help. *)

    if paramcount = 0 then
        helpdocomando;

(* Antes de tratar como seria com um parametro, pega tudo e passa *)
(* para maiusculas. *)
    
    for j := 1 to 3 do
    begin
        temporario := paramstr(j);
        if pos('/',temporario) <> 0 then
            parametro := j;
        for b := 1 to length(temporario) do
            temporario[b] := upcase(temporario[b]);
        entradadocomando[j] := temporario;
    end;

(* Com um parametro. Se for o /h ou /help, apresenta o help.    *)  
(* Se for o /v ou /version, apresenta a versao do programa.     *)  
    
    caractere:=' ';
        
    if (entradadocomando[parametro] = '/A') or (entradadocomando[parametro] = '/CHANGE') then
        caractere := 'A';
    if (entradadocomando[parametro] = '/C') or (entradadocomando[parametro] = '/COUNT') then
        caractere := 'C';
    if (entradadocomando[parametro] = '/H') or (entradadocomando[parametro] = '/HELP') then
        helpdocomando;
    if (entradadocomando[parametro] = '/L') or (entradadocomando[parametro] = '/LIMIT') then
        caractere := 'L';
    if (entradadocomando[parametro] = '/P') or (entradadocomando[parametro] = '/PROLIX') then
        caractere := 'P';
    if (entradadocomando[parametro] = '/S') or (entradadocomando[parametro] = '/STATS') then
        caractere := 'S';
    if (entradadocomando[parametro] = '/V') or (entradadocomando[parametro] = '/VERSION') then
        versaodocomando;

    if caractere = 'L' then
    begin
        val(entradadocomando[parametro + 1],limite,b);
        limite := limite - 1;
    end;
    
    for b := 1 to 2 do
        if pos('.',entradadocomando[b]) <> 0 then
            parametro := b;

(* O 1o parametro e o nome a ser pesquisado. *)
    
    pesquisa := entradadocomando[parametro];

    nomearquivoregistros := 'teste.dat';
    nomearquivohashes := 'teste.hsh';

{
    primeiraletra := upcase(pesquisa[1]);
    
    nomearquivoregistros := concat(primeiraletra,'.dat');
    nomearquivohashes := concat(primeiraletra,'.hsh');
}
(* Abre o arquivo, informa números dele e vai pra busca *)

    if caractere = 'P' then writeln('Abre arquivo de registros');
    abrearquivoregistros(nomearquivoregistros);
    
    if caractere = 'P' then writeln('Abre arquivo de hashes');
    abrearquivohashes(nomearquivohashes);

    tamanho:=filesize(arquivoregistros);

    if caractere = 'S' then
    begin
        writeln('Arquivo com os registros: ',nomearquivoregistros);
        writeln('Arquivo com os hashes: ',nomearquivohashes);
        writeln('Tamanho: ',tamanho, ' registros.');
    end;
    
    if caractere = 'P'
    then    
        writeln('Tamanho do arquivo: ',tamanho,' registros.'); 

(* Le o arquivo de hashes, pegando todos os numeros de hash e salvando num vetor *)

    if caractere = 'P' then writeln('Le arquivo de hashes');
    learquivohashes;

(* Pede o nome exato de um arquivo a ser procurado *)

    if caractere = 'P'
    then
        writeln('Nome do arquivo: ', pesquisa);
        
(* Calcula o hash do nome da pesquisa *)

    hash:=calculahash(pesquisa);
    if caractere = 'P'
    then
        writeln('Hash do nome pesquisado: ',hash);
    
(* Faz a busca binaria no vetor *)

    if caractere = 'P' then writeln('Faz busca.');
    buscabinarianomearquivo(vetorhashes, hash, posicao, tentativas);
 
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
        
        if caractere = 'C'
        then
            writeln('Numero de entradas encontradas: ',(cima - baixo) + 1);
                
        if caractere = 'L' then cima := baixo + limite;
            
        for j := baixo to cima do
        begin
            leregistronoarquivo(arquivoregistros,vetorbuffer,j);
            if pesquisa = ficha.nomearquivo then
            begin
                if caractere = 'P' then
                    writeln('Posicao: ',j,' tentativas: ',tentativas,
                    ' Nome do arquivo: ',ficha.nomearquivo,' Diretorio: ',ficha.diretorio)
                else
                    writeln(ficha.diretorio,'\',ficha.nomearquivo);
            end;
        end;
    end
        else
            writeln('Arquivo nao encontrado.');

(* Fecha o arquivo *)
    if caractere = 'P' then
        writeln('Fecha arquivo.');
    fechaarquivoregistros;
    
    CloseDirectTextMode ( handle );
END.
