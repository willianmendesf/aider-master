# /dados/aider/mcp/code_rag_server.py
import os
import sys
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("CodeRAG")

# Caminho base para seus índices - compatível com Linux e Windows
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RAG_ROOT = os.path.join(os.path.dirname(SCRIPT_DIR), "rag", "db")

def _discover_project_name(project_name: str = None) -> str:
    """Se o Aider não passar o nome do projeto, descobrimos pela raiz do git ou diretório atual."""
    if project_name and project_name.strip():
        return project_name
    current = os.getcwd()
    while current and current != "/" and current != os.path.dirname(current):
        if os.path.isdir(os.path.join(current, ".git")):
            return os.path.basename(current)
        current = os.path.dirname(current)
    return os.path.basename(os.getcwd())

@mcp.tool()
def search_project_memory(query: str, project_name: str = "") -> str:
    """
    Busca na memória indexada do projeto. Use para encontrar onde funções, 
    regras, constantes ou lógicas de arquivos antigos/bundles estão implementadas.
    """
    proj = _discover_project_name(project_name)
    index_file = os.path.join(RAG_ROOT, proj, "index.txt")
    
    if not os.path.exists(index_file):
        return f"O projeto '{proj}' ainda não foi indexado no RAG. Rode: brain-index <caminho> {proj}"

    with open(index_file, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    lines = content.split('\n')
    results = []
    for line in lines:
        if query.lower() in line.lower():
            results.append(line)
            
    if not results:
        return f"Nada encontrado sobre '{query}' na memória do projeto '{proj}'."
    
    # Retorna as primeiras 30 linhas para dar um contexto melhor pro Aider
    return f"### Resultados na memória do projeto '{proj}':\n" + "\n".join(results[:30])

@mcp.tool()
def get_project_map(project_name: str = "") -> str:
    """
    Retorna a lista completa de caminhos de arquivos mapeados na estrutura do projeto.
    Útil para a IA entender o esqueleto global sem ler o código.
    """
    proj = _discover_project_name(project_name)
    map_file = os.path.join(RAG_ROOT, proj, "file_list.txt") # Ajustado de summary.md para file_list.txt
    
    if os.path.exists(map_file):
        with open(map_file, 'r', encoding='utf-8', errors='ignore') as f:
            return f"### Estrutura de Arquivos de '{proj}':\n" + f.read()
            
    return f"Mapa da estrutura do projeto '{proj}' não encontrado em {map_file}."

if __name__ == "__main__":
    mcp.run()