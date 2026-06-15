# /dados/aider/mcp/servers/codebase_rag.py
import os
import sys
import chromadb
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("CodebaseRAG")

@mcp.tool()
def search_code(query: str, project: str) -> str:
    """
    Busca trechos de código relevantes no projeto especificado.
    Use isso antes de pedir para editar arquivos desconhecidos.
    """
    db_path = os.path.expanduser(f"/dados/aider/rag/db/{project}")
    if not os.path.exists(db_path):
        return f"Erro: Projeto '{project}' não indexado."

    client = chromadb.PersistentClient(path=db_path)
    collection = client.get_collection("codebase")
    
    results = collection.query(query_texts=[query], n_results=3)
    
    if not results['documents']:
        return "Nenhum código relevante encontrado."
    
    # Formata a resposta para o Aider entender
    response = []
    for doc, meta in zip(results['documents'][0], results['metadatas'][0]):
        response.append(f"Arquivo: {meta['path']}\n```{doc[:500]}...\n```")
    
    return "\n\n".join(response)

if __name__ == "__main__":
    mcp.run()   
