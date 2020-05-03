#!/bin/sh
DIRETORIO_ORIGINAL="/home/ricardo/Downloads/MSX/SD_CF_cartao"
DIRETORIO=$(echo $DIRETORIO_ORIGINAL | sed 's/\//\\\//g')
ARQUIVO="teste.txt"
TEMPORARIO=$(mktemp)
find $DIRETORIO_ORIGINAL/1_raiz/ -type f > $TEMPORARIO
for linha in $(cat $TEMPORARIO); do
	NOMEARQUIVO=$(basename $linha)
	AUXILIAR=$(dirname $linha)
	CAMINHO=$(echo $AUXILIAR  | sed "s/1_raiz\///" | sed "s/$DIRETORIO/a:/" | tr "\/" "\\" 2> /dev/null)
	echo $NOMEARQUIVO','$CAMINHO',' >> $ARQUIVO
done
cat $ARQUIVO | sort > $TEMPORARIO
cat $TEMPORARIO > $ARQUIVO