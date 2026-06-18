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
        print("❌ Uso: discover <Termo/Classe> [--tree] [--deep]")
        sys.exit(1)

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
    is_deep = "--deep" in args
    if is_tree:
        args.remove("--tree")
    if is_deep:
        args.remove("--deep")
        
    if not args:
        print("❌ Uso: discover <Termo> [--tree] [--deep]")
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
    
    if is_deep and file_path and os.path.exists(file_path):
        print("=======================================")
        print(" 🔍 CONTEÚDO DO ARQUIVO (--deep)")
        print("=======================================\n")
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                content = f.read()
                print(content)
        except Exception as ex:
            print(f"⚠️ Não foi possível ler o arquivo: {ex}")

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

    # Nova Seção: Recomendação Direta e Risco
    print("RECOMENDAÇÃO:\n")
    if score == "BAIXO":
        print("  ✅ Pode alterar com segurança.")
        print("\n  Motivo:\n    Nenhuma outra tela ou serviço central depende diretamente.")
        print("\n  Risco:\n    Apenas regressão local (contido no próprio arquivo).")
        print("\n  Necessário testar:")
        if target_ent and target_ent.get("type", "").lower() == "component":
            print(f"    - Renderização da tela {target_ent.get('name')}")
        else:
            print(f"    - Lógica isolada de {target_ent.get('name') if target_ent else target_id}")
    elif score == "MÉDIO":
        print("  ⚠️ Alteração requer atenção moderada.")
        print("\n  Motivo:\n    Existem consumidores diretos na cadeia de injeção.")
        print("\n  Risco:\n    Pode quebrar contratos internos ou o comportamento de telas próximas.")
        print("\n  Necessário testar:")
        print(f"    - {target_ent.get('name') if target_ent else target_id}")
        for c in cons_components[:2]:
            print(f"    - Tela: {c}")
    else:
        print("  🚨 NÃO ALTERE DIRETAMENTE SEM PLANEJAMENTO.")
        print(f"\n  Motivo:\n    Alto número de dependentes ({num_dependents} consumidores) ou endpoints críticos afetados.")
        print("\n  Risco:\n    Efeito cascata severo. Uma mudança de contrato aqui quebra múltiplos fluxos.")
        print("\n  Necessário testar:")
        print("    - Suíte de regressão completa")
        for ep in endpoints_afetados[:2]:
            print(f"    - Fluxo do endpoint {ep}")
        for c in cons_components[:3]:
            print(f"    - Integração da tela {c}")
    print("")

def _get_tsconfig_paths():
    paths = {}
    for tsconfig_file in ["tsconfig.json", "tsconfig.app.json", "tsconfig.base.json"]:
        if os.path.exists(tsconfig_file):
            try:
                with open(tsconfig_file, 'r', encoding='utf-8') as f:
                    content = f.read()
                content = re.sub(r'//.*', '', content)
                content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
                data = json.loads(content)
                if 'compilerOptions' in data and 'paths' in data['compilerOptions']:
                    for alias, targets in data['compilerOptions']['paths'].items():
                        if targets:
                            paths[alias] = targets[0]
            except Exception:
                pass
    return paths

def _resolve_import_path(imp, base_dir, tsconfig_paths):
    if imp.startswith('.'):
        resolved = os.path.normpath(os.path.join(base_dir, imp))
    else:
        resolved = None
        for alias, target in tsconfig_paths.items():
            alias_prefix = alias.replace('/*', '/')
            target_prefix = target.replace('/*', '/')
            if imp.startswith(alias_prefix):
                resolved = os.path.normpath(imp.replace(alias_prefix, target_prefix, 1))
                break
        if not resolved:
            if imp.startswith('@app/'):
                resolved = os.path.normpath(os.path.join('src/app', imp[5:]))
            elif imp.startswith('src/'):
                resolved = os.path.normpath(imp)
            else:
                return None
                
    if os.path.exists(resolved + '.ts'):
        return resolved + '.ts'
    elif os.path.exists(os.path.join(resolved, 'index.ts')):
        return os.path.join(resolved, 'index.ts')
    return None

