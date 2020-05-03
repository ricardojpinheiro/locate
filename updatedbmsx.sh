#!/bin/sh
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

if [ '$#' -ne 1 ]; then
	echo "$0 versão 0.001."
	echo "Sintaxe: $0 <caminho do diretorio a ser indexado>"
	echo "Este script cria a listagem inicial dos arquivos e diretorios"
	echo "para serem usados pelo locate do MSX. Logo, O parâmetro que você"
	echo "deve passar é o caminho para o diretório inicial. Nesse diretório,"
	echo "deveremos ter diretórios, onde cada uma será uma partição do cartão"
	echo "SD. O script gera a lista de diretórios, faz a listagem, monta os"
	echo "arquivos e executa o programa em Pascal que vai gerar os arquivos"
	echo "que o locate do MSX vai acessar".
	exit 1
fi

TEMPORARIO=$(mktemp)
ARQUIVO=$(mktemp)
DIRETORIO_ORIGINAL=$1
QUANTOS_DIRETORIOS=$(find $DIRETORIO_ORIGINAL -maxdepth 1 -type d | sed -n '2,$p' | wc -l)
DIRETORIO=$(echo $DIRETORIO_ORIGINAL | sed 's/\//\\\//g')
k=1
i=$((k+1))
while [ $k -le $QUANTOS_DIRETORIOS ]; do
	DIRETORIOPARTICAO=$(basename $(find $DIRETORIO_ORIGINAL -maxdepth 1 -type d | sort | sed -n ""$i"p"))
	j=$((i+63))	
	LETRADRIVE=$(chr $j)
	echo "Drive "$LETRADRIVE "Diretorio particao: "$DIRETORIOPARTICAO
	for linha in $(find $DIRETORIO_ORIGINAL/$DIRETORIOPARTICAO/ -type f); do
		NOMEARQUIVO=$(basename $linha)
		AUXILIAR=$(dirname $linha)
		CAMINHO=$(echo $AUXILIAR | sed "s/$DIRETORIOPARTICAO\///" | sed "s/$DIRETORIO/$LETRADRIVE:/" | tr "\/" "\\" 2> /dev/null)
		echo $NOMEARQUIVO','$CAMINHO',' >> $ARQUIVO
	done	
	i=$((i+1))
	k=$((k+1))
done 
cat $ARQUIVO | sort | uniq | tr '[[:lower:]]' '[[:upper:]]' > $TEMPORARIO
for letra in {A..Z}; do 
	echo $letra
	sed -n -e '/^'"${letra}"'/p' $TEMPORARIO > "${letra}.txt"
	./update06 linux ${letra}.txt 
done
