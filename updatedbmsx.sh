#!/usr/bin/env bash
#
# A funcao desse script e fazer a listagem inicial dos arquivos e diretorios.
# Logo, ele receberá um parâmetro, que é o caminho para o diretório inicial.
# Nesse diretório inicial, deveremos ter diretórios, onde cada uma será uma
# partição do cartão SD. O script vai fazer a lista de diretórios, fazer a 
# listagem e montar o arquivo que o programa em Pascal (update06, no momento)
# vai processar.
#
#DIRETORIO_ORIGINAL="/home/ricardo/Downloads/MSX/SD_CF_cartao"

chr() {
  [ "$1" -lt 256 ] || return 1
  printf "\\$(printf '%03o' "$1")"
}

if [ $# -ne 1 ]; then
	echo "$0 versão 0.1."
	echo "Sintaxe: $0 <caminho do diretorio a ser indexado>"
	echo "Este script cria a listagem inicial dos arquivos e diretorios"
	echo "para serem usados pelo locate do MSX. Logo, o parâmetro que você"
	echo "deve passar é o caminho para o diretório inicial. Nesse diretório,"
	echo "deveremos ter diretórios, onde cada uma será uma partição do cartão"
	echo "SD. O script gera a lista de diretórios, faz a listagem, monta os"
	echo "arquivos e executa o programa em Pascal que vai gerar os arquivos"
	echo "que o locate do MSX vai acessar".
	exit 1
fi

TEMPORARIO=$(mktemp)
TEMP2=$(mktemp)
ARQUIVO=$(mktemp)
UPDATE="./update.linux"
CP=$(which cp)
DIRETORIO_ORIGINAL=$1
QUANTOS_DIRETORIOS=$(find $DIRETORIO_ORIGINAL -maxdepth 1 -type d | sed -n '2,$p' | wc -l)
DIRETORIO=$(echo $DIRETORIO_ORIGINAL | sed 's/\//\\\//g')
k=1
i=$((k+1))
#
# Monta toda a listagem, já trocando os caminhos padrao Unix por padrao DOS.
#
while [ $k -le $QUANTOS_DIRETORIOS ]; do
	DIRETORIOPARTICAO=$(basename $(find $DIRETORIO_ORIGINAL -maxdepth 1 -type d | sort | sed -n ""$i"p"))
	j=$((i+63))	
	LETRADRIVE=$(chr $j)
	echo "Drive "$LETRADRIVE "Diretorio particao: "$DIRETORIOPARTICAO
	if [ $LETRADRIVE == 'A' ]
	then
		BASELOCATE=$DIRETORIOPARTICAO
	fi
	for linha in $(find $DIRETORIO_ORIGINAL/$DIRETORIOPARTICAO/ -type f); do
		NOMEARQUIVO=$(basename $linha)
		AUXILIAR=$(dirname $linha)
		CAMINHO=$(echo $AUXILIAR | sed "s/$DIRETORIOPARTICAO\///" | sed "s/$DIRETORIO/$LETRADRIVE:/" | tr "\/" "\\" 2> /dev/null)
		echo $NOMEARQUIVO','$CAMINHO',' >> $ARQUIVO
	done	
	i=$((i+1))
	k=$((k+1))
done 
#
# Gera as listas dos arquivos, e executa o update para cada arquivo.
#
cat $ARQUIVO | sort | uniq | tr '[[:lower:]]' '[[:upper:]]' > $TEMPORARIO
for letra in {A..Z}; do 
	echo $letra
	sed -n -e '/^'"${letra}"'/p' $TEMPORARIO > "${letra}.txt"
	$UPDATE linux ${letra}.txt 
done
#
# Gera a lista de arquivos que não se enquadram nas opcoes anteriores, e coloca
# tudo isso no arquivo 0.txt.
#
grep -v "^[A-Z]" $TEMPORARIO > "0.txt"
$UPDATE linux 0.txt
#
#
# A ser testado depois... O script cria as pastas no diretorio correspondente
# ao drive A e salvara la o banco de dados, alem de setar a variavel de ambiente 
# dentro do AUTOEXEC.BAT.
#
#LOCATEDB=$DIRETORIO_ORIGINAL"/"$BASELOCATE"/UTILS/LOCATE/DB/ "
#mkdir -p $LOCATEDB
#$CP *.dat *.hsh $LOCATEDB
#cat $DIRETORIO_ORIGINAL"/"$BASELOCATE"/AUTOEXEC.BAT" | sed -e "\$aset locatedb=a:\\\utils\\\locate\\\db" > $TEMP2
#cat $TEMP2 $DIRETORIO_ORIGINAL"/"$BASELOCATE"/AUTOEXEC.BAT"
#
exit 0
#
#MSX r0x a lot.
