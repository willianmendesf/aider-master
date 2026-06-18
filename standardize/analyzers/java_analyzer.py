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
                if file.endswith('.java') and 'target' not in root:
                    files_to_analyze.append(os.path.join(root, file))

    issue_counter = 1

    for file_path in files_to_analyze:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')

        # Lines heuristic
        total_lines = len(lines)
        if total_lines > 400:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "java",
                "classification": "PADRONIZAR",
                "severity": "HIGH",
                "file": file_path,
                "evidence": f"File has {total_lines} lines",
                "problem": "Class is too large",
                "recommendation": "Split class responsibilities"
            })
            issue_counter += 1

        # Sysout heuristic
        sysout_usages = len(re.findall(r'System\.out\.print', content))
        if sysout_usages > 0:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "java",
                "classification": "PADRONIZAR",
                "severity": "HIGH",
                "file": file_path,
                "evidence": f"Found {sysout_usages} usages of System.out.println",
                "problem": "Using standard output instead of proper logging",
                "recommendation": "Replace with SLF4J or proper Logger"
            })
            issue_counter += 1

        # Field injection heuristic
        field_injections = len(re.findall(r'@Autowired\s+(?:private|protected|public)?\s+[\w<>]+\s+\w+;', content))
        if field_injections > 0:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "java",
                "classification": "PADRONIZAR",
                "severity": "MEDIUM",
                "file": file_path,
                "evidence": f"Found {field_injections} @Autowired field injections",
                "problem": "Field injection is not recommended",
                "recommendation": "Use constructor injection instead (e.g. @RequiredArgsConstructor)"
            })
            issue_counter += 1

        # Preserve endpoints
        endpoints = re.findall(r'@(?:Get|Post|Put|Delete|Patch)Mapping\([^)]*\)', content)
        if endpoints:
            findings.append({
                "id": f"STD-{issue_counter:03d}",
                "stack": "java",
                "classification": "PRESERVAR",
                "severity": "INFO",
                "file": file_path,
                "evidence": f"Declared endpoints: {', '.join(endpoints)}",
                "problem": "N/A",
                "recommendation": "Preserve API contract and paths"
            })
            issue_counter += 1

    return findings
