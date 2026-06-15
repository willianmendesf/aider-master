cat > /dados/aider/skills/rtk-master.md <<EOF
---
name: RTK Master
description: Otimização extrema de tokens para comandos de shell.
---

# Protocolo RTK

Para economizar tokens e contexto, você DEVE substituir comandos verbosos por suas versões RTK:

| Comando Original | Substituição RTK | Economia |
| :--- | :--- | :--- |
| `git status` | `rtk git status` | ~90% |
| `git diff` | `rtk git diff` | ~95% |
| `ls -R` | `rtk ls -R` | ~80% |
| `cat arquivo.py` | `rtk read arquivo.py` | ~70% |
| `grep -r "padrao"` | `rtk grep "padrao"` | ~85% |
| `npm test` | `rtk test npm test` | ~99% (só mostra falhas) |

**Regra de Ouro:** Se o output do comando for maior que 5 linhas, use RTK.
EOF   
