#!/usr/bin/env python3
import os
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAG_ROOT = os.path.join(SCRIPT_DIR, "db")

def search(query, proj):
    index_file = os.path.join(RAG_ROOT, proj, "index.txt")
    if not os.path.exists(index_file):
        print(f"O projeto '{proj}' ainda não foi indexado no RAG. Rode: brain-index <caminho> {proj}")
        return
    
    with open(index_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        
    lines = content.split('\n')
    results = [line for line in lines if query.lower() in line.lower()]
    
    if not results:
        # Se não encontrou no mapa de símbolos, faz um fallback para busca full-text no repositório local
        import subprocess
        print(f"⚠️ '{query}' não encontrado no índice de símbolos. Buscando no texto completo do projeto '{proj}'...")
        try:
            # Transforma "como usar o brain-index" em uma busca inteligente "como|usar|brain|index"
            import re
            words = [w for w in re.split(r'\W+', query) if len(w) > 3]
            
            if not words:
                words = [query]
                
            regex_pattern = "|".join(words)
            grep_cmd = ["grep", "-rn", "-i", "-E", regex_pattern, "."]
            # Ignora pastas pesadas
            grep_cmd.extend(["--exclude-dir=node_modules", "--exclude-dir=venv", "--exclude-dir=.git", "--exclude-dir=.aider", "--exclude=bundle-output.txt"])
            
            output = subprocess.check_output(grep_cmd, text=True, stderr=subprocess.DEVNULL)
            lines = output.strip().split('\n')
            if lines and lines[0]:
                print(f"### Resultados full-text na memória do projeto '{proj}':\n" + "\n".join(lines[:30]))
                return
        except subprocess.CalledProcessError:
            pass # grep retorna erro se não achar nada
            
        print(f"Nada encontrado sobre '{query}' na memória do projeto '{proj}'.")
        return
        
    print(f"### Resultados na memória do projeto '{proj}':\n" + "\n".join(results[:30]))

def show_map(proj):
    map_file = os.path.join(RAG_ROOT, proj, "file_list.txt")
    if os.path.exists(map_file):
        with open(map_file, 'r', encoding='utf-8', errors='ignore') as f:
            print(f"### Estrutura de Arquivos de '{proj}':\n" + f.read())
    else:
        print(f"Mapa da estrutura do projeto '{proj}' não encontrado em {map_file}.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python rag_cli.py search <query> [project_name]")
        print("     python rag_cli.py map [project_name]")
        sys.exit(1)
        
    action = sys.argv[1]
    
    # Descobre o projeto procurando a raiz do git
    proj = None
    current = os.getcwd()
    while current and current != "/" and current != os.path.dirname(current):
        if os.path.isdir(os.path.join(current, ".git")):
            proj = os.path.basename(current)
            break
        current = os.path.dirname(current)
    if not proj:
        proj = os.path.basename(os.getcwd())
    
    if action == "search" and len(sys.argv) > 2:
        query = sys.argv[2]
        if len(sys.argv) > 3:
            proj = sys.argv[3]
        search(query, proj)
    elif action == "map":
        if len(sys.argv) > 2:
            proj = sys.argv[2]
        show_map(proj)
    else:
        print("Comando inválido ou argumentos insuficientes.")
