
# locate
Este é um utilitário para MSX cujo objetivo é funcionar de forma semelhante ao locate do Linux. Ele requer MSX-DOS 2, e a saída está formatada (a princípio) para 80 colunas. O código está escrito em Turbo Pascal, e está liberado segundo a GPL.

## Os links rápidos.
 - [Última versão do programa para fazer o update](update08.pas)
 - [Última versão do programa que faz a localização](locate08.pas)

## Algumas explicações.
A ideia é que a lista seja feita em um computador IBM-PC compatível, que tem poder de processamento de sobra para gerá-la. O MSX fará a consulta na mesma.
Logo, há um programa, chamado `update`, que gerará a lista. E o programa `locate` fará a busca.

## Como usar.
Há um script em shell (Bash), chamado `updatedbmsx.sh`, que cria os arquivos-texto para que o update crie os arquivos. 

A sintaxe é updatedbmsx.sh (caminho do diretório a ser indexado). Logo, o parâmetro que você deve passar é o caminho para o diretório inicial. Nesse diretório, deveremos ter diretórios, onde cada uma será uma partição do cartão SD. Se o seu cartão SD tiver 2 partições, coloque 2 pastas dentro dessa pasta, e o script entenderá que serão os drives A e B. Se você quiser ter 4 drives (A, B, C e D), crie 4 pastas e coloque os arquivos assim dispostos. Lembre-se que o A será o primeiro (na ordenação por nome), logo recomendo que você crie assim: 
 - 1_diretorio-1.
 - 2_diretorio-2.
 - 3_diretorio-3.
 - 4_diretorio-4.

