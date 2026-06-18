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

    matches = []
    for e in entities:
        if term in e.get("name", "").lower() or term in e.get("id", "").lower():
            matches.append(e)

    if not matches:
        print(f"⚠️ Nenhuma entidade encontrada para '{term}'.")
        return

    if len(matches) == 1:
        e = matches[0]
        print("📍 ENCONTRADO\n")
        print(f"Nome:\n  {e.get('name')}")
        print(f"Tipo:\n  {e.get('type').capitalize()}")
        print(f"Arquivo:\n  {e.get('file')}")
        print(f"Linha:\n  {e.get('line')}")
        print(f"Fonte:\n  {e.get('source')} ({e.get('confidence')}%)")
    else:
        print("📍 MÚLTIPLOS RESULTADOS\n")
        for idx, e in enumerate(matches, 1):
            print(f"[{idx}] {e.get('name')}")
            print(f"    Tipo: {e.get('type').capitalize()}")
            print(f"    Arquivo:\n    {e.get('file')}\n")
        print(f"Total:\n  {len(matches)} resultados")

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

    is_tree = "--tree" in args
    if is_tree:
        # Remove a flag para não quebrar o filtro de nome
        args.remove("--tree")
        if not args:
            print("❌ Uso: discover <Termo> [--tree]")
            sys.exit(1)
    
    term = args[0].lower()
    matches = [e for e in entities if term in e.get("id", "").lower() or term in e.get("name", "").lower()]
    if not matches:
        print(f"⚠️ Nenhuma entidade encontrada para '{term}'.")
        return

    exact_matches = [e for e in matches if term == e.get("name", "").lower()]
    e = exact_matches[0] if exact_matches else matches[0]

    graph = load_json(GRAPH_FILE)
    edges = graph.get("edges", [])
    
    dependencies = set()
    consumers = set()
    for edge in edges:
        if edge.get("from_node") == e.get("id"):
            dependencies.add(edge.get("to_node"))
        if edge.get("to_node") == e.get("id"):
            consumers.add(edge.get("from_node"))
            
    ent_by_id = {ent.get("id"): ent for ent in entities}
    dep_services = []
    dep_components = []
    dep_models = []
    dep_utils = []
    
    for d in dependencies:
        d_ent = ent_by_id.get(d)
        if not d_ent: continue
        t = d_ent.get("type", "").lower()
        name = d_ent.get("name", d)
        if t == "service": dep_services.append(name)
        elif t in ("component", "directive"): dep_components.append(name)
        elif t in ("model", "interface", "class"): dep_models.append(name)
        else: dep_utils.append(name)
        
    num_deps = len(dependencies)
    num_cons = len(consumers)
    num_models = len(dep_models)
    
    # Avaliação de Saúde Arquitetural
    risco = "BAIXO"
    if num_deps <= 5:
        saude = "BAIXO ACOPLAMENTO"
        saude_msg = "Componente atua com responsabilidade única e coesa."
    elif num_deps <= 10:
        saude = "MÉDIO ACOPLAMENTO"
        saude_msg = "Acoplamento dentro da média esperada."
        risco = "MÉDIO"
    elif num_deps <= 15:
        saude = "ALTO ACOPLAMENTO"
        saude_msg = "O componente concentra múltiplas responsabilidades (UI, integração, regras)."
        risco = "ALTO"
    else:
        saude = "ACOPLAMENTO CRÍTICO"
        saude_msg = "O componente concentra responsabilidades de UI, integração, regras de negócio e manipulação de dados em um único ponto."
        risco = "CRÍTICO"

    # Inferência de Feature via Caminho
    file_path = e.get('file', '')
    parts = file_path.replace("\\", "/").split("/")
    feature_str = "(Nenhuma mapeada)"
    if len(parts) > 1:
        parent_dir = parts[-2]
        if parent_dir in ("model", "models", "components", "services", "utils", "shared", "core", "interfaces", "pages", "logged"):
            if len(parts) > 2:
                parent_dir = parts[-3]
                if parent_dir in ("pages", "logged"):
                    if len(parts) > 3: parent_dir = parts[-4]
        feature_str = parent_dir.capitalize()

    if is_tree:
        print(f"{feature_str}")
        print(f"└── {e.get('name')}")
        all_deps = sorted(dep_services + dep_components + dep_models + dep_utils)
        for i, d in enumerate(all_deps):
            is_last = (i == len(all_deps) - 1)
            prefix = "    └── " if is_last else "    ├── "
            print(f"{prefix}{d}")
        return

    print("=======================================")
    print(" 🔎 DISCOVERY REPORT")
    print("=======================================\n")
    print(f"Nome:\n  {e.get('name')}\n")
    print(f"Feature Inferida:\n  {feature_str}\n")
    print(f"Tipo:\n  {e.get('type').capitalize()}\n")
    print(f"Arquivo:\n  {e.get('file')}\n")
    print(f"Origem:\n  {e.get('source')} ({e.get('confidence')}%)\n")
    
    if dep_services or dep_components:
        print("Utiliza (Usa):")
        for d in sorted(dep_services + dep_components):
            print(f"  - {d}")
        print("")
        
    if dep_models:
        print("Models:")
        for m in sorted(dep_models):
            print(f"  - {m}")
        print("")
        
    print("Saúde Arquitetural:\n")
    print(f"  Dependências Totais:\n    {num_deps}\n")
    print(f"  Services:\n    {len(dep_services)}")
    print(f"  Components:\n    {len(dep_components)}")
    print(f"  Models:\n    {len(dep_models)}")
    print(f"  Utils:\n    {len(dep_utils)}\n")
    print(f"  Avaliação:\n    {saude}\n")
    print(f"  Motivo:\n    {saude_msg}\n")
    print(f"  Risco:\n    {risco}\n")

    print("Relacionamentos Gerais:")
    print(f"  {num_models} models associados")
    print(f"  {num_cons} consumidores detectados\n")

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

    # Dependências (Usa)
    dependencies = set()
    for edge in edges:
        if edge.get("from_node") == target_id:
            dependencies.add(edge.get("to_node"))

    # Consumidores (Usado por)
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
    
    # Classificar Dependências
    dep_services = []
    dep_components = []
    dep_models = []
    dep_utils = []
    dep_endpoints = []

    for d in dependencies:
        e = ent_by_id.get(d)
        if not e:
            continue
        t = e.get("type", "").lower()
        name = e.get("name", d)
        if t == "service": dep_services.append(name)
        elif t in ("component", "directive"): dep_components.append(name)
        elif t in ("model", "interface", "class"): dep_models.append(name)
        elif t == "endpoint": dep_endpoints.append(name)
        else: dep_utils.append(name)

    # Classificar Consumidores
    cons_services = []
    cons_components = []
    cons_routes_utils = []
    endpoints_afetados = []
    
    for c in visited:
        if c == target_id:
            continue
        
        e = ent_by_id.get(c)
        if not e: continue
        t = e.get("type", "").lower()
        name = e.get("name", c)
        
        # Filtro de sanidade: model não deveria ser consumidor, geralmente é falso positivo
        if t in ("model", "interface", "class"):
            continue
            
        if t == "service": cons_services.append(name)
        elif t == "component": cons_components.append(name)
        elif t == "endpoint": endpoints_afetados.append(name)
        else: cons_routes_utils.append(name)

    num_dependents = len(visited)
    score = "BAIXO"
    justificativas = []

    if endpoints_afetados:
        score = "CRÍTICO"
        justificativas.append(f"Atinge diretamente {len(endpoints_afetados)} endpoint(s).")
    if num_dependents > 10:
        score = "CRÍTICO"
        justificativas.append(f"Alto número de dependentes na cadeia ({num_dependents}).")
    elif num_dependents >= 6:
        if score == "BAIXO": score = "ALTO"
        justificativas.append(f"Impacta {num_dependents} consumidores (6 ou mais).")
    elif num_dependents >= 1:
        if score == "BAIXO": score = "MÉDIO"
        justificativas.append(f"{len(direct_dependents)} consumidor(es) direto(s) e {len(indirect_dependents)} indireto(s).")
    
    if target_ent and target_ent.get("type", "").lower() == "model":
        justificativas.append("Alterações em Models/Interfaces costumam gerar efeitos cascata em tipagens.")
        if score in ("BAIXO", "MÉDIO"): score = "ALTO"

    if not justificativas:
        justificativas.append("Componente folha ou isolado. Nenhum consumidor principal identificado.")

    print("=======================================")
    print(" 💥 IMPACT REPORT")
    print("=======================================\n")
    print(f"Alvo:\n  {target_ent.get('name') if target_ent else target_id}\n")
    
    if target_ent:
        print(f"Tipo:\n  {target_ent.get('type').capitalize()}\n")
        print(f"Arquivo:\n  {target_ent.get('file')}\n")

    if dependencies:
        print("Dependências (Usa):\n")
        if dep_services:
            print("  Services:")
            for s in sorted(dep_services): print(f"    - {s}")
        if dep_components:
            print("  Components:")
            for c in sorted(dep_components): print(f"    - {c}")
        if dep_models:
            print("  Models:")
            for m in sorted(dep_models): print(f"    - {m}")
        if dep_endpoints:
            print("  Endpoints:")
            for ep in sorted(dep_endpoints): print(f"    - {ep}")
        if dep_utils:
            print("  Utilities/Outros:")
            for u in sorted(dep_utils): print(f"    - {u}")
        print("")

    consumidores_reais = cons_components + cons_services + cons_routes_utils
    if consumidores_reais:
        print("Consumidores (Usado por):")
        for c in sorted(consumidores_reais):
            print(f"  - {c}")
        print("")

    if endpoints_afetados:
        print("Endpoints Afetados:")
        for ep in sorted(endpoints_afetados):
            print(f"  - {ep}")
        print("")

    print(f"Impact Score:\n  {score}\n")
    print("Justificativa:")
    for j in justificativas:
        print(f"  - {j}")
    print("")

