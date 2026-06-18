import os
import re

def analyze(target_path, ref_path=None, examples_path=None):
    findings = []
    
    files_to_analyze = []
    if os.path.isfile(target_path):
        files_to_analyze.append(target_path)
    else:
        for root, dirs, files in os.walk(target_path):
            for file in files:
                if file.endswith('.ts') and 'node_modules' not in root:
                    files_to_analyze.append(os.path.join(root, file))

    issue_counter = 1

    for file_path in files_to_analyze:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')

        # Heuristic 1: Lines
        total_lines = len(lines)
        if total_lines > 300:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "angular",
                "classification": "PADRONIZAR",
                "severity": "HIGH",
                "file": file_path,
                "evidence": f"File has {total_lines} lines",
                "problem": "Component or service is too large",
                "recommendation": "Split into smaller components or extract logic to services"
            })
            issue_counter += 1

        # Heuristic 2: Methods and sizes
        # Simplified regex for methods: typical pattern `methodName() {`
        # Ignores keywords like if, switch, for, while, etc.
        method_pattern = re.compile(
            r'^\s*(?:public |private |protected )?(?:get |set )?(?!(?:if|for|while|switch|catch|return|subscribe|pipe|map|filter)\b)([a-zA-Z_]\w*)\s*\([^)]*\)\s*(?::\s*[^{]+)?\s*\{', 
            re.MULTILINE
        )
        # Arrow function handlers
        arrow_pattern = re.compile(
            r'^\s*(?:public |private |protected )?(?:readonly\s+)?([a-zA-Z_]\w*)\s*=\s*(?:\([^)]*\)|[a-zA-Z_]\w*)\s*=>\s*\{?', 
            re.MULTILINE
        )
        
        methods = list(method_pattern.finditer(content)) + list(arrow_pattern.finditer(content))
        # Sort methods by their starting position in the file to keep the sequence logical for line counting
        methods.sort(key=lambda m: m.start())
        
        if len(methods) > 15:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "angular",
                "classification": "PADRONIZAR",
                "severity": "MEDIUM",
                "file": file_path,
                "evidence": f"Class contains {len(methods)} methods",
                "problem": "Too many methods, likely violating Single Responsibility Principle",
                "recommendation": "Refactor and extract responsibilities"
            })
            issue_counter += 1

        # Large methods heuristic (rough counting of lines between '{' and '}')
        # We'll just look at the raw distances between method declarations
        for i, match in enumerate(methods):
            start_pos = match.end()
            end_pos = methods[i+1].start() if i + 1 < len(methods) else len(content)
            method_body = content[start_pos:end_pos]
            method_lines = method_body.count('\n')
            if method_lines > 30:
                findings.append({
                    "id": f"STD-{issue_counter:03d}",
                    "stack": "angular",
                    "classification": "PADRONIZAR",
                    "severity": "MEDIUM",
                    "file": file_path,
                    "evidence": f"Method {match.group(1)} has approximately {method_lines} lines",
                    "problem": "Method is too long and complex",
                    "recommendation": "Break method into smaller, testable private methods"
                })
                issue_counter += 1

        # Heuristic 3: subscribe without takeUntilDestroyed
        subscribes = len(re.findall(r'\.subscribe\(', content))
        take_untils = len(re.findall(r'takeUntilDestroyed\(', content))
        if subscribes > 0 and take_untils < subscribes:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "angular",
                "classification": "PADRONIZAR",
                "severity": "HIGH",
                "file": file_path,
                "evidence": f"Found {subscribes} subscribes but only {take_untils} takeUntilDestroyed",
                "problem": "Potential memory leak from unscoped subscriptions",
                "recommendation": "Pipe takeUntilDestroyed() before subscribe()"
            })
            issue_counter += 1

        # Heuristic 4: usage of 'any'
        any_usages = len(re.findall(r':\s*any\b', content))
        if any_usages > 0:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "angular",
                "classification": "PADRONIZAR",
                "severity": "LOW",
                "file": file_path,
                "evidence": f"Found {any_usages} usages of type 'any'",
                "problem": "Loss of type safety",
                "recommendation": "Define explicit interfaces or types instead of any"
            })
            issue_counter += 1

        # Business vs Pattern: Identify injected clients to "PRESERVAR"
        injections = re.findall(r'inject\(([A-Za-z0-9_]+Client)\)', content)
        if injections:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "angular",
                "classification": "PRESERVAR",
                "severity": "INFO",
                "file": file_path,
                "evidence": f"Injected clients: {', '.join(injections)}",
                "problem": "N/A",
                "recommendation": "Preserve domain-specific API clients"
            })
            issue_counter += 1

    return findings
