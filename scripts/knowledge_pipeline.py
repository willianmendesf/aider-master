#!/usr/bin/env python3
import os
import sys
import json
import yaml
import subprocess
from dataclasses import dataclass, field, asdict
from typing import List, Dict, Optional

AIDER_GLOBAL_DIR = "/dados/aider"
CATALOG_DIR = os.path.join(AIDER_GLOBAL_DIR, "tooling/catalog")
KNOWLEDGE_DIR = ".ai/knowledge"
CACHE_DIR = ".ai/cache"

@dataclass
class Entity:
    id: str
    name: str
    type: str
    file: str
    line: int
    source: str
    confidence: int
    uses: List[str] = field(default_factory=list)
    used_by: List[str] = field(default_factory=list)
    tags: List[str] = field(default_factory=list)

@dataclass
class Edge:
    from_node: str
    to_node: str
    type: str

@dataclass
class Graph:
    nodes: List[Dict] = field(default_factory=list)
    edges: List[Dict] = field(default_factory=list)

class ToolCatalog:
    def __init__(self):
        self.tools = []
        self._load_catalog()

    def _load_catalog(self):
        if not os.path.exists(CATALOG_DIR):
            return
        for file in os.listdir(CATALOG_DIR):
            if file.endswith((".yml", ".yaml")):
                path = os.path.join(CATALOG_DIR, file)
                with open(path, "r") as f:
                    try:
                        self.tools.append(yaml.safe_load(f))
                    except Exception:
                        pass

    def detect_tools(self) -> List[Dict]:
        matched = []
        for tool in self.tools:
            detect_patterns = tool.get("detect", [])
            for pattern in detect_patterns:
                if pattern == "*" or os.path.exists(pattern):
                    matched.append(tool)
                    break
        # Sort by priority descending
        matched.sort(key=lambda x: x.get("priority", 0), reverse=True)
        return matched

class CompodocProvider:
    def normalize(self, outputs: List[str], tool: Dict) -> List[Entity]:
        import re
        entities_dict = {}
        raw_items = []

        for output in outputs:
            if not os.path.exists(output):
                continue
            with open(output, "r", encoding="utf-8") as f:
                try:
                    data = json.load(f)
                except Exception:
                    continue
            
            for comp in data.get("components", []):
                raw_items.append((comp, "component"))
            for srv in data.get("injectables", []):
                raw_items.append((srv, "service"))
            for mod in data.get("modules", []):
                raw_items.append((mod, "module"))
        
        for item, etype in raw_items:
            name = item.get("name", "")
            if not name:
                continue
            
            ent = Entity(
                id=name,
                name=name,
                type=etype,
                file=item.get("file", ""),
                line=item.get("line", 0) or 0,
                source=tool.get("name", "Compodoc"),
                confidence=tool.get("confidence", 100)
            )
            entities_dict[name] = {"ent": ent, "code": item.get("sourceCode", "")}

        names = list(entities_dict.keys())
        for name, obj in entities_dict.items():
            ent = obj["ent"]
            code = obj["code"]
            if not code:
                continue
            
            for other in names:
                if other == name:
                    continue
                # Busca exata de palavra para evitar falso positivo (ex: 'App' dando match em 'Appointment')
                if re.search(r'\b' + re.escape(other) + r'\b', code):
                    if other not in ent.uses:
                        ent.uses.append(other)
                    other_ent = entities_dict[other]["ent"]
                    if name not in other_ent.used_by:
                        other_ent.used_by.append(name)

        return [obj["ent"] for obj in entities_dict.values()]

