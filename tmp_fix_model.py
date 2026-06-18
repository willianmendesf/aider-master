import re

file_path = '/dados/aider/aider_core.sh'
with open(file_path, 'r') as f:
    content = f.read()

content = re.sub(
    r'[ \t]*if \[ "\$1" == "--model" \] && \[ -n "\$2" \]; then\n[ \t]*modelo="\$2"\n[ \t]*shift 2\n[ \t]*elif \[ "\$\#" -gt 0 \] && \[\[ ! "\$1" == -\* \]\]; then\n[ \t]*modelo="\$1"\n[ \t]*shift\n[ \t]*fi',
    '    if [ "$1" == "--model" ] && [ -n "$2" ]; then\n        modelo="$2"\n        shift 2\n    fi',
    content
)

content = re.sub(
    r'[ \t]*if \[ "\$\#" -gt 0 \] && \[\[ ! "\$1" == -\* \]\]; then\n[ \t]*modelo="\$1"\n[ \t]*shift\n[ \t]*fi',
    '    if [ "$1" == "--model" ] && [ -n "$2" ]; then\n        modelo="$2"\n        shift 2\n    fi',
    content
)

plan_regex = r'''(plan\(\)\s*\{[\s\S]*?local modelo="default"[\s\S]*?while \[ "\$\#" -gt 0 \]; do\s*case "\$1" in)([\s\S]*?)(esac)'''
def replace_plan(m):
    body = m.group(2)
    body = re.sub(r'--model\)\s*modelo="\$2"\s*shift\s*;;', 
                  '--model)\n                if [ -n "$2" ] && [[ "$2" != --* ]]; then\n                    modelo="$2"\n                    shift\n                else\n                    echo "❌ ERRO: --model requer um valor."\n                    return 1\n                fi\n                ;;', body)
    body = re.sub(r'\*\)\s*modelo="\$1"\s*;;',
                  '*)\n                echo "❌ Argumento desconhecido no plan: $1"\n                echo "Use: --feature, --new-screen, --ref, --area, --doc, --open ou --model"\n                return 1\n                ;;', body)
    return m.group(1) + body + m.group(3)
content = re.sub(plan_regex, replace_plan, content)

std_regex = r'''(standardize\(\)\s*\{[\s\S]*?local modelo="default"[\s\S]*?while \[ "\$\#" -gt 0 \]; do\s*case "\$1" in)([\s\S]*?)(esac)'''
def replace_std(m):
    body = m.group(2)
    body = re.sub(r'--model\)\s*modelo="\$2"\s*shift\s*;;', 
                  '--model)\n                if [ -n "$2" ] && [[ "$2" != --* ]]; then\n                    modelo="$2"\n                    shift\n                else\n                    echo "❌ ERRO: --model requer um valor."\n                    return 1\n                fi\n                ;;', body)
    # Be careful not to replace standardize fallback if it doesn't assign to modelo
    body = re.sub(r'\*\)\s*modelo="\$1"\s*;;',
                  '*)\n                ALVO="$1"\n                ;;', body)
    return m.group(1) + body + m.group(3)
content = re.sub(std_regex, replace_std, content)

with open(file_path, 'w') as f:
    f.write(content)
