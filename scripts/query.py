#!/usr/bin/env python3
import sys
import json
import os
import re

KNOWLEDGE_DIR = ".ai/knowledge"
ENTITIES_FILE = os.path.join(KNOWLEDGE_DIR, "entities.json")
GRAPH_FILE = os.path.join(KNOWLEDGE_DIR, "graph.json")

def load_json(path):
    if not os.path.exists(path):
        return []
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def _is_partial_index(entities) -> bool:
    """Retorna True se o índice contém apenas o RepomixBundle (conhecimento parcial)."""
    if not entities:
        return False
    types = {e.get("type") for e in entities}
    return types == {"bundle"} or (len(entities) == 1 and entities[0].get("id") == "RepomixBundle")

def _get_bundle_file(entities) -> str:
    """Retorna o caminho do bundle Repomix se existir."""
    for e in entities:
        if e.get("type") == "bundle" and e.get("file"):
            return e.get("file")
    return ""

def _grep_in_bundle(bundle_file: str, term: str):
    """Busca textual simples no bundle. Retorna lista de (line_num, line_content)."""
    if not os.path.exists(bundle_file):
        return []
    results = []
    try:
        with open(bundle_file, "r", encoding="utf-8", errors="ignore") as f:
            for i, line in enumerate(f, 1):
                if term.lower() in line.lower():
                    line_content = line.rstrip()
                    if len(line_content) > 120:
                        idx = line_content.lower().find(term.lower())
                        start = max(0, idx - 40)
                        end = min(len(line_content), idx + len(term) + 40)
                        prefix = "..." if start > 0 else ""
                        suffix = "..." if end < len(line_content) else ""
                        line_content = prefix + line_content[start:end].strip() + suffix
                    results.append((i, line_content))
                    if len(results) >= 30:
                        break
    except Exception:
        pass
    return results

def cmd_where(args):
    if not args:
        print("❌ Uso: where <Termo/Classe>")
        sys.exit(1)

    term = args[0].lower()
    entities = load_json(ENTITIES_FILE)

    if not entities:
        print("⚠️ Índice vazio. Rode 'bootstrap' primeiro.")
        sys.exit(1)

    if _is_partial_index(entities):
        bundle_file = _get_bundle_file(entities)
        print(f"⚠️  AVISO: Índice parcial (apenas bundle Repomix). Executando busca textual fallback em: {bundle_file}")
        print(f"   Resultados NÃO têm precisão de AST — são correspondências textuais simples.\n")
        hits = _grep_in_bundle(bundle_file, args[0])
        if not hits:
            print(f"⚠️ Nenhuma ocorrência textual de '{args[0]}' encontrada no bundle.")
        else:
            print(f"📍 Ocorrências textuais de '{args[0]}' no bundle (fallback):")
            for line_num, line_content in hits:
                print(f"   Linha {line_num}: {line_content}")
        return

    found = False
    for e in entities:
        if term in e.get("name", "").lower() or term in e.get("id", "").lower():
            found = True
            print(f"📍 {e.get('name')} ({e.get('type')})")
            print(f"   Arquivo: {e.get('file')}")
            print(f"   Linha: {e.get('line')}\n")

    if not found:
        print(f"⚠️ Nenhuma entidade encontrada para '{term}'.")

def cmd_discover(args):
    if not args:
        print("❌ Uso: discover <Termo/Classe>")
        sys.exit(1)

    term = args[0].lower()
    entities = load_json(ENTITIES_FILE)

    if not entities:
        print("⚠️ Índice vazio. Rode 'bootstrap' primeiro.")
        sys.exit(1)

    if _is_partial_index(entities):
        bundle_file = _get_bundle_file(entities)
        print(f"⚠️  AVISO: Índice parcial (apenas bundle Repomix). Executando busca textual fallback em: {bundle_file}")
        print(f"   Resultados NÃO têm precisão de AST — são correspondências textuais simples.\n")
        hits = _grep_in_bundle(bundle_file, args[0])
        if not hits:
            print(f"⚠️ Nenhuma ocorrência textual de '{args[0]}' encontrada no bundle.")
        else:
            print(f"🔍 Ocorrências textuais de '{args[0]}' no bundle (fallback):")
            for line_num, line_content in hits:
                print(f"   Linha {line_num}: {line_content}")
        return

    found = False
    for e in entities:
        if term in e.get("name", "").lower() or term in e.get("id", "").lower():
            found = True
            print(f"🔍 Encontrado: {e.get('name')}")
            print(f"   Tipo: {e.get('type')}")
            print(f"   Arquivo: {e.get('file')}:{e.get('line')}")
            print(f"   Confiança: {e.get('confidence')}% (Fonte: {e.get('source')})\n")

    if not found:
        print(f"⚠️ Nenhuma entidade encontrada para '{term}'.")