class OpenAPIProvider:
    def normalize(self, outputs: List[str], tool: Dict) -> List[Entity]:
        entities = []
        found_any = False
        for output in outputs:
            if not os.path.exists(output):
                continue
            with open(output, "r", encoding="utf-8") as f:
                try:
                    data = json.load(f)
                    found_any = True
                except Exception:
                    continue
            
        if not found_any:
            print(f"  [WARNING] Nenhuma especificação OpenAPI encontrada ({', '.join(outputs)}). O conhecimento extraído será mínimo. Recomendamos gerar o OpenAPI na build do projeto.")
            return entities

        for output in outputs:
            if not os.path.exists(output):
                continue
            with open(output, "r", encoding="utf-8") as f:
                try:
                    data = json.load(f)
                except Exception:
                    continue
            
            paths = data.get("paths", {})
            for path, methods in paths.items():
                for method, details in methods.items():
                    op_id = details.get("operationId", f"{method.upper()} {path}")
                    entities.append(Entity(
                        id=op_id,
                        name=op_id,
                        type="endpoint",
                        file=output,
                        line=0,
                        source=tool.get("name", "OpenAPI"),
                        confidence=tool.get("confidence", 100),
                        tags=[method.upper(), path]
                    ))
            
            schemas = data.get("components", {}).get("schemas", {})
            for schema_name, details in schemas.items():
                entities.append(Entity(
                    id=schema_name,
                    name=schema_name,
                    type="model",
                    file=output,
                    line=0,
                    source=tool.get("name", "OpenAPI"),
                    confidence=tool.get("confidence", 100)
                ))
        return entities

class TypeDocProvider:
    def normalize(self, outputs: List[str], tool: Dict) -> List[Entity]:
        entities = []
        for output in outputs:
            if not os.path.exists(output):
                continue
            with open(output, "r", encoding="utf-8") as f:
                try:
                    data = json.load(f)
                except Exception:
                    continue
            
            children = data.get("children", [])
            for child in children:
                kind_string = child.get("kindString", "").lower()
                ent_type = "model"
                if "interface" in kind_string:
                    ent_type = "interface"
                elif "class" in kind_string:
                    if "Service" in child.get("name", ""):
                        ent_type = "service"
                    else:
                        ent_type = "component"
                
                source_file = ""
                line = 0
                sources = child.get("sources", [])
                if sources:
                    source_file = sources[0].get("fileName", "")
                    line = sources[0].get("line", 0)

                entities.append(Entity(
                    id=child.get("name", ""),
                    name=child.get("name", ""),
                    type=ent_type,
                    file=source_file,
                    line=line,
                    source=tool.get("name", "TypeDoc"),
                    confidence=tool.get("confidence", 90)
                ))
        return entities

class RepomixProvider:
    def normalize(self, outputs: List[str], tool: Dict) -> List[Entity]:
        # Repomix just bundles text, without an LLM we can't extract deep structure easily,
        # but we can list files as a fallback.
        entities = []
        for output in outputs:
            if not os.path.exists(output):
                continue
            # Simple regex/file listing logic could go here
            entities.append(Entity(
                id="RepomixBundle",
                name="Repomix Bundle",
                type="bundle",
                file=output,
                line=0,
                source=tool.get("name", "Repomix"),
                confidence=tool.get("confidence", 70)
            ))
        return entities

def get_provider(tool_name: str):
    name = tool_name.lower()
    if "compodoc" in name:
        return CompodocProvider()
    elif "openapi" in name or "springdoc" in name:
        return OpenAPIProvider()
    elif "typedoc" in name:
        return TypeDocProvider()
    else:
        return RepomixProvider()

def run_tool(tool: Dict) -> bool:
    generate_cmds = tool.get("generate", [])
    success = True
    for cmd in generate_cmds:
        print(f"🔧 Executando: {cmd}")
        try:
            # Added 300 second timeout
            result = subprocess.run(cmd, shell=True, capture_output=True, timeout=300)
            if result.returncode != 0:
                print(f"  ❌ Comando falhou (Código {result.returncode}): {result.stderr.decode('utf-8', errors='ignore')}")
                success = False
        except subprocess.TimeoutExpired:
            print(f"  ❌ Erro: Tempo limite excedido (timeout) ao executar: {cmd}")
            success = False
        except Exception as e:
            print(f"  ❌ Erro ao executar ferramenta: {e}")
            success = False
    return success

def build_graph(entities: List[Entity]) -> Graph:
    g = Graph()
    # Create nodes
    for e in entities:
        g.nodes.append({"id": e.id, "type": e.type})
    
    # Create edges
    for e in entities:
        for u in e.uses:
            g.edges.append(asdict(Edge(from_node=e.id, to_node=u, type="uses")))
        for u_by in e.used_by:
            g.edges.append(asdict(Edge(from_node=u_by, to_node=e.id, type="uses")))
            
    return g