def cmd_feature(args):
    if not args:
        print("❌ Uso: feature <Nome>")
        sys.exit(1)

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

    # Identificar todas as entidades principais da feature via path heurístico ou nome
    feature_entities = []
    for e in entities:
        file_path = e.get('file', '')
        parts = file_path.replace("\\", "/").split("/")
        feature_str = ""
        if len(parts) > 1:
            parent_dir = parts[-2]
            if parent_dir in ("model", "models", "components", "services", "utils", "shared", "core", "interfaces", "pages", "logged"):
                if len(parts) > 2:
                    parent_dir = parts[-3]
                    if parent_dir in ("pages", "logged"):
                        if len(parts) > 3: parent_dir = parts[-4]
            feature_str = parent_dir.lower()
        
        if target in feature_str or target in e.get("name", "").lower():
            feature_entities.append(e)

    if not feature_entities:
        print(f"⚠️ Nenhuma entidade associada à feature '{target}'.")
        sys.exit(0)

    # Coletar dependências para o Fluxo
    graph = load_json(GRAPH_FILE)
    edges = graph.get("edges", [])
    ent_by_id = {e.get("id"): e for e in entities}
    
    telas = []
    services = []
    models = []
    arquivos = set()
    feature_ids = set()
    
    for e in feature_entities:
        t = e.get("type", "").lower()
        feature_ids.add(e.get("id"))
        if t == "component": telas.append(e)
        elif t == "service": services.append(e)
        elif t in ("model", "interface", "class"): models.append(e)
        
        if e.get("file"): arquivos.add(e.get("file"))
            
    reused_components = {}
    external_services = {}
    tela_deps = {}
    
    for tela in telas:
        tela_id = tela.get("id")
        deps = set()
        for edge in edges:
            if edge.get("from_node") == tela_id:
                deps.add(edge.get("to_node"))
        tela_deps[tela_id] = deps
        
        for d in deps:
            d_ent = ent_by_id.get(d)
            if not d_ent: continue
            
            dt = d_ent.get("type", "").lower()
            if d not in feature_ids:
                if dt in ("component", "directive"):
                    reused_components[d] = d_ent
                elif dt == "service":
                    external_services[d] = d_ent
                elif dt in ("model", "interface", "class"):
                    models.append(d_ent)
                    feature_ids.add(d)
                    if d_ent.get("file"): arquivos.add(d_ent.get("file"))

    # Ocultar infra/utils do fluxo principal (variáveis, constantes, helpers)
    infra_utils = []
    
    print(f"FEATURE: {args[0].capitalize()}\n")
    
    if telas:
        print("TELAS (Ponto de Entrada)")
        for t in sorted(telas, key=lambda x: x.get("name")):
            print(f"- {t.get('name')}\n  {t.get('file')}")
        print("")
        
    all_services = services + list(external_services.values())
    if all_services:
        print("SERVICES (Regras de Negócio / Integração)")
        for s in sorted(all_services, key=lambda x: x.get("name")):
            print(f"- {s.get('name')}")
        print("")
        
    if models:
        print("MODELS (Domínio / Contratos)")
        for m in sorted(models, key=lambda x: x.get("name")):
            print(f"- {m.get('name')}")
        print("")
        
    if reused_components:
        print("COMPONENTES REUTILIZADOS (UI Compartilhada)")
        for c in sorted(reused_components.values(), key=lambda x: x.get("name")):
            print(f"- {c.get('name')}")
        print("")
        
    print("FLUXO PRINCIPAL (Arquitetura)")
    for tela in sorted(telas, key=lambda x: x.get("name")):
        print(f"[TELA] {tela.get('name')}")
        
        tdeps = tela_deps.get(tela.get("id"), set())
        
        # Categorizar para o fluxo
        f_services = [ent_by_id[d].get('name') for d in tdeps if d in ent_by_id and ent_by_id[d].get('type') == 'service']
        f_models = [ent_by_id[d].get('name') for d in tdeps if d in ent_by_id and ent_by_id[d].get('type') in ('model', 'interface', 'class')]
        f_ui = [ent_by_id[d].get('name') for d in tdeps if d in ent_by_id and ent_by_id[d].get('type') in ('component', 'directive') and d != tela.get('id')]
        
        if f_services:
            print(" │\n ├── [INTEGRA/CHAMA]")
            for s in sorted(f_services):
                print(f" │     └── {s}")
                
        if f_models:
            print(" │\n ├── [MANIPULA DADOS]")
            for m in sorted(f_models):
                print(f" │     └── {m}")
                
        if f_ui:
            print(" │\n └── [RENDERIZA COM]")
            for u in sorted(f_ui):
                print(f"       └── {u}")
        print("")
    
    print("ARQUIVOS RELEVANTES (Caminho Completo)")
    for i, f in enumerate(sorted(arquivos), 1):
        print(f"{f}")
        
    print(f"\nTOTAL DE CONTEXTO:\n{len(arquivos)} arquivos\n")

    # Gerar arquivo TXT para automação do Aider
    try:
        import os
        os.makedirs(".ai/cache", exist_ok=True)
        with open(".ai/cache/feature_files.txt", "w", encoding="utf-8") as f:
            for arq in sorted(arquivos):
                f.write(arq + "\n")
    except Exception as e:
        pass

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
