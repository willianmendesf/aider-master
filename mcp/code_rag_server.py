# /dados/aider/mcp/code_rag_server.py
import os
import sys
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("CodeRAG")

# Caminho base para seus índices
RAG_ROOT = os.path.expanduser("/dados/aider/rag/db")

@mcp.tool()
def search_project_memory(project_name: str, query: str) -> str:
    """
    Busca na memória indexada de um projeto específico.
    Use isso para encontrar onde funções ou lógicas estão implementadas.
    """
    index_file = os.path.join(RAG_ROOT, project_name, "index.txt")
    
    if not os.path.exists(index_file):
        return f"Projeto '{project_name}' ainda não foi indexado. Rode o script de indexação."

    # Leitura simples do índice (pode ser melhorado com vetores depois)
    with open(index_file, 'r') as f:
        content = f.read()
    
    # Busca textual simples (fallback até implementarmos vetores)
    # Em uma versão V2, aqui entraria a busca por similaridade de cosseno
    lines = content.split('\n')
    results = []
    for line in lines:
        if query.lower() in line.lower():
            results.append(line)
            
    if not results:
        return f"Nada encontrado sobre '{query}' no projeto '{project_name}'."
    
    return "\n".join(results[:10]) # Retorna top 10

@mcp.tool()
def get_project_map(project_name: str) -> str:
    """
    Retorna o mapa de arquitetura do projeto (arquivo summary.md).
    Isso dá contexto global sem ler todo o código.
    """
    map_file = os.path.join(RAG_ROOT, project_name, "summary.md")
    if os.path.exists(map_file):
        with open(map_file, 'r') as f:
            return f.read()
    return "Mapa do projeto não encontrado."

if __name__ == "__main__":
    mcp.run()   
