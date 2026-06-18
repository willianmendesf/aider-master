# 🤖 Aider OS v2.0: Knowledge Extraction Pipeline & Motor de Governança

O Aider OS evoluiu. Ele não é mais apenas um conjunto de prompts para o modelo de linguagem tentar entender o seu código lendo milhares de arquivos no escuro. 

Aider OS v2.0 é um **Sistema Operacional de Governança de Código** que atua como um **Language Server + MCP (Model Context Protocol)**. Ele orquestra ferramentas maduras de mercado (Compodoc, OpenAPI, TypeDoc, LSP) para extrair o AST do seu projeto, construir um Banco de Conhecimento relacional nativo (Entidades e Grafo) e permitir que você e a IA naveguem na arquitetura em **milissegundos**, com custo zero de tokens e mitigação total de alucinações.

O problema não é "fazer a IA ler o código". O problema resolvido aqui é **"Como não precisar que a IA leia o código inteiro para achar uma tela e suas dependências"**.

---

## 🛠️ Requisitos e Instalação

A instalação do repositório requer: `python3.10+`, `repomix`, `aider-chat`.
Para carregar os comandos globalmente, adicione ao seu `.bashrc` (Linux):
```bash
if [ -f "/dados/aider/bash_linux_functions.sh" ]; then
    source "/dados/aider/bash_linux_functions.sh"
fi
```
Ou adicione ao seu Git Bash / profile no Windows:
```bash
if [ -f "/dados/aider/bash_win_functions.sh" ]; then
    source "/dados/aider/bash_win_functions.sh"
fi
```

### Ferramentas Especializadas (Opcionais, mas altamente recomendadas)
Para extrair o máximo do Pipeline de Conhecimento, instale as ferramentas compatíveis com a sua stack:
- **Angular**: `@compodoc/compodoc`
- **Java/Spring**: OpenAPI (`springdoc-openapi`)
- **TypeScript**: `typedoc`

---

## 🧠 Arquitetura de Conhecimento (Como Funciona?)

O coração do Aider OS reside na pasta `.ai/`.

```text
.ai/
├─ knowledge/
│  ├─ entities.json (O catálogo universal de todas as telas, serviços, models, endpoints)
│  └─ graph.json (O grafo de arestas: quem chama quem, quem depende de quem)
├─ providers/ (Adaptadores Python para Compodoc, OpenAPI, TypeDoc)
├─ tooling/catalog/ (Regras YAML de detecção de stack)
└─ cache/ (Artefatos brutos extraídos pelas ferramentas)
```

O sistema não gera "enciclopédias Markdown" gigantes e inúteis. Ele gera **dados estruturados (JSON)** que os comandos de consulta consomem instantaneamente.

---

## 🔌 Model Context Protocol (MCP)

O Aider OS integra-se com o **MCP (Model Context Protocol)** para fornecer ferramentas nativas à IA:
1. **filesystem**: Acesso seguro ao sistema de arquivos
2. **code-rag**: Busca na memória indexada do projeto (`entities.json`) via as rotas `search_project_memory` e `get_project_map`.

A configuração MCP está em `mcp/mcp.json`.

---

## 🗺️ Repo-Map Nativo do Aider

O Aider OS agora usa o **repo-map nativo do Aider**, gerado automaticamente via Ctags/Tree-Sitter. Isso fornece contexto inteligente para a IA sem esforço manual.

### Como usar no dia a dia:
1. **Uso automático**: Quando você inicia o Aider (via `agent` ou diretamente), o repo-map é gerado e atualizado dinamicamente.
2. **Ver o mapa na sessão**: `/map`
3. **Atualizar o mapa na sessão**: `/map-refresh`
4. **Ver o mapa no terminal (fora do Aider)**: `aider --show-repo-map`

### Diferença entre repo-map e grafo local:
- **repo-map**: Contexto de conversa para a IA ler a hierarquia dos arquivos em tempo real (dinâmico, via Tree-Sitter).
- **Grafo local (where/impact/feature)**: Índice operacional absoluto para VOCÊ (determinístico, extraído por LSP/Compodoc, $0 de tokens).

