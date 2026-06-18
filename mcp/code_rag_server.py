# /dados/aider/mcp/code_rag_server.py
import os
import json
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("CodeRAG")

KNOWLEDGE_DIR = ".ai/knowledge"
ENTITIES_FILE = os.path.join(KNOWLEDGE_DIR, "entities.json")

def load_json(path):
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        try:
            return json.load(f)
        except Exception:
            return []

def _is_partial_index(entities) -> bool:
    if not entities:
        return False
    types = {e.get("type") for e in entities}
    return types == {"bundle"} or (len(entities) == 1 and entities[0].get("id") == "RepomixBundle")

def _get_bundle_file(entities) -> str:
    for e in entities:
        if e.get("type") == "bundle" and e.get("file"):
            return e.get("file")
    return ""

def _grep_in_bundle(bundle_file: str, term: str):
    if not os.path.exists(bundle_file):
        return []
    results = []
    try:
        with open(bundle_file, "r", encoding="utf-8", errors="ignore") as f:
            for i, line in enumerate(f, 1):
                if term.lower() in line.lower():
                    results.append((i, line.rstrip()))
                    if len(results) >= 30:
                        break
    except Exception:
        pass
    return results

@mcp.tool()
def search_project_memory(query: str, project_name: str = "") -> str:
    """
    Busca na memória estruturada do projeto atual (via Aider OS bootstrap).
    Use para encontrar a localização de classes, funções, serviços ou regras extraídas.
    """
    entities = load_json(ENTITIES_FILE)

    if not entities:
        return "⚠️ Índice de conhecimento vazio. Rode o comando 'bootstrap' no terminal para indexar o projeto via Aider OS."

    term = query.lower()
    
    # Se só tivermos o bundle textual (sem parser ast rodado)
    if _is_partial_index(entities):
        bundle_file = _get_bundle_file(entities)
        hits = _grep_in_bundle(bundle_file, term)
        if not hits:
            return f"Nenhuma ocorrência de '{query}' encontrada no bundle textual."
        
        output = f"⚠️ Resultados via busca textual no bundle (fallback) para '{query}':\n"
        for line_num, line_content in hits:
            output += f"L{line_num}: {line_content}\n"
        return output

    # Busca exata e estruturada no AST gerado pelo Aider OS
    results = []
    for e in entities:
        if term in e.get("name", "").lower() or term in e.get("id", "").lower():
            results.append(f"📍 {e.get('name')} ({e.get('type')})\n   Arquivo: {e.get('file')}:{e.get('line')}")
            
    if not results:
        return f"Nada encontrado sobre '{query}' na memória estruturada do projeto."
    
    return f"### Resultados Estruturais para '{query}':\n" + "\n".join(results)

@mcp.tool()
def get_project_map(project_name: str = "") -> str:
    """
    Retorna a lista das principais entidades arquiteturais (classes, serviços, módulos) 
    do projeto indexado, para a IA entender o esqueleto global sem ler todos os arquivos.
    """
    entities = load_json(ENTITIES_FILE)

    if not entities:
        return "⚠️ Mapa vazio. Rode o comando 'bootstrap' no terminal."

    if _is_partial_index(entities):
        return "⚠️ Mapa estrutural indisponível (apenas fallback de texto). Rode 'bootstrap' usando Compodoc/OpenAPI para extrair a estrutura real."

    # Agrupar entidades por tipo para um overview elegante
    overview = {}
    for e in entities:
        t = e.get("type", "unknown")
        if t not in overview:
            overview[t] = []
        overview[t].append(f"{e.get('name')} -> {e.get('file')}")

    output = "### Mapa Estrutural do Projeto:\n"
    for t, items in overview.items():
        output += f"\n## {t.upper()}\n"
        output += "\n".join(f"- {i}" for i in items[:50]) # limitamos a 50 de cada tipo para não explodir
        if len(items) > 50:
            output += f"\n... (+ {len(items) - 50} itens)"
            
    return output

if __name__ == "__main__":
    mcp.run()