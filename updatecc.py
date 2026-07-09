import os
import sys
import struct

def calcular_hash_djb2(string_data):
    """
    Algoritmo DJB2 de 32 bits.
    Extremamente rapido para computadores antigos e com indice de colisao proximo a zero.
    """
    hash_value = 5381
    for char in string_data:
        hash_value = ((hash_value << 5) + hash_value) + ord(char)
        hash_value &= 0xFFFFFFFF
    return hash_value

def carregar_configuracoes(config_filepath):
    mapeamentos = []
    if not os.path.exists(config_filepath):
        print(f"Erro: Arquivo de configuracao '{config_filepath}' nao encontrado.")
        sys.exit(1)
    with open(config_filepath, 'r', encoding='iso-8859-1') as f:
        linhas = [l.strip() for l in f if l.strip()]
    for linha in linhas[:8]:
        if ',' in linha:
            caminho, drive = linha.split(',', 1)
            mapeamentos.append((caminho.strip(), drive.strip().upper()))
    return mapeamentos

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
        print("Uso: python3 gerador_diretorios.py <config.txt>")
        sys.exit(1)
        
    arq_config = sys.argv[1]
    mapeamentos = carregar_configuracoes(arq_config)
    
    lista_diretorios = []
    
    print("Mapeando estruturas de diretorios...")
    for root_dir, drive in mapeamentos:
        if not os.path.isdir(root_dir):
            print(f"Aviso: O caminho '{root_dir}' nao existe ou nao eh acessivel. Ignorado.")
            continue
            
        for dirpath, _, _ in os.walk(root_dir):
            # Obtem o nome isolado do diretorio atual (ex: "PASCAL" ou "SISTEMA")
            nome_diretorio = os.path.basename(dirpath)
            
            # Se for a raiz do caminho configurado, tratamos para nao ficar em branco
            if not nome_diretorio:
                nome_diretorio = drive
                
            nome_dir_upper = nome_diretorio.upper()
            
            # Calcula o Hash DJB2 focado exclusivamente no nome do diretorio
            h = calcular_hash_djb2(nome_dir_upper)
            
            # Trata o caminho completo ate chegar a esse diretorio
            # Substitui a raiz (root_dir) pela letra de drive correspondente
            clean_path = dirpath.replace(root_dir, "").upper().lstrip("/")
            clean_path = os.path.join(drive, clean_path).replace("/", "\\")
            while "\\\\" in clean_path:
                clean_path = clean_path.replace("\\\\", "\\")
                
            # Limita o caminho a regra de 80 caracteres definida anteriormente, por seguranca
            clean_path_cortado = clean_path[:80]
            
            # Monta a string no formato solicitado: HASH,DIRETORIO,CAMINHO
            linha_final = f"{h},{nome_dir_upper},{clean_path_cortado}"
            
            # Armazena o hash (indice 0) para a ordenacao numerica crescente
            lista_diretorios.append((h, linha_final))
            
    if not lista_diretorios:
        print("Erro: Nenhum diretorio encontrado para processar.")
        sys.exit(1)
        
    # Ordena de forma crescente com base no valor numerico do HASH (indice 0)
    lista_diretorios.sort(key=lambda x: x[0])
    
    # Nomes dos arquivos consolidados unicos requisitados
    nome_dat = "DIRS.DAT"
    nome_txt = "DIRS.TXT"
    
    print(f"\n--- Gravando {nome_dat} (Binario Pascal) e {nome_txt} (Texto Depuracao) ---")
    
    # 1. GRAVA O ARQUIVO BINÁRIO (.DAT) FORMATADO PARA BLOCKREAD NO PASCAL
    with open(nome_dat, 'wb') as bin_f:
        for _, item in lista_diretorios:
            bloco_binario = empacotar_string_pascal_128(item)
            bin_f.write(bloco_binario)
            
    # 2. GRAVA O ARQUIVO TEXTO ESPELHO (.TXT) EM ISO 8859-1
    with open(nome_txt, 'w', encoding='iso-8859-1', errors='replace', newline='\r\n') as txt_f:
        for _, item in lista_diretorios:
            txt_f.write(f"{item}\n")
            
    print(f"Sucesso! Gerados {len(lista_diretorios)} diretorios mapeados.")
    print(f"-> '{nome_dat}' pronto para o Turbo Pascal 3.0.")
    print(f"-> '{nome_txt}' pronto para fins de depuracao.")

if __name__ == "__main__":
    main()