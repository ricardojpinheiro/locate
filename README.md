# locate

Este é um utilitário para MSX cujo objetivo é funcionar de forma semelhante ao locate do Linux. Ele requer MSX-DOS 2, mas funciona em 40 ou 80 colunas. O código está escrito em Turbo Pascal, e está liberado segundo a GPL.

## Algumas explicações.

A ideia é que a lista seja feita em um computador IBM-PC compatível, que tem poder de processamento de sobra para gerá-la. O MSX fará a consulta na mesma. Logo, há um programa, chamado `updatedb.py` (escrito em Python), que gerará a lista. E o programa locate fará a busca.

## Sobre o `updatedb.py`.

**Sintaxe**: `updatedb.py` \<arquivo de configurações\>

Este script em Python criará os arquivos DAT que serão usados pelo locate no MSX para realizar a busca. Ele também cria os arquivos TXT, que não serão usados, podendo ser descartados pelo usuário.

Configuração: O \<arquivo de configurações\> deve seguir o seguinte formato:

\<caminho completo até o diretório que será indexado\>,\<letra de drive\>

**Exemplo:**

`/home/fulano/MSX/Arquivos/SD/DIVERSOS,A:`

`/home/fulano/MSX/Arquivos/SD/JOGOS,B:`

`/home/fulano/MSX/Arquivos/SD/MUSICA,C:`

`/home/fulano/MSX/Arquivos/SD/MAGAZINE,D:`

Observação: Após a letra de drive, tem o : (dois pontos). Isto se repetirá para cada letra de drive.

## Configurações prévias no MSX

No arquivo `AUTOEXEC.BAT`, crie uma variável de ambiente, chamada `LOCATEDB`, que deve apontar onde estão os arquivos de dados.

**Exemplo:** 
`SET LOCATEDB=A:\UTILS\LOCATE\DB\`

A variável de ambiente `LOCATEDB` apontará para o diretório A:\UTILS\LOCATE\DB, e é lá que o locate vai procurar os arquivos.

## Sobre o locate.

Você passa um padrão de pesquisa e eventualmente um parâmetro. O locate pega a primeira letra desse padrão e vai buscar no arquivo correspondente (se for um número, está no arquivo NUM.DAT). Ele realiza a busca binária nesse arquivo, e caso ocorram colisões (mais de um arquivo com o mesmo hash), ele entrega o primeiro resultado que ele encontrou.

## Parâmetros do locate.
 
- /a - Exibe todas as correspondências encontradas.
- /c - Exibe a quantidade de correspondências encontradas.
- /dX - Exibe correspondências relacionadas à letra de unidade especificada (X).
- /f  - Exibe o nome do arquivo, o caminho, o hash e em quantos passos ele encontrou o resultado.
- /ln – Encerra a busca após n correspondências.
- /h - Exibe esta ajuda e encerra.
- /v  - Exibe informações da versão e encerra.
 
## Sobre o código.

Além de um bom tempo investido por mim, há a ajuda inestimável das bibliotecas em Pascal criadas pelos irmãos Lammassaari e pelo PopolonY2K. Os arquivos (enxugados, claro, o MSX não tem memória pra dar e vender) estão no repositório, e tem a extensão .PAS.

## Limitações do locate.

1. Esse programa não faz buscas em nomes incompletos ou em diretórios. No momento, ele apenas faz busca por nomes exatos de arquivos no banco de dados.  
2. Esse programa só permite o uso de um parâmetro por vez, na ordem determinada na ajuda do comando.

## Desempenho.

No teste que tenho feito aqui, (4 diretórios, 76641 arquivos), o tempo varia em proporção direta ao tamanho do arquivo de hash. Logo, uma busca em arquivos que começam com Q (473 arquivos) são muito mais rápidos do que uma busca em arquivos que começam com M (8099 arquivos).

Fiz uma medição com o OpenMSX, em um MSX 2 padrão, com MSX-DOS 2 e acesso a disco. Usei um arquivo com 1000 registros, mais o arquivo de hashes dentro do mesmo diretório. Procurei por um nome de arquivo que aparecia pelo menos 8 vezes naquele arquivo. No último teste (marcado com o cronômetro do meu relógio) o MSX foi capaz de entregar o resultado em 7,3 segundos. Todo.

Ah, tem muitas coisas ainda a serem mexidas. Segue a lista: No script updatedbmsx.sh:

```
    O script deverá também criar a pasta na partição correspondente ao drive A do cartão/pendrive a ser usado no MSX, e acrescentar o SET LOCATEDB=a:\\UTILS\\LOCATE\\DB no AUTOEXEC.BAT. Essa funcionalidade, a propósito, está feita mas precisa de testes.