def cmd_impact(args):
    if not args:
        print("❌ Uso: impact <Classe>")
        sys.exit(1)

    target_input = args[0].lower()
    entities = load_json(ENTITIES_FILE)
    graph = load_json(GRAPH_FILE)

    if not entities or not graph:
        print("❌ ERRO\n\nNão existe grafo de dependências.\n\nExecute:\n\nbootstrap\n\npara construir entities.json e graph.json.\n\nImpact Analysis requer relacionamentos.\nBusca textual não produz análise confiável.\n")
        sys.exit(1)

    edges = graph.get("edges", [])
    if not edges:
        print("❌ ERRO\n\nNão existe grafo de dependências (arestas vazias).\n\nExecute:\n\nbootstrap\n\npara construir entities.json e graph.json.\n\nImpact Analysis requer relacionamentos.\nBusca textual não produz análise confiável.\n")
        sys.exit(1)

    target_id = None
    target_ent = None
    for e in entities:
        if target_input in e.get("id", "").lower() or target_input in e.get("name", "").lower():
            target_id = e.get("id")
            target_ent = e
            break

    if not target_id:
        print(f"⚠️ Nenhuma entidade encontrada para '{args[0]}'.")
        sys.exit(1)

    ent_by_id = {e.get("id"): e for e in entities}

    dependencies = set()
    for edge in edges:
        if edge.get("from_node") == target_id:
            dependencies.add(edge.get("to_node"))

    direct_dependents = set()
    for edge in edges:
        if edge.get("to_node") == target_id:
            direct_dependents.add(edge.get("from_node"))

    visited = set(direct_dependents)
    queue = list(direct_dependents)
    while queue:
        curr = queue.pop(0)
        for edge in edges:
            if edge.get("to_node") == curr:
                from_n = edge.get("from_node")
                if from_n not in visited:
                    visited.add(from_n)
                    queue.append(from_n)
    
    indirect_dependents = visited - direct_dependents
    all_affected = visited
    
    endpoints_afetados = []
    telas_afetadas = []
    models_afetados = []
    arquivos_afetados = set()

    for dep in all_affected:
        ent = ent_by_id.get(dep)
        if ent:
            t = ent.get("type", "").lower()
            name = ent.get("name", dep)
            if t == "endpoint": endpoints_afetados.append(name)
            elif t == "component": telas_afetadas.append(name)
            elif t in ("model", "interface"): models_afetados.append(name)
            
            if ent.get("file"):
                arquivos_afetados.add(ent.get("file"))
    
    if target_ent and target_ent.get("file"):
        arquivos_afetados.add(target_ent.get("file"))

    num_dependents = len(all_affected)
    score = "BAIXO"
    if endpoints_afetados or num_dependents > 10:
        score = "CRÍTICO"
    elif num_dependents >= 6:
        score = "ALTO"
    elif num_dependents >= 2:
        score = "MÉDIO"
    else:
        score = "BAIXO"

    print("=======================================")
    print(" 💥 IMPACT REPORT")
    print("=======================================\n")
    print(f"Alvo:\n  {target_ent.get('name') if target_ent else target_id}\n")
    
    if target_ent:
        print(f"Tipo:\n  {target_ent.get('type').capitalize()}\n")
        print(f"Arquivo:\n  {target_ent.get('file')}\n")

    if dependencies:
        print("Dependências Diretas (Usa):")
        for d in sorted(dependencies):
            print(f"  - {d}")
        print("")

    if direct_dependents:
        print("Consumidores (Usado por):")
        for d in sorted(direct_dependents):
            print(f"  - {d}")
        print("")

    if endpoints_afetados:
        print("Endpoints Relacionados:")
        for ep in sorted(endpoints_afetados):
            print(f"  - {ep}")
        print("")
        
    if models_afetados:
        print("Models / Interfaces Utilizadas:")
        for m in sorted(models_afetados):
            print(f"  - {m}")
        print("")

    print("Raio de Quebra:\n")
    if num_dependents == 0:
        print(f"  SE ALTERAR '{target_id}':\n    Afeta apenas ele mesmo (Componente/Serviço Folha).")
    else:
        print(f"  SE ALTERAR '{target_id}':\n    Pode quebrar {len(direct_dependents)} consumidores diretos e {len(indirect_dependents)} indiretos.")
        if telas_afetadas:
            print(f"    Telas Afetadas: {', '.join(telas_afetadas[:3])}" + ("..." if len(telas_afetadas) > 3 else ""))

    print(f"\nImpact Score:\n  {score}\n")

def cmd_feature(args):
    if not args:
        print("❌ Uso: feature <Nome>")
        sys.exit(1)

    # feature builds context and invokes AIDER, but the python script just gathers data
    # In bash we will pipe this data to aider.
    target = args[0].lower()
    entities = load_json(ENTITIES_FILE)

    if _is_partial_index(entities):
        bundle_file = _get_bundle_file(entities)
        print(f"⚠️  AVISO: Índice parcial. Feature map baseado em busca textual (não estrutural).\n")
        hits = _grep_in_bundle(bundle_file, args[0])
        if hits:
            print(f"# Contexto Textual da Feature: {args[0]} (fallback)\n")
            print(f"## Ocorrências no bundle Repomix\n")
            for line_num, line_content in hits:
                print(f"- Linha {line_num}: `{line_content}`")
        else:
            print(f"⚠️ Nenhuma entidade associada à feature '{target}'.")
        return

    feature_entities = []
    for e in entities:
        features = [f.lower() for f in e.get("feature", [])]
        if any(target in f for f in features) or target in e.get("name", "").lower():
            feature_entities.append(e)

    if not feature_entities:
        print(f"⚠️ Nenhuma entidade associada à feature '{target}'.")
        sys.exit(0)

    print(f"# Contexto da Feature: {args[0]}\n")
    for e in feature_entities:
        print(f"## {e.get('name')} ({e.get('type')})")
        print(f"- Arquivo: {e.get('file')}:{e.get('line')}")
        print(f"- Source: {e.get('source')} (Confiança: {e.get('confidence')}%)\n")

def main():
    if len(sys.argv) < 2:
        print("❌ Comando ausente. Use where, discover, impact, feature.")
        sys.exit(1)

    cmd = sys.argv[1]
    args = sys.argv[2:]

    if cmd == "where":
        cmd_where(args)
    elif cmd == "discover":
        cmd_discover(args)
    elif cmd == "impact":
        cmd_impact(args)
    elif cmd == "feature":
        cmd_feature(args)
    else:
        print(f"❌ Comando desconhecido: {cmd}")

if __name__ == "__main__":
    main()