---

## 🚀 Os Comandos do Aider OS (Fluxo Cronológico)

Esta tabela serve como seu documento de consulta rápida para o dia a dia, ordenada do momento em que você clona o projeto até o review final do código.

### 1. 🏗️ Setup Inicial e Regras (Quando entrar no projeto)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `bootstrap [modelo]` | **[Pipeline de Extração]** Roda apenas uma vez ou quando o projeto sofrer mudanças drásticas na arquitetura. Detecta a sua stack, aciona o Provider correto, normaliza os dados e gera o `entities.json` e o `graph.json`. **Processamento local (custa 0 tokens).** |
| `draft-rules [modelo] [--context-rows <numero>]` | **[Extrator de Padrões]** Analisa o código do projeto existente e extrai automaticamente as regras de projeto, estilo de código e arquitetura, gerando o arquivo imutável `.ai/rules/project-rules.md`. Por padrão lê 4000 linhas, mas você pode aumentar com `--context-rows` (ex: `--context-rows 12000`). |

### 2. ⚡ Consultas Rápidas (Investigando o código)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `where <nome>` | **[Onde Está?]** Retorna a localização exata (Arquivo e Linha) de forma limpa. Se houver múltiplos, exibe uma lista numerada. |
| `discover <nome> [--tree]` | **[O Que É Isso?]** Raio-X do componente sem LLM. Inferência de Feature, lista de Models/Services que utiliza e um laudo de Saúde Arquitetural (risco de acoplamento). A flag `--tree` desenha a hierarquia ASCII. |
| `impact <nome>` | **[O Que Quebra?]** Navega no Grafo e lista consumidores exatos. Avalia o Risco e emite uma **RECOMENDAÇÃO TÁTICA** (Pode alterar / Não altere) sugerindo o que deve ser testado em regressão. |
| `feature <nome> [--open | --ai | --report]` | **[Contexto Cirúrgico Completo]**<br>- **Sem flags**: Mostra ponto de entrada, fluxo principal, services, models, componentes reutilizados e lista de todos os arquivos relevantes<br>- `--ai` ou `--report`: Gera relatório explicativo via IA<br>- `--open`: Abre o Aider com **todos os arquivos relevantes carregados** (incluindo reused_components e external_services) e automaticamente dispara um onboarding que analisa a feature e responde com objetivo, fluxo, APIs, models, arquivos importantes, pontos de extensão e riscos de alteração (sem escrever código) |

### 3. 🧠 Decisão e Planejamento (Pensando antes de codar)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `architect "<problema>"` | **[Mudança Estrutural]** Ex: `architect "Migrar Context API para Redux"`. A IA não escreve código, apenas analisa trade-offs e gera arquivos oficiais `ADR-001.md`. |
| `design "<demanda>"` | **[Mudança Tática]** Ex: `design "Tela de login"`. Desenha a estrutura de componentes, eventos e fluxos. |
| `plan "<demanda>" [--feature <nome-feature>] [--new-screen] [--ref <tela-irma>] [--area <area>] [--doc <caminho-doc>] [--open] [--model <modelo>]` | **[Tech Lead]** Pega uma demanda e fatia o trabalho em um checklist executável numerado (ex: `.ai/plans/PLAN-001.md`).<br>- **`--feature <nome>`**: Injetar o contexto da feature como referência.<br>- **`--new-screen --ref <tela-irma>`**: Criar nova tela usando uma tela existente como padrão.<br>- **`--new-screen --area <area>`**: Criar nova tela usando referências de uma área específica.<br>- **`--doc <caminho>`**: Injetar um documento de requisitos como contexto adicional.<br>- **Regra crítica**: Não use `plan` sozinho para descobrir contexto. Sem flags de contexto, ele atua em modo global (planejamento abstrato). |
| `verify <caminho_do_plano>` | **[Auditoria Determinística]** Valida o plano: verifica se todos os arquivos listados como [REFERENCIA] ou [EDITAR] existem no disco, adiciona uma "Certificação de Auditoria" no plano (APROVADO/REPROVADO). |
| `discover <nome> [--tree] [--deep]` | **[Raio-X do Componente]** Mostra detalhes do componente.<br>- **`--deep`**: Inclui o conteúdo completo do arquivo no output. |