```

No utilitário update: Otimização.

```
É sabido que o MSX trabalha com setores de 512 bytes, e independente do tamanho (menor) que você use, o MSX-DOS 2 lerá 512 bytes. Logo, a ideia é fazer com que até 4 registros fiquem em cada setor do disco. Quando ler, o MSX lerá logo 4 registros, e terá que buscar dentro deles. O acesso será mais rápido.  
Se aumentarmos o tamanho de cada registro para 512 bytes, o arquivo de hashes poderá ter até 72 entradas por registro (no momento temos 36). O processo de leitura seria abreviado pela metade.
```

No utilitário locate:

```
Parâmetro riscado lá em cima - será possível fazer com que ele execute o comando cd para já colocar o prompt no diretório onde aquele arquivo está.  
Reconhecer se estamos rodando com 40 ou 80 colunas, e formatar o documento dessa forma.  
Traduzir todas as mensagens para inglês. Aliás, prever a internacionalização de software é uma boa ideia... Para o futuro.
```

Otimização

```
Ao ler um "registrão" de 512 bytes, teria que fazer a busca dentro desse registrão pra saber qual das 4 entradas contém a entrada desejada.  
Aumentando a densidade de entradas por registro no arquivo de hashes, ganhamos em desempenho.  
Na hora de movimentar o ponteiro pelo arquivo de registros, seria interessante fazer a leitura a partir do início e também a partir do fim. Exemplo: Um arquivo tem 2000 registros. Você pode começar do registro 1 ou do registro 2000, indo para frente ou para trás. Claro que o pior caso será quanto mais próximo do meio o registro estiver. Mas há um visível ganho de performance.  
  
E a pergunta que não quer calar: Quando eu vou fazer isso? Já aviso: Não será agora. Esse código tem sido um grande aprendizado para mim, mas agora eu quero parar e investir em coisas novas. Quando eu tiver paciência, eu volto e faço essas alterações. Ou então você mesmo pode fazer, aifnal das contas, é código aberto, né? :-D
```

Extras que são necessários:

```
Eu tenho um script pronto para fazer o trabalho sujo no Linux. Preciso de um script para fazer a mesma coisa no Windows. Não, eu não sei Powershell, e nem uso Windows, a não ser quando quero que entre um ar na minha casa. :-D Logo, vou precisar da ajuda de alguém.  
Preciso compilar o update em uma máquina Windows, com o Free Pascal Compiler, e testar. Alguém disposto a ajudar? Como vocês sabem, eu não uso Windows, não pretendo usar e não vou instalar uma VM de Windows 7 só pra isso. Cai no mesmo problema do Python (que eu falo aí embaixo).  
Já houve uma sugestão de fundir o script com o update e fazer um programa só em outra linguagem, como Python, por exemplo. Seria ótimo... Se eu soubesse Python. Entendam que eu fiz em Pascal porque é a linguagem que eu sei, e eu não vou aprender uma linguagem nova de programação somente para resolver um problema. Claro que eu não desprezo Python, pelo contrário, concordo com a afirmação de que Python vai salvar o mundo. Ainda não sabemos como, mas que vai, vai! Mas minha prioridade é o MSX.
```

Futuro:

Tudo isso que você está vendo deve estar disponível quando a versão inicial ficar pronta. Agora, as seguintes podem demorar:

```
Uso de dois ou mais parâmetros simultaneamente.  
Busca em nomes incompletos.  
Busca em diretórios.  
    Diminuição da quantidade de variáveis usadas, limpeza de constantes e tipos não usados (já fiz alguma coisa, mas farei melhor depois).
```

Notas de versão. (c) 2020-2026 Brazilian MSX Crew. Alguns direitos reservados, mas a licença é a GPL. Então... Obedeça-a. Mas aceito sugestões, correções, melhorias. Ideias são sempre bem-vindas. Mas críticas destrutivas, tipo "esse código tá uma bosta, faz em ASM de Z80 que é melhor" receberão de resposta um vai a m\* bem sonoro e serão remetidas para `/dev/null`.