def _classify_import(filepath):
    path_lower = filepath.lower()
    
    if any(k in path_lower for k in ('guard', 'interceptor', 'auth', 'security')):
        return "INFRA / SEGURANÇA"
    elif any(k in path_lower for k in ('store', 'state', 'signal', 'reducer', 'action', 'selector', 'effect')):
        return "ESTADO"
    elif any(k in path_lower for k in ('route', 'routing')):
        return "ROTAS"
    elif any(k in path_lower for k in ('service', 'api')):
        return "SERVICES USADOS"
    elif any(k in path_lower for k in ('model', 'interface', 'dto', 'type', 'entity')):
        return "MODELS / INTERFACES"
    elif any(k in path_lower for k in ('validator', 'utils', 'helper', 'pipe', 'util')):
        return "VALIDATORS / UTILS"
    elif any(k in path_lower for k in ('component', 'shared', 'module')):
        return "COMPONENTES COMPARTILHADOS"
    else:
        return "OUTROS IMPORTS"

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

    candidates = []
    for e in entities:
        if e.get("type", "").lower() in ("component", "directive"):
            if target in e.get("name", "").lower() or target in e.get("file", "").lower():
                if e.get("file"):
                    candidates.append(e.get("file"))
                
    main_file = None
    if candidates:
        for c in candidates:
            if c and c.endswith(f"{target}.component.ts"):
                main_file = c
                break
        if not main_file:
            main_file = candidates[0]
            
    if not main_file or not os.path.exists(main_file):
        print(f"⚠️ Não foi possível encontrar o arquivo principal da feature '{target}'.")
        sys.exit(0)

    base_dir = os.path.dirname(main_file)
    basename_no_ext = os.path.basename(main_file).replace('.component.ts', '').replace('.ts', '')
    html_file1 = os.path.join(base_dir, f"{basename_no_ext}.component.html")
    html_file2 = os.path.join(base_dir, f"{basename_no_ext}.html")
    scss_file1 = os.path.join(base_dir, f"{basename_no_ext}.component.scss")
    scss_file2 = os.path.join(base_dir, f"{basename_no_ext}.scss")

    edit_files = [main_file]
    if os.path.exists(html_file1): edit_files.append(html_file1)
    elif os.path.exists(html_file2): edit_files.append(html_file2)
    
    if os.path.exists(scss_file1): edit_files.append(scss_file1)
    elif os.path.exists(scss_file2): edit_files.append(scss_file2)

    tsconfig_paths = _get_tsconfig_paths()
    imports_found = []
    
    with open(main_file, 'r', encoding='utf-8') as f:
        content = f.read()
    matches = re.findall(r"import\s+.*?from\s+['\"](.*?)['\"]", content)
    
    for match in matches:
        if not match.startswith('.') and not match.startswith('@') and not match.startswith('src/'):
            continue
        if match.startswith('@angular') or match.startswith('rxjs') or match.startswith('ngx-'):
            continue
            
        resolved = _resolve_import_path(match, base_dir, tsconfig_paths)
        if resolved and resolved not in imports_found:
            imports_found.append(resolved)

    classified = {
        "SERVICES USADOS": [],
        "MODELS / INTERFACES": [],
        "VALIDATORS / UTILS": [],
        "COMPONENTES COMPARTILHADOS": [],
        "INFRA / SEGURANÇA": [],
        "ESTADO": [],
        "ROTAS": [],
        "OUTROS IMPORTS": []
    }

    for imp in imports_found:
        cat = _classify_import(imp)
        classified[cat].append(imp)

    print(f"FEATURE: {target.upper()}\n")
    print("IMPORTS DETECTADOS")
    if imports_found:
        for imp in sorted(imports_found):
            print(f"- {imp}")
    else:
        print("- nenhum detectado")
    print()

    for cat in ["SERVICES USADOS", "MODELS / INTERFACES", "VALIDATORS / UTILS", "COMPONENTES COMPARTILHADOS", "INFRA / SEGURANÇA", "ESTADO", "ROTAS"]:
        print(f"{cat}")
        items = classified[cat]
        if items:
            for item in sorted(items):
                print(f"- {item}")
        else:
            print("- nenhum detectado")
        print()

    print("ARQUIVOS CANDIDATOS PARA EDITAR")
    for f in edit_files:
        print(f"[EDITAR] {f}")
    print()

    print("ARQUIVOS CANDIDATOS PARA REFERENCIA")
    for f in sorted(imports_found):
        print(f"[REFERENCIA] {f}")
    print()

    print(f"\nTOTAL DE CONTEXTO:\n{len(edit_files) + len(imports_found)} arquivos\n")

    try:
        os.makedirs(".ai/cache", exist_ok=True)
        with open(".ai/cache/feature_files.txt", "w", encoding="utf-8") as f:
            for arq in edit_files + imports_found:
                f.write(arq + "\n")
    except Exception:
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
