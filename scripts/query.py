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
                    results.append((i, line.rstrip()))
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

    target = args[0].lower()
    entities = load_json(ENTITIES_FILE)

    if _is_partial_index(entities):
        bundle_file = _get_bundle_file(entities)
        print(f"⚠️  AVISO: Índice parcial. Análise de impacto não disponível sem grafo estrutural.")
        print(f"   Executando busca textual de referências a '{args[0]}' no bundle como fallback:\n")
        hits = _grep_in_bundle(bundle_file, args[0])
        if hits:
            print(f"💥 Referências textuais a '{args[0]}' (possíveis dependências):")
            for line_num, line_content in hits:
                print(f"   Linha {line_num}: {line_content}")
        else:
            print(f"✅ Nenhuma referência textual a '{args[0]}' encontrada no bundle.")
        return

    graph = load_json(GRAPH_FILE)
    if not graph:
        print("⚠️ graph.json não encontrado. Rode o bootstrap primeiro.")
        sys.exit(1)

    edges = graph.get("edges", [])

    if not edges:
        print("⚠️  AVISO: Grafo de dependências está vazio no índice atual.")
        print(f"   Executando busca textual de referências a '{args[0]}' nos arquivos originais:\n")
        # Try to find references in the repomix bundle if it exists, otherwise warn
        bundle_file = _get_bundle_file(entities)
        if bundle_file:
            hits = _grep_in_bundle(bundle_file, args[0])
            if hits:
                print(f"💥 Referências textuais a '{args[0]}' (possíveis dependências):")
                for line_num, line_content in hits:
                    print(f"   Linha {line_num}: {line_content}")
            else:
                print(f"✅ Nenhuma referência textual a '{args[0]}' encontrada no bundle.")
        else:
             print("❌ Nenhum bundle disponível para busca textual.")
        return

    affected = set()
    for edge in edges:
        if target in edge.get("to_node", "").lower():
            affected.add(edge.get("from_node"))

    if not affected:
        print(f"✅ Nenhuma dependência direta encontrada que quebre se alterar '{args[0]}'.")
    else:
        print(f"💥 O que quebra se alterar '{args[0]}':")
        for a in affected:
            print(f"   - {a}")

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
