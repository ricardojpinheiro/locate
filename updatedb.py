#!/usr/bin/python

import os
import sys
import struct

def calcular_hash_djb2(string_data):
    """Algoritmo DJB2 de 32 bits modificado."""
    hash_value = 5381
    for char in string_data:
        hash_value = ((hash_value << 5) + hash_value) + ord(char)
        hash_value &= 0xFFFFFFFF
    return hash_value

def carregar_configuracoes(config_filepath):
    mapeamentos = []
    if not os.path.exists(config_filepath):
        print(f"Erro: Arquivo '{config_filepath}' nao encontrado.")
        sys.exit(1)
    with open(config_filepath, 'r', encoding='iso-8859-1') as f:
        linhas = [l.strip() for l in f if l.strip()]
    for linha in linhas[:8]:
        if ',' in linha:
            caminho, drive = linha.split(',', 1)
            mapeamentos.append((caminho.strip(), drive.strip().upper()))
    return mapeamentos

def determinar_sufixo_lote(filename):
    if not filename: 
        return 'NUM'
    inicial = filename[0].upper()
    if 'A' <= inicial <= 'Z':
        return inicial
    return 'NUM'

def empacotar_string_pascal_128(texto):
    """
    Transforma uma string Python em um bloco binario de 128 bytes do Turbo Pascal.
    [1 byte de tamanho] + [texto convertido] + [preenchimento com zeros ate 128 bytes]
    """
    texto_cortado = texto[:127]
    encoded_text = texto_cortado.encode('iso-8859-1', errors='replace')
    tamanho_real = len(encoded_text)
    
    padding_needed = 127 - tamanho_real
    corpo_preenchido = encoded_text + (b'\x00' * padding_needed)
    
    return struct.pack('<B127s', tamanho_real, corpo_preenchido)

def main():
    if len(sys.argv) < 2:
        print("updatedbmsx versão 0.1")
        print("Copyright (c) 2026 Brazilian MSX Crew")
        print("")
        print("Uso: updatedbmsx.py <arquivo de configurações>")
        print("")
        print("Descrição: Este script em Python criará os arquivos DAT que serão usados pelo locate")
        print("no MSX para realizar a busca. Ele também cria os arquivos TXT, que não serão usados,")
        print("podendo ser descartados pelo usuário.")
        print("")        
        print("Configuração: O <arquivo de configurações> deve seguir o seguinte formato:")
        print("<caminho completo até o diretório que será indexado>,<letra do drive correspondente>")
        print("Isto se repetirá para cada letra de drive.")
        sys.exit(1)
        
    arq_config = sys.argv[1]
    mapeamentos = carregar_configuracoes(arq_config)
    
    lista_consolidada = []
    
    for root_dir, drive in mapeamentos:
        if not os.path.isdir(root_dir): continue
        for dirpath, _, filenames in os.walk(root_dir):
            for filename in filenames:
                filename_upper = filename.upper()
                
                h = calcular_hash_djb2(filename_upper)
                
                clean_dir = dirpath.replace(root_dir, "").upper().lstrip("/")
                clean_dir = os.path.join(drive, clean_dir).replace("/", "\\")
                while "\\\\" in clean_dir:
                    clean_dir = clean_dir.replace("\\\\", "\\")
                
                # --- NOVA REGRA DE CORTE DE TAMANHOS ---
                # Corta o caminho/diretorio para garantir no maximo 80 caracteres
                clean_dir_cortado = clean_dir[:80]
                
                # Monta a string final. Como o hash tem no maximo 10 e o diretorio no maximo 80,
                # o nome do arquivo podera ter ate ~35 caracteres sem estourar o limite de 127 da string.
                linha_final = f"{h},{filename_upper},{clean_dir_cortado}"
                
                lista_consolidada.append((h, filename_upper, linha_final))
                
    lista_consolidada.sort(key=lambda x: x[0])
    
    grupos = {chr(i): [] for i in range(ord('A'), ord('Z') + 1)}
    grupos['NUM'] = []
    
    for h, filename, linha_final in lista_consolidada:
        chave = determinar_sufixo_lote(filename)
        grupos[chave].append(linha_final)
        
    print("\n--- Gravando Lotes com limite de 80 caracteres no caminho ---")
    for chave, registros in grupos.items():
        if not registros: continue
            
        nome_dat = f"{chave}.DAT"
        nome_txt = f"{chave}.TXT"
        
        with open(nome_dat, 'wb') as bin_f:
            for item in registros:
                bloco_binario = empacotar_string_pascal_128(item)
                bin_f.write(bloco_binario)
                
        with open(nome_txt, 'w', encoding='iso-8859-1', errors='replace', newline='\r\n') as txt_f:
            for item in registros:
                txt_f.write(f"{item}\n")
                
        print(f"-> Concluido: '{nome_dat}' e '{nome_txt}' gerados com {len(registros)} registros.")

if __name__ == "__main__":
    main()
