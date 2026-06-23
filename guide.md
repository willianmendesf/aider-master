# 📘 AIDER OS: Guia Definitivo do Dia a Dia

Este guia é a sua referência prática para usar o Aider OS.

---

## 🚀 Setup Inicial (Primeiro Uso no Projeto)
Sempre que começar em um repositório novo:

1. **Indexar o Projeto (ETL Local):**
   ```bash
   bootstrap
   ```
   Isso detecta a stack (Angular, Spring, TypeScript, etc.), extrai metadados via ferramentas de mercado (Compodoc, OpenAPI, etc.), e gera o grafo de conhecimento. **Não usa nenhum token.**

2. **Extrair Regras de Projeto Automáticas (Opcional):**
   ```bash
   draft-rules
   ```
   Gera `.ai/rules/project-rules.md` com os padrões de código do seu projeto.

---

## 🔄 4 Workflows Oficiais (Uso Diário)
Esses são os fluxos que resolvem 99% dos casos.

---

### 1. Refatorar/Padronizar uma Tela Existente
Use este fluxo para limpar código, remover duplicatas e padronizar uma tela que já existe.

**Fluxo Completo:**
```bash
# Passo 1: Mapear o contexto da tela
feature <nome-da-tela>

# Passo 2: Opção 1 — Verificar o estado atual (--audit)
standardize <caminho-da-tela> --audit

# Passo 2: Opção 2 — Gerar plano de padronização (--plan)
standardize <caminho-da-tela> --plan

# Passo 3: Orquestrar a Arquitetura da Solução (Gera spec, plan e tasks)
plan "padronizar a tela <nome-da-tela>, remover duplicações, validar utils existentes e simplificar validações complexas" --feature <nome-da-tela>

# Passo 4: Executar a Feature Restrita
dev <nome-da-tela>

# Passo 5: Auditoria Cruzada (Code Review 360)
code-review <nome-da-tela>
```

---

### 2. Criar Tela Nova Baseada em Tela Irmã (Main Workflow)
**Este é o fluxo principal para criar telas novas!** Usa uma tela existente como referência para manter consistência.

**Fluxo Completo:**
```bash
# Passo 1: Criar toda a especificação da nova tela baseada na irmã
plan "criar nova tela <nome-da-nova-tela> baseada na tela <nome-da-tela-irma>, mantendo estrutura e adaptando filtros/models conforme documentação" --feature <nome-da-nova-tela>

# Passo 2: Executar rigorosamente as tarefas geradas
dev <nome-da-nova-tela>

# Passo 3: Auditar a qualidade cruzando Spec vs Código
code-review <nome-da-nova-tela>
```

---

### 3. Entender Tela Legada (Extrair Tudo)
Use esse fluxo para entender completamente uma tela que você não conhece.

**Fluxo Completo:**
```bash
# Passo 1: Ver o contexto cirúrgico da feature
feature <nome-da-tela>

# Passo 2: Raio-X profundo da tela (inclui conteúdo do arquivo)
discover <nome-da-tela> --deep

# Passo 3: Ver o impacto da tela (o que ela usa)
impact <nome-da-tela>

# Passo 4: Opção — Gerar relatório explicativo via IA
feature <nome-da-tela> --ai
```

Esses passos extraem:
- Regras de negócio
- APIs consumidas
- Payloads enviados/recebidos
- Validações
- Base64/download de arquivos
- Models utilizados
- Fluxo tela → service → endpoint

---

### 4. Backend Gigante: Entender Endpoint/Service/Controller
Use esse fluxo para encontrar e entender rapidamente um backend complexo.

**Fluxo Completo (Se você sabe o nome do endpoint/service):**
```bash
# Passo 1: Localizar exato
where <nome-do-endpoint/service/controller>

# Passo 2: Raio-X profundo
discover <nome-do-endpoint/service/controller> --deep

# Passo 3: Ver impacto
impact <nome-do-endpoint/service/controller>
```

**Fluxo Completo (Se você só sabe o tema, ex: "boleto"):**
```bash
# Passo 1: Garantir que o grafo está atualizado (se precisar)
bootstrap

# Passo 2: Buscar tudo relacionado
discover <tema> --deep

# Passo 3: Ver entidades importantes
where <tema>

# Passo 4: Ver impacto do service principal
impact <nome-do-service-principal>

# Passo 5: Opção — Relatório IA
feature <tema> --ai
```

---

## ⚡ Comandos de Consulta Rápida (0 Tokens)
Esses comandos são locais e instantâneos, sem usar a IA:
- `where <nome>`: Encontra o caminho do arquivo e a linha
- `discover <nome> [--tree] [--deep]`: Mostra detalhes, dependências e saude arquitetural
- `impact <nome>`: Mostra todos os consumidores da entidade (o que quebra se você alterar)
- `feature <nome>`: Mostra o contexto completo da feature

---

## ⚠️ Comandos Depreciados
Não use mais esses comandos, eles foram substituídos por soluções melhores:
- `sync-full`: Use `bootstrap` e repo-map nativo do Aider
- `sync-module`: Use `bootstrap` e repo-map nativo do Aider
- `design` para telas: Use o workflow 2 (feature → plan --new-screen --ref) em vez disso. O `design` só deve ser usado para decisões maiores de produto/arquitetura.

---

## 🛡️ Conclusão
O fluxo diário oficial é sempre:
1. `feature`/`discover` para entender.
2. `plan "..." --feature X` para orquestrar o planejamento (spec, plan, tasks).
3. `dev X` para o Aider construir e tickar o checklist de tarefas sozinho.
4. `code-review X` para garantir que o Aider não alucinou no código final.
