
# locate

Esta é uma tentativa de um utilitário para MSX, semelhante ao locate, do Linux. Ele requer MSX-DOS 2, e a saída está formatada (a princípio) para 80 colunas. O código está escrito em Turbo Pascal.

## Os links rápidos.

- [Sexta versão do programa para fazer o update](update06.pas)
- [Sexta versão do programa que faz a localização](locate06.pas)

## Algumas explicações.

A ideia é que a lista seja feita em um computador IBM-PC compatível, que tem poder de processamento de sobra para gerá-la. O MSX fará a consulta na mesma.

Logo, há um programa, chamado *update*, que gerará a lista. E o programa *locate* fará a busca.

## Um pouco mais de detalhes.

### Sobre o update.
Esta explicação está no cabeçalho do programa, então lá vai:

 - Este código deve ser executado no PC. O programa vai puxar toda a base de dados do arquivo texto, gerar os hashes de cada nome de arquivo, colocar tudo em um vetor e ordená-lo. Ele cria um arquivo não tipado (para ser lido com blockread), contendo o hash, o nome do arquivo e o diretório - tudo em maiúsculas porque o MSX-DOS não diferencia. O programa também cria um segundo arquivo, somente com os hashes, e faz uma compressao desse arquivo usando o método RLE - Run Length Encoding.
 - A execução do update deve ser feita a partir de um script que gera a lista inicial e a entrega já arrumada pro programa gerar os arquivos. No caso, como sou usuário Linux e programador shell, fiz um shell script, o *updatedbmsx.sh*, que faz o serviço sujo. O processo é um pouco lento (o que me surpreendeu), mas do jeito que está, ele cria dois arquivos para cada letra do alfabeto (um com os registros e outro com os hashes) e para aqueles que não participam. Logo, serão no total 54 arquivos.

#### Parâmetros do update.
- /h ou /help - Apresenta um texto de ajuda e sai.
- /v ou /version - Apresenta a versão do comando, algumas notas de versão e sai.
- /p ou /prolix - Informa tudo o que o programa está fazendo.
 
### Sobre o locate.

Esta explicação também está no cabeçalho do programa, então lá vai:
 - Este código pode ate ser rodado no PC, mas a prioridade e o MSX. Ele vai ler o arquivo de hashes (que esta compactado com um método baseado em RLE) e jogar para um vetor na memória. O programa vai pedir um padrão de busca. O programa coloca o padrão todo em maiúsculas - o MSX-DOS não diferencia mesmo... Ele calcula o hash desse padrão de busca, faz-se uma  busca binária nesse vetor de hashes e, achando, lê o registro no arquivo de registros, colocando a informacao na tela. Acrescentei um trecho de código para procurar por colisões (com base no hash) e imprimir todas as entradas idênticas.
#### Parâmetros do locate.
 - /a ou /change    - ~~Muda para o diretório onde o arquivo está~~.
 - /c ou /count     - Mostra quantas entradas foram encontradas.
 - /h ou /help      - Traz este texto de ajuda e sai.
 - /l n ou /limit n - Limita a saída para n entradas.
 - /p ou /prolix    - Mostra tudo o que o comando está fazendo.
 - /s ou /stats     - Exibe estatísticas do banco de dados.
 - /v ou /version   - Apresenta a versão do comando, algumas notas de versão e sai.
Nota: A função riscada é que ainda não está implementada.
#### Limitações do locate.
No momento, esse comando apenas faz busca por nomes exatos de arquivos no banco de dados. Ele ainda não faz buscas em nomes incompletos ou em diretórios. Ele também só faz uso de um parâmetro por vez, mas o parâmetro pode estar fora de ordem.
#### Desempenho.
Fiz uma medição com o OpenMSX, em um MSX 2 padrão, com MSX-DOS 2 e acesso a disco. Usei um arquivo com 1000 registros, mais o arquivo de hashes dentro do mesmo diretório. Procurei por um nome de arquivo que aparecia pelo menos 8 vezes naquele arquivo. No último teste (marcado com o cronômetro do meu relógio)  o MSX foi capaz de entregar o resultado em 7,3 segundos. Mas tem ainda como ganhar algum tempo.
### Testes.
No momento estou fazendo com o arquivo *teste.txt*, que está aí em cima. Mas o teste definitivo será feito com a minha imagem de cartão SD, que contém no total 77.803 arquivos, espalhados em 4 partições.

### Todo.
Ah, tem muitas coisas ainda a serem mexidas. Segue a lista:

#### No script updatedbmsx.sh:
- - ~~Ele tem que garantir que os arquivos que não começam com uma letra, sejam jogados em um arquivo, tipo 0.txt, por exemplo.~~ 
- - ~~O script deverá também criar a pasta na partição correspondente ao drive A do cartão/pendrive a ser usado no MSX, e acrescentar o SET LOCATEDB=a:\UTILS\LOCATE\DB no AUTOEXEC.BAT.~~ Essa funcionalidade, a propósito, está feita mas precisa de testes.

#### No utilitário locate:
- - ~~Ele também tem que ser capaz de fazer a busca por arquivos que comecem com algum caracter que não é uma letra, e buscar no arquivo correspondente.~~
- - ~~Usar rotinas para impressão mais rápida na tela. O write/writeln do TP3 usa a BDOS, então imprime na tela, mas é lento. Usando rotinas que estão disponíveis nas bibliotecas dos irmãos Lammassaari, eu obtive um ganho de desempenho de 15 a 20% na saída.~~
- - Usar as rotinas disponibilizadas pelo [PopolonY2K](https://sourceforge.net/projects/oldskooltech/) para facilitar a abertura de arquivos em diretórios que não são os seus, já que o blockread tem problemas com isto.
- - Quero que ele leia a variável de ambiente, setada no MSX-DOS 2 para colocar o caminho para o banco de dados. A variável de ambiente será a LOCALEDB, e a entrada será, a princípio, a:\UTILS\LOCATE\DB.
- - Parâmetro riscado lá em cima - será possível fazer com que ele execute o comando cd para já colocar o prompt no diretório onde aquele arquivo está.

#### Extras:
- - Um script para fazer a mesma coisa no Windows. **Não, eu não sei Powershell, e nem uso Windows**, a não ser quando quero que entre um ar na minha casa. :-D Logo, vou precisar da ajuda de alguém. 

#### Futuro:
Estas melhorias eu pretendo que estejam disponíveis quando a versão inicial ficar pronta. Agora, as seguintes podem demorar:
 - Uso de dois ou mais parâmetros simultaneamente.
 - Busca em nomes incompletos.
 - Busca em diretórios.

# Notas de versão.
(c) 2020 Brazilian MSX Crew. Alguns direitos reservados, já que esse programa vai pela GPL mesmo... Mas aceito sugestões, correções, melhorias... São sempre bem-vindas. Mas críticas destrutivas, tipo "*esse código tá uma bosta, faz em ASM de Z80 que é melhor*" serão remetidas para /dev/null. Ou, dependendo do meu estado de espírito, ouvirão um **vai a m*** bem sonoro.

