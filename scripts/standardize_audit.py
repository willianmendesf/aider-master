import os
import sys
import json
import yaml
import importlib.util
import argparse

def detect_stack(target_path, catalogs_dir):
    for catalog_file in os.listdir(catalogs_dir):
        if not catalog_file.endswith('.yml'):
            continue
        with open(os.path.join(catalogs_dir, catalog_file), 'r') as f:
            catalog = yaml.safe_load(f)
            
        detect_rules = catalog.get('detect', {})
        files_to_detect = detect_rules.get('files', [])
        exts_to_detect = detect_rules.get('extensions', [])
        
        # Check target
        if os.path.isfile(target_path):
            if any(target_path.endswith(ext) for ext in exts_to_detect):
                return catalog
        else:
            for root, dirs, files in os.walk(target_path):
                if any(f in files for f in files_to_detect):
                    return catalog
                for f in files:
                    if any(f.endswith(ext) for ext in exts_to_detect):
                        return catalog
    return None

def main():
    parser = argparse.ArgumentParser(description="Deterministic Standardize Audit")
    parser.add_argument("--target", required=True)
    parser.add_argument("--ref")
    parser.add_argument("--examples")
    parser.add_argument("--out-json", required=True)
    parser.add_argument("--out-md", required=True)
    args = parser.parse_args()

    aider_global = os.environ.get('AIDER_GLOBAL_DIR', '/dados/aider')
    catalogs_dir = os.path.join(aider_global, 'standardize', 'catalog')
    analyzers_dir = os.path.join(aider_global, 'standardize', 'analyzers')
    
    catalog = detect_stack(args.target, catalogs_dir)
    if not catalog:
        print("ERROR: Could not detect stack for target.", file=sys.stderr)
        sys.exit(1)
        
    analyzer_name = catalog['analyzer']
    analyzer_path = os.path.join(analyzers_dir, analyzer_name)
    
    if not os.path.exists(analyzer_path):
        print(f"ERROR: Analyzer {analyzer_name} not found.", file=sys.stderr)
        sys.exit(1)

    # Dynamically load the analyzer module
    spec = importlib.util.spec_from_file_location("analyzer_module", analyzer_path)
    analyzer_module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(analyzer_module)

    # Run analysis
    findings = analyzer_module.analyze(args.target, args.ref, args.examples)

    # Prepare JSON output
    report_json = {
        "stack": catalog['name'],
        "target": args.target,
        "ref": args.ref,
        "summary": {
            "files_analyzed": len(set(f['file'] for f in findings)),
            "issues": len(findings),
            "padronizar": len([f for f in findings if f['classification'] == 'PADRONIZAR']),
            "preservar": len([f for f in findings if f['classification'] == 'PRESERVAR'])
        },
        "findings": findings
    }

    # Ensure output dirs exist
    os.makedirs(os.path.dirname(args.out_json), exist_ok=True)

    with open(args.out_json, 'w', encoding='utf-8') as f:
        json.dump(report_json, f, indent=2, ensure_ascii=False)

    # Prepare MD output
    md_lines = []
    md_lines.append("# Standardize Audit\n")
    md_lines.append("## Resumo")
    md_lines.append(f"- Stack detectada: {catalog['name']}")
    md_lines.append(f"- Alvo: {args.target}")
    md_lines.append(f"- Referência: {args.ref or 'N/A'}")
    md_lines.append(f"- Issues totais: {len(findings)}\n")
    
    md_lines.append("## Achados\n")
    if not findings:
        md_lines.append("Nenhuma divergência estrutural detectada.")
    else:
        for f in findings:
            md_lines.append(f"### {f['id']}")
            md_lines.append(f" • Classificação: {f['classification']}")
            md_lines.append(f" • Severidade: {f['severity']}")
            md_lines.append(f" • Arquivo: {f['file']}")
            md_lines.append(f" • Evidência:\n\n```typescript\n{f['evidence']}\n```\n")
            md_lines.append(f" • Problema: {f['problem']}")
            md_lines.append(f" • Recomendação: {f['recommendation']}\n")

    with open(args.out_md, 'w', encoding='utf-8') as f:
        f.write('\n'.join(md_lines))

if __name__ == "__main__":
    main()