def save_knowledge(entities: List[Entity], graph: Graph):
    os.makedirs(KNOWLEDGE_DIR, exist_ok=True)
    
    entities_dict = [asdict(e) for e in entities]
    with open(os.path.join(KNOWLEDGE_DIR, "entities.json"), "w", encoding="utf-8") as f:
        json.dump(entities_dict, f, indent=2, ensure_ascii=False)
        
    with open(os.path.join(KNOWLEDGE_DIR, "graph.json"), "w", encoding="utf-8") as f:
        json.dump(asdict(graph), f, indent=2, ensure_ascii=False)

def print_doctor(matched_tools: List[Dict]):
    print("🚀 Laudo Bootstrap Doctor")
    print("---------------------------------")
    print("Ferramentas compatíveis detectadas na stack:")
    for t in matched_tools:
        print(f"- {t.get('name')} (Prioridade: {t.get('priority', 0)}, Confiança: {t.get('confidence', 0)}%)")
        if 'install' in t:
            print("  Recomendação de instalação:")
            for cmd in t['install']:
                print(f"    {cmd}")
    print("---------------------------------")
    print("O Bootstrap priorizará a ferramenta de maior confiança instalada para indexação.")

def main():
    catalog = ToolCatalog()
    matched = catalog.detect_tools()
    
    if len(sys.argv) > 1 and sys.argv[1] == "--doctor":
        print_doctor(matched)
        return

    if not matched:
        print("⚠️ Nenhuma ferramenta mapeada para esta stack. Usando Fallback.")
        return

    # Filter to the best tools that can actually run or generate outputs
    print(f"🔍 Tools detectadas: {[t.get('name') for t in matched]}")
    
    all_entities = []
    
    # Ensure cache dir exists
    os.makedirs(CACHE_DIR, exist_ok=True)
    
    for tool in matched:
        print(f"⚡ Acionando Provider: {tool.get('name')} (Confiança {tool.get('confidence')}%)")
        tool_success = True
        
        # Generate metadata
        if "generate" in tool:
            tool_success = run_tool(tool)
        else:
            print("  (Apenas lendo artefatos existentes)")
            
        if not tool_success:
            print(f"  ⚠️ Provider {tool.get('name')} falhou. Tentando próximo provider como fallback...")
            continue
        
        outputs = tool.get("outputs", [])
        provider = get_provider(tool.get("name", ""))
        
        try:
            entities = provider.normalize(outputs, tool)
            if entities:
                print(f"  ✔ {len(entities)} entidades extraídas com sucesso.")
                all_entities.extend(entities)
        except Exception as e:
            print(f"  ❌ Erro ao processar {tool.get('name')}: {e}")
            
    # Resolve Cross-References (Basic implementation)
    # E.g. finding names inside file strings to link edges, although mature providers 
    # would parse this natively from JSON ASTs.
    
    # Save to Index and Graph
    graph = build_graph(all_entities)
    save_knowledge(all_entities, graph)
    
    # --- Relatório final de qualidade do índice ---
    bundle_only = all_entities and all(e.type == "bundle" for e in all_entities)
    if not all_entities:
        print(f"❌ Falha no Bootstrap: Nenhuma entidade gerada. O índice está vazio.")
        print(f"   Verifique se as ferramentas (Compodoc, Springdoc/OpenAPI) estão instaladas e configuradas.")
    elif bundle_only:
        print(f"⚠️  Bootstrap PARCIAL: só o bundle Repomix foi indexado ({len(all_entities)} entidade).")
        print(f"   Isso acontece quando nenhuma ferramenta estrutural (Compodoc / OpenAPI) gerou artefatos.")
        print(f"   Impacto: 'where', 'discover', 'feature' e 'impact' operarão em modo textual (sem precisão de AST).")
        print(f"   Para Java/Spring: adicione springdoc-openapi ao pom.xml e gere swagger-ui.html antes do bootstrap.")
        print(f"   Para Angular: verifique que 'npx @compodoc/compodoc -p tsconfig.json ...' executa sem erro.")
    else:
        print(f"✅ Bootstrap concluído. {len(all_entities)} entidades indexadas em .ai/knowledge/entities.json e graph.json.")

if __name__ == "__main__":
    main()
