# 🤖 Aider OS v2.0: Knowledge Extraction Pipeline & Motor de Governança

O Aider OS evoluiu. Ele não é mais apenas um conjunto de prompts para o modelo de linguagem tentar entender o seu código lendo milhares de arquivos no escuro. 

Aider OS v2.0 é um **Sistema Operacional de Governança de Código** que atua como um **Language Server + RAG**. Ele orquestra ferramentas maduras de mercado (Compodoc, OpenAPI, TypeDoc, LSP) para extrair o AST do seu projeto, construir um Banco de Conhecimento relacional nativo (Entidades e Grafo) e permitir que você e a IA naveguem na arquitetura em **milissegundos**, com custo zero de tokens e mitigação total de alucinações.

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
│
├─ providers/ (Adaptadores Python para Compodoc, OpenAPI, TypeDoc)
├─ tooling/catalog/ (Regras YAML de detecção de stack)
└─ cache/ (Artefatos brutos extraídos pelas ferramentas)
```

O sistema não gera "enciclopédias Markdown" gigantes e inúteis. Ele gera **dados estruturados (JSON)** que os comandos de consulta consomem instantaneamente.

---

## 🚀 Os Comandos do Aider OS (Manual de Referência)

Esta tabela serve como seu documento de consulta rápida para o dia a dia.

### 1. 🏭 ETL de Conhecimento
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `bootstrap` | **[Pipeline de Extração]** Roda apenas uma vez ou quando o projeto sofrer mudanças drásticas. Detecta a sua stack, aciona o Provider correto (Compodoc, OpenAPI, TypeDoc ou Repomix), normaliza os dados e gera o `entities.json` e o `graph.json`. **Não consome IA, apenas processamento local.** |

### 2. ⚡ Consultas Rápidas (Respostas em milissegundos sem gastar Tokens)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `where <nome>` | Retorna a localização exata no disco (Arquivo e Linha) de uma classe, função, módulo ou componente. |
| `discover <nome>` | Busca textual super-rápida. Mostra as propriedades da entidade, de onde veio e o Grau de Confiança da extração (ex: 100% via AST Compodoc). |
| `impact <nome>` | **[Análise de Quebra]** Navega recursivamente no `graph.json` usando arestas reversas (`used_by`). Responde imediatamente: "Quem quebra se eu alterar esse Service?". |

### 3. 🧠 RAG (Retrieval-Augmented Generation)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `brain-index <caminho_projeto> <nome_projeto>` | Indexa um projeto no banco de dados RAG local, para consultas rápidas posteriores. |
| `python rag/rag_cli.py search <query> [nome_projeto]` | Busca no índice RAG um tópico (ex: `search "AppointmentService" dashboard-manager`). Se o projeto não for informado, tenta detectar automaticamente pelo git root. |
| `python rag/rag_cli.py map [nome_projeto]` | Mostra a estrutura de arquivos do projeto indexado. |

### 4. 🎯 Orquestração Contextual com IA
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `agent [modelo]` | **[Core]** Inicia o agente Aider com o modelo de linguagem (padrão: `o3-mini`). Carrega automaticamente as skills base e regras do projeto. |
| `ask [modelo]` | Modo "Ask" (perguntas rápidas) sem contexto de arquivo. |
| `study [modelo]` | Modo "Ask" sem Git (ideal para estudo e exploração). |
| `ask-refactor [modelo]` | Modo Ask especializado em refatorações (carrega skills de análise, arquitetura, refatoração enterprise e testes). |
| `ask-migration [modelo]` | Modo Ask especializado em migrações de código/tecnologia. |
| `ask-enterprise [modelo]` | Modo Ask completo para empresas (inclui análise, segurança, performance, observabilidade e governança). |
| `feature <nome>` | **[Foco de Laser]** A IA atua. Ela varre as entidades associadas a essa feature, entende a conexão Tela → Service → Endpoint via Grafo, isola esse contexto microscópico, e gera o relatório arquitetural perfeito. O LLM recebe APENAS o que importa. |

### 5. 🧠 Planejamento e Decisão Estrutural
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `architect "<problema>"`| **[Mudança Estrutural]** Requer um problema obrigatório (ex: `architect "Migrar para Redux"`). A IA não escreve código, apenas analisa trade-offs e gera arquivos oficiais `ADR-001.md`. |
| `design "<demanda>"` | **[Mudança Tática]** Requer a demanda local (ex: `design "Tela de login"`). Desenha a estrutura de componentes, eventos e fluxos. |
| `plan <demanda/ADR>` | **[Tech Lead]** Pega um ADR ou demanda e gera um checklist executável no `.ai/plans/PLAN-XXX.md`. |

### 6. 🔨 Execução e Convergência (Codificação)
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `dev <plano.md>` | **[Motor Restrito]** A IA atua como pedreiro copiando os padrões contidos no golden path `.ai/examples/`. O dev segue fielmente as tasks do plano. |
| `standardize <alvo> [--audit|--plan|--fix]` | **[Padronizador]** Força o código a convergir ao padrão da empresa. |
| `code-review <arquivo/diretorio>` | **[Tribunal do Código]** Audita qualidade, segurança e arquitetura de um arquivo ou diretório, gerando um laudo detalhado. |
| `review` | **[Revisão Operacional]** Revisão rápida de PR focada em limpeza, variáveis não usadas, logs e erros sintáticos. |
| `debug` | **[Investigação de Bug]** Usa Root Cause Analysis e Bug Hunter para encontrar a causa raiz de um problema. |

### 7. 🛠️ Ferramentas Auxiliares
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `bundle [output_file]` | Empacota o código do projeto em um arquivo texto (usando Repomix) para contexto rápido. |
| `draft-rules [modelo]` | Analisa o código do projeto e extrai automaticamente as regras de projeto, coding style e arquitetura, gerando `.ai/rules/project-rules.md`. |

---

## 📚 Todas as Skills do Aider OS
O Aider OS usa skills especializadas para diferentes tarefas:

### Skills Obrigatórias (Sempre Carregadas)
| Skill | Propósito |
| :--- | :--- |
| `anti-hallucination.md` | Mitiga alucinações da IA. |
| `clean-code.md` | Aplica princípios de Clean Code. |
| `rtk-master.md` | Especializada em Redux Toolkit (RTK). |

### Skills de Análise
| Skill | Propósito |
| :--- | :--- |
| `analysis.md` | Análise geral de código e arquitetura. |
| `context-builder.md` | Constrói contexto para a IA. |
| `investigation.md` | Investigação de problemas. |

### Skills de Bug e Depuração
| Skill | Propósito |
| :--- | :--- |
| `bug-hunter.md` | Caça bugs no código. |
| `root-cause-analysis.md` | Análise de causa raiz de problemas. |

### Skills de Refatoração
| Skill | Propósito |
| :--- | :--- |
| `refactor.md` | Refatoração básica. |
| `enterprise-refactor.md` | Refatoração de código enterprise. |
| `architecture-review.md` | Revisão de arquitetura. |

### Skills de Qualidade e Testes
| Skill | Propósito |
| :--- | :--- |
| `test-generator.md` | Gera testes automatizados. |
| `pr-review.md` | Revisão de Pull Requests. |
| `standardizer.md` | Padronização de código. |

### Skills Especializadas
| Skill | Propósito |
| :--- | :--- |
| `security-audit.md` | Auditoria de segurança. |
| `performance-audit.md` | Auditoria de performance. |
| `git-guardian.md` | Protege o git (segurança e boas práticas). |
| `governance-audit.md` | Auditoria de governança de código. |
| `architect.md` | Decisões arquiteturais (ADRs). |
| `system-design.md` | Design de sistema tático. |
| `dev-golden-path.md` | Execução de código seguindo o golden path do projeto. |
| `angular-patterns.md` | Padrões específicos para Angular. |
| `discover.md` | Descoberta de código. |
| `rules-extractor.md` | Extrai regras de projeto do código. |

---

## 🔌 Integrações
| Integração | Propósito |
| :--- | :--- |
| `Bitbucket` | Integração com Bitbucket Pull Requests para carregar comentários diretamente na sessão Aider (usa `integrations/bitbucket/bitbucket_cli.py`). |

---

## 📦 Templates de Inicialização
Use os templates na pasta `templates/aider-os/` para inicializar rapidamente a estrutura do `.ai/` em um novo projeto:
- `templates/aider-os/.ai/constitution.md`: Constituição do projeto.
- `templates/aider-os/.ai/rules/`: Regras de arquitetura, coding, projeto e testes.

---

## 📖 Como Integrar na Prática?
O manual prático e focado no dia a dia do Desenvolvedor mudou! 
👉 **Consulte o arquivo [guide.md](./guide.md) para aprender a parar de gastar tokens ensinando a IA e começar a extrair respostas imediatas do Grafo do seu projeto.**