### 4. 🔨 Execução e Qualidade (Desenvolvimento Real)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `agent [modelo]` | **[Codificação Livre]** Inicia uma sessão iterativa do Aider. Você adiciona arquivos com `/add` e pede para ele criar código, componentes e lógicas livremente. Usa o repo-map para não ficar cego. |
| `dev <plano.md>` | **[Codificação Guiada]** A IA atua de forma disciplinada. Ela foca estritamente nas tasks do plano lendo as regras extraídas pelo `draft-rules`. |
| `standardize <alvo>` | **[Padronizador]** Força o código a convergir ao padrão da empresa. |
| `debug [modelo]` | **[Investigação de Bug]** Cruza rastros de erro de stacktrace com a base de código e aponta o defeito raiz. |
| `code-review <arquivo>` | **[Tribunal do Código]** Audita qualidade, segurança e arquitetura gerando um laudo detalhado com SCORE (0-100). |
| `review` | **[Revisão Operacional]** Revisão rápida de PR focada em limpeza, logs soltos e erros sintáticos fáceis. |

### 5. 🗣️ Modos de Dúvida e Estudo (Sem alterar código)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `ask` | Modo "Ask" (perguntas rápidas) bloqueado contra edições, preservando seu workspace. |
| `study` | Modo "Ask" sem rastros no Git (ideal para estudo livre). |
| `ask-refactor` | Modo especializado em táticas limpas de refatoração. |
| `ask-migration` | Modo focado em guiar atualizações e quebras de pacote (ex: Angular 15 para 18). |
| `ask-enterprise` | Modo focado em Segurança (OWASP), Governança e Alta Performance. |

### 6. ⚠️ Ferramentas Auxiliares e Legadas
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `bundle [arquivo]` | Empacota o projeto em texto puro (usando Repomix) para fallback. |
| `sync-full` | *(Deprecated)* Forçava geração de mapas estruturais baseados em LLM. Substituído por `bootstrap` + `repo-map nativo`. |
| `sync-module` | *(Deprecated)* Forçava geração de mapa modular. |

---

## 📚 Todas as Skills do Aider OS
O Aider OS usa skills especializadas para diferentes tarefas:

### Skills Obrigatórias (Sempre Carregadas no agent)
- `anti-hallucination.md`: Mitiga alucinações da IA e proíbe imports mortos.
- `clean-code.md`: Aplica princípios puros de Clean Code e arquitetura sólida.

### Skills de Domínio Específico (Carregadas sob demanda)
- **Análise & Investigação:** `analysis.md`, `investigation.md`, `root-cause-analysis.md`, `discover.md`
- **Planejamento:** `architect.md`, `system-design.md`, `rules-extractor.md`
- **Qualidade & Auditoria:** `bug-hunter.md`, `test-generator.md`, `pr-review.md`, `standardizer.md`, `security-audit.md`, `performance-audit.md`, `governance-audit.md`
- **Refatoração:** `refactor.md`, `enterprise-refactor.md`, `architecture-review.md`
- **Execução:** `dev-golden-path.md`, `angular-patterns.md`, `rtk-master.md`

---

## 🔌 Integrações
| Integração | Propósito |
| :--- | :--- |
| `Bitbucket` | Carrega comentários de PRs do Bitbucket direto na sessão do Aider (`integrations/bitbucket_cli.py`). |

---

## 📖 Como Integrar na Prática?
O manual prático e focado no dia a dia do Desenvolvedor foi reescrito! 
👉 **Consulte o arquivo [guide.md](./guide.md) para ver como navegar no Aider OS cronologicamente, do momento do `git clone` até o envio de um `Pull Request` perfeito.**
