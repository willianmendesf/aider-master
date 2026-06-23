#!/usr/bin/env python3
import sys
import os
import re
import subprocess

def find_in_codebase(text):
    try:
        # Use git grep for fast searching
        res = subprocess.run(["git", "grep", "-q", "-I", "-F", text], capture_output=True)
        if res.returncode == 0:
            return True
    except Exception:
        pass
    
    # Fallback to os.walk
    for root, dirs, files in os.walk('.'):
        for d in ['.git', 'node_modules', 'dist', 'build', 'out', '.ai', '.aider', 'coverage']:
            if d in dirs:
                dirs.remove(d)
        for f in files:
            if f.endswith(('.ts', '.tsx', '.java', '.py', '.cs', '.js', '.jsx', '.go', '.rb', '.php')):
                filepath = os.path.join(root, f)
                try:
                    with open(filepath, 'r', encoding='utf-8', errors='ignore') as fh:
                        if text in fh.read():
                            return True
                except:
                    pass
    return False

def check_path_exists(path_str):
    # Clean formatting
    path_str = path_str.strip("`'\"* \t\n")
    if ']' in path_str and '(' in path_str:
        m = re.search(r'\]\((.*?)\)', path_str)
        if m:
            path_str = m.group(1)
            
    path_str = path_str.replace('file://', '')
    if os.path.exists(path_str):
        return True
        
    base = os.path.basename(path_str)
    try:
        # Check if any file matches the basename
        res = subprocess.run(["git", "ls-files", f"**/{base}"], capture_output=True, text=True)
        if res.stdout.strip():
            return True
    except:
        pass
    return False

def main():
    if len(sys.argv) < 2:
        print("Uso: python3 validator.py <arquivos.md...>")
        sys.exit(1)
        
    files = sys.argv[1:]
    
    # Regexes
    regex_paths = re.compile(r'\b(src/[\w/.-]+|app/[\w/.-]+|[\w/.-]+\.(?:ts|tsx|java|py|cs))\b')
    regex_endpoints = re.compile(r'\b(?:GET|POST|PUT|DELETE|PATCH)\s+/[A-Za-z0-9_/-]+\b')
    regex_classes = re.compile(r'\b[A-Za-z0-9_]+(?:Service|Component|Controller|Repository|Model|DTO|Interface)\b')
    
    blockers = []
    warnings = []
    
    for filepath in files:
        if not os.path.exists(filepath):
            continue
            
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        for line_num, line in enumerate(lines, 1):
            is_discovery = '[NEEDS DISCOVERY]' in line
            
            # Find items
            paths = regex_paths.findall(line)
            endpoints = regex_endpoints.findall(line)
            classes = regex_classes.findall(line)
            
            # Check Paths
            for p in paths:
                if not check_path_exists(p):
                    msg = f"Path '{p}' in {os.path.basename(filepath)}:{line_num}"
                    if is_discovery: warnings.append(msg)
                    else: blockers.append(msg)
                    
            # Check Endpoints
            for ep in endpoints:
                if not find_in_codebase(ep):
                    msg = f"Endpoint '{ep}' in {os.path.basename(filepath)}:{line_num}"
                    if is_discovery: warnings.append(msg)
                    else: blockers.append(msg)
                    
            # Check Classes
            for cls in classes:
                if not find_in_codebase(cls):
                    msg = f"Class '{cls}' in {os.path.basename(filepath)}:{line_num}"
                    if is_discovery: warnings.append(msg)
                    else: blockers.append(msg)

    # Deduplicate
    blockers = list(dict.fromkeys(blockers))
    warnings = list(dict.fromkeys(warnings))
    
    os.makedirs(".ai/cache", exist_ok=True)
    report_path = ".ai/cache/validation-report.md"
    
    with open(report_path, "w", encoding="utf-8") as rf:
        rf.write("# Validation Report\n\n")
        rf.write("## Blockers (Fatos citados sem evidência)\n")
        if blockers:
            for b in blockers:
                rf.write(f"- [BLOCKER] {b}\n")
        else:
            rf.write("Nenhum blocker encontrado.\n")
            
        rf.write("\n## Warnings (Hipóteses marcadas como descoberta)\n")
        if warnings:
            for w in warnings:
                rf.write(f"- [WARNING] {w}\n")
        else:
            rf.write("Nenhum warning encontrado.\n")
            
    print("\n=======================================")
    print(" 🛡️  VALIDATOR REPORT")
    print("=======================================")
    print(f"📄 Relatório gerado em: {report_path}")
    print(f"🛑 Blockers: {len(blockers)}")
    print(f"⚠️  Warnings: {len(warnings)}")
    
    if blockers:
        for b in blockers[:5]:
            print(f"  - {b}")
        if len(blockers) > 5:
            print(f"  - ... e mais {len(blockers)-5}")
        print("\n❌ VALIDAÇÃO FALHOU: Evidências faltando. Revise o plano ou use [NEEDS DISCOVERY].")
        sys.exit(1)
    else:
        print("\n✅ VALIDAÇÃO BEM SUCEDIDA: Todas as evidências (fatos) conferem.")
        sys.exit(0)

if __name__ == "__main__":
    main()