O script executa os seguintes passos:
 - Monta toda a listagem, já trocando os caminhos "padrão Unix" para "padrão MS(X)-DOS". Este é um processo um pouco lento, o que me surpreendeu.
 - Gera as listas de arquivos, e executa o *update* para cada arquivo.
 - Gera a lista de arquivos que não se enquadra no item anterior, e coloca tudo em um arquivo separado.
 - Cria a pasta `A:\UTILS\LOCATE\DB` dentro da pasta que será o drive A, copia todos os arquivos para essa pasta.
 - Altera o AUTOEXEC.BAT do MSX, para setar uma variável de ambiente, a saber: `SET LOCATEDB=A:\UTILS\LOCATE\DB\`.
  
 No final, teremos 54 arquivos: 27 arquivos .DAT (0 e de A a Z), e 27 arquivos HSH (0 e de A a Z). Esses arquivos serão copiados para a pasta `A:\UTILS\LOCATE\DB`. Esta é a pasta padrão.

## Um pouco mais de detalhes.

### Sobre o update.
O update será executado no PC. O programa pega a base de dados que está no arquivo texto, gera os hashes de cada nome de arquivo, coloca tudo em um vetor e ordena-o. Ele cria dois arquivos não tipados (para ser lido com o comando `blockread`, do Pascal). Um contém o hash, o nome do arquivo e o diretório - tudo em maiúsculas porque o MSX-DOS não diferencia. O outro contém apenas o hash de cada entrada, e faz uma compressao desse arquivo usando o método RLE - Run Length Encoding.
A execução do update deve ser feita a partir do script que gera a lista inicial e a entrega já arrumada pro programa gerar os arquivos. É possível executar separadamente, usando `update <arquivo texto>` . Se você apenas executar o `update`, ele apresentará o resultado.

#### Parâmetros do update.
 - /h ou /help - Apresenta um texto de ajuda e sai.
 - /v ou /version - Apresenta a versão do comando, algumas notas de versão e sai.
 - /p ou /prolix - Informa tudo o que o programa está fazendo. É o modo *verbose*.
 
### Sobre o locate.
Esta explicação também está no cabeçalho do programa, então lá vai:
Você passa um padrão de pesquisa e eventualmente um parâmetro. Ele lê o arquivo de hashes correspondente, joga para um vetor na memória e faz a busca. Ele passa o padrão para maiúsculas, calcula o hash desse padrão, faz busca binária no vetor. Caso ele ache, ele procura o registro equivalente no arquivo de registros e entrega o resultado na saída padrão (a tela). Caso ocorram colisões (mais e um arquivo com o mesmo hash), ele faz uma busca sequencial no vetor para procurar as entradas idênticas e as imprime na tela também.

#### Parâmetros do locate.
 - /a ou /change    - Muda para o diretório onde o arquivo está.
 - /c ou /count     - Mostra quantas entradas foram encontradas.
 - /h ou /help      - Traz este texto de ajuda e sai.
 - /l n ou /limit n - Limita a saída para n entradas.
 - /p ou /prolix    - Mostra tudo o que o comando está fazendo.
 - /s ou /stats     - Exibe estatísticas do banco de dados e sai.
 - /v ou /version   - Apresenta a versão do comando, algumas notas e sai.

Nota: A função riscada é que ainda não está implementada.

#### Sobre o código.
Além de muito tempo investido por mim, há a ajuda inestimável das bibliotecas em Pascal criadas pelos irmãos [Lammassaari](http://pascal.hansotten.com/delphi/turbo-pascal-on-cpm-msx-dos-and-ms-dos/) e pelo [PopolonY2K](https://sourceforge.net/projects/oldskooltech/). Os arquivos (enxugados, claro, o MSX não tem memória pra dar e vender) estão no repositório, e tem a extensão .INC.

#### Limitações do locate.
- Esse programa não faz buscas em nomes incompletos ou em diretórios.  No momento, ele apenas faz busca por nomes exatos de arquivos no banco de dados. 
- Esse programa só permite o uso de um parâmetro por vez, na ordem determinada na ajuda do comando.

#### Desempenho.
No teste que tenho feito aqui, (4 diretórios, 76641 arquivos), o tempo varia em proporção direta ao tamanho do arquivo de hash. Logo, uma busca em arquivos que começam com Q (473 arquivos) são muito mais rápidos do que uma busca em arquivos que começam com M (8099 arquivos). 

Fiz uma medição com o OpenMSX, em um MSX 2 padrão, com MSX-DOS 2 e acesso a disco. Usei um arquivo com 1000 registros, mais o arquivo de hashes dentro do mesmo diretório. Procurei por um nome de arquivo que aparecia pelo menos 8 vezes naquele arquivo. No último teste (marcado com o cronômetro do meu relógio)  o MSX foi capaz de entregar o resultado em 7,3 segundos.

## Todo.
Ah, tem muitas coisas ainda a serem mexidas. Segue a lista:

### No script updatedbmsx.sh:
- - ~~O script deverá também criar a pasta na partição correspondente ao drive A do cartão/pendrive a ser usado no MSX, e acrescentar o SET LOCATEDB=a:\UTILS\LOCATE\DB no AUTOEXEC.BAT.~~ Essa funcionalidade, a propósito, está feita mas precisa de testes.

### No utilitário update:
#### Otimização.
- É sabido que o MSX trabalha com setores de 512 bytes, e independente do tamanho (menor) que você use, o MSX-DOS 2 lerá 512 bytes. Logo, a ideia é fazer com que até 4 registros fiquem em cada setor do disco. Quando ler, o MSX lerá logo 4 registros, e terá que buscar dentro deles. O acesso será mais rápido.
- Se aumentarmos o tamanho de cada registro para 512 bytes, o arquivo de hashes poderá ter até 72 entradas por registro (no momento temos 36). O processo de leitura seria abreviado pela metade.

### No utilitário locate:
- Parâmetro riscado lá em cima - será possível fazer com que ele execute o comando cd para já colocar o prompt no diretório onde aquele arquivo está.
- Reconhecer se estamos rodando com 40 ou 80 colunas, e formatar o documento dessa forma.
- Traduzir todas as mensagens para inglês. Aliás, prever a internacionalização de software é uma boa ideia... Para o futuro.

#### Otimização
- Ao ler um "registrão" de 512 bytes, teria que fazer a busca dentro desse registrão pra saber qual das 4 entradas contém a entrada desejada. 
- Aumentando a densidade de entradas por registro no arquivo de hashes, ganhamos em desempenho.
- Na hora de movimentar o ponteiro pelo arquivo de registros, seria interessante fazer a leitura a partir do início e também a partir do fim. Exemplo: Um arquivo tem 2000 registros. Você pode começar do registro 1 ou do registro 2000, indo para frente ou para trás. Claro que o pior caso será quanto mais próximo do meio o registro estiver. Mas há um visível ganho de performance.

> E a pergunta que não quer calar: **Quando eu vou fazer isso?** Já aviso: *Não será agora*. Esse código tem sido um grande aprendizado para mim, mas agora eu quero parar e investir em coisas novas. Quando eu tiver paciência, eu volto e faço essas alterações. Ou então você mesmo pode fazer, aifnal das contas, é código aberto, né? :-D

#### Extras que são necessários:
- Eu tenho um script pronto para fazer o trabalho sujo no Linux. Preciso de um script para fazer a mesma coisa no Windows. **Não, eu não sei Powershell, e nem uso Windows**, a não ser quando quero que entre um ar na minha casa. :-D Logo, vou precisar da ajuda de alguém. 
- Já houve uma sugestão de fundir o script com o `update` e fazer um programa só em outra linguagem, como Python, por exemplo. Seria ótimo... Se eu soubesse Python. Entendam que eu fiz em Pascal porque é a linguagem que eu sei, e **eu não vou aprender uma linguagem nova de programação somente para resolver um problema**. Claro que eu não desprezo Python, pelo contrário, concordo com a afirmação de que *Python vai salvar o mundo. Ainda não sabemos como, mas que vai, vai!* Mas minha prioridade é o MSX.

#### Futuro:
Tudo isso que você está vendo deve estar disponível quando a versão inicial ficar pronta. Agora, as seguintes podem demorar:
 - Uso de dois ou mais parâmetros simultaneamente.
 - Busca em nomes incompletos.
 - Busca em diretórios.
 - - Diminuição da quantidade de variáveis usadas, limpeza de constantes e
 tipos não usados (já fiz alguma coisa, mas farei melhor depois).

# Notas de versão.
(c) 2020 Brazilian MSX Crew. Alguns direitos reservados, mas a licença é a GPL. Então... Obedeça-a. Mas aceito sugestões, correções, melhorias. Ideias são sempre bem-vindas. Mas críticas destrutivas, tipo "*esse código tá uma bosta, faz em ASM de Z80 que é melhor*" receberão de resposta um **vai a m*** bem sonoro e serão remetidas para `/dev/null`.
