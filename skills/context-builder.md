---
name: Context Builder
description: Construir mapa mental e arquitetural do projeto (Aider OS).
---

# Objetivo
Criar um mapa global atualizado do sistema ou módulo sem alterar nenhum código fonte.

# Regras Absolutas
- NUNCA crie novos padrões ou modifique código existente.
- Aja unicamente como leitor e documentador.

# O que Mapear
1. Estrutura de Domínios e Pastas (project-map.md)
2. Lista de Entidades, Modelos e Fluxos (domain-map.md)
3. Relacionamentos Críticos
4. Identificar dependências e pontos de integração externa

# Saída
Sempre sobrescreva e salve o resumo diretamente em:
- `.ai/context/project-map.md`
- `.ai/context/domain-map.md`
