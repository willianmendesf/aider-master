# 🤖 Aider OS: Motor de Governança Inteligente v1.0

Este repositório é um **Sistema Operacional de Governança de Código**. O Aider OS garante que a Inteligência Artificial deixe de atuar como um "Júnior Criativo" que inventa padrões aleatórios, e passe a atuar como um ecossistema disciplinado de **Arquitetura, Liderança Técnica, Confiabilidade (SRE) e Auditoria**.

---

## 🛠️ Requisitos e Instalação

A instalação do repositório requer: `python3.10+`, `repomix`, `aider-chat`.
Para carregar os comandos globalmente, adicione ao seu `.bashrc` (Linux) ou Bash do Windows:
```bash
if [ -f "/dados/aider/bash_linux_functions.sh" ]; then
    source "/dados/aider/bash_linux_functions.sh"
fi
```

---

## 🚀 Os Comandos do Aider OS (Manual de Referência)

Esta tabela serve como seu documento de consulta rápida para o dia a dia.
> **Lembrete:** Nunca apague a pasta `.ai/` manualmente. Ela é o cérebro do projeto.

### 1. 🗺️ Descoberta e Inicialização
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `bootstrap` | **[Setup de Projeto]** Roda apenas uma vez no projeto. Mapeia a arquitetura, gera os mapas (`project-map.md`), emite o *Laudo de Arquitetura Base*, compila o **Technical Debt Backlog Inicial** e elege os arquivos mais limpos como candidatos a Golden Path (`.ai/examples/candidates.md`). |
| `discover <alvo>` | **[Engenharia Reversa]** Desvenda sistemas legados. Argumentos suportados: <br>`--flow`: Mostra o fluxo completo (Frontend → Backend → DB).<br>`--api`: Foca em mapear endpoints, payloads e autenticação.<br>`--db`: Foca nas tabelas, consultas e views envolvidas.<br>`--deep`: Análise massiva e completa de todas as camadas. |
| `sync-full` | **[Re-sincronização]** Lê a árvore de pastas atual (limitado a 15k tokens) e reconstrói o `project-map.md`. Use se as pastas mudaram drasticamente. |
| `sync-module <pasta>`| Foca a sincronização apenas na pasta informada para economizar tokens, integrando ao mapa existente. |

### 2. 🧠 Planejamento e Decisão
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `architect "<problema>"`| **[Mudança Estrutural]** Requer um problema obrigatório (ex: `architect "Migrar para Redux"`). A IA não escreve código, apenas analisa trade-offs e gera arquivos oficiais `ADR-001.md`, etc. |
| `design "<demanda>"` | **[Mudança Tática]** Requer a demanda local (ex: `design "Tela de login"`). Desenha a estrutura de componentes, eventos e fluxos, sem o peso formal de um ADR. |
| `plan <demanda/ADR>` | **[Tech Lead]** Pega um ADR ou demanda e gera um checklist executável no `.ai/plans/PLAN-XXX.md`. **Obrigatório:** O plano declara no topo o bloco `## Sources` listando todas as regras e exemplos que usou para tomar decisões. |

### 3. 🔨 Execução e Convergência
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `dev <plano.md>` | **[Motor Restrito]** A IA atua como pedreiro. É **proibida** de criar padrões, dependências ou arquitetura sem ADR. Ela lê o `.md`, escreve o código copiando o `.ai/examples/` e marca as tarefas com o **Evidence Logging** (ex: `Implemented: src/app.js \| Ref: ADR-001`). |
| `standardize <alvo>` | **[Padronizador]** Força um código a convergir ao padrão da empresa. <br>`--audit`: (Padrão) Lista divergências. Não altera código.<br>`--plan`: Identifica erros e gera um `PLAN-XXX.md` de correção.<br>`--fix`: Entra ativamente modificando o código para padronizá-lo. |

### 4. ⚖️ Qualidade e Auditoria
| Comando | Descrição Completa e Casos de Uso |
| :--- | :--- |
| `review` | **[Micro-Gerenciamento]** A IA limpa o seu código sujo de desenvolvimento: tira `console.log`, avisa de variáveis mortas, limpa lixo comentado. Roda antes do PR. |
| `code-review <alvo>` | **[Tribunal do Código]** A IA audita a arquitetura. Valida as metas mínimas (ex: Feature Nova tem que ser B). **Atenção:** Possui sistema de 🚫 **Bloqueadores**. Se houver vazamento de tokens ou uso de `any` proibido, o laudo dá **REPROVADO** incontestavelmente. |
| `debug` | **[SRE Root Cause Analysis]** Dado um erro, a IA investiga pelo mapa. Passa pelas fases: Sintoma → Evidência → Hipótese → Validação → Causa Raiz. **Proibida de sugerir gambiarras**. |

---

## 📖 Como Integrar na Prática?
O manual prático e focado no dia a dia do Desenvolvedor foi condensado no arquivo de guia.
👉 **Consulte o arquivo [guide.md](./guide.md) para aprender a navegar nos 5 cenários práticos reais.**

---

## 🚀 Roadmap v1.1
Os seguintes comandos já estão planejados para a próxima fase (Manutenção e Legado):
- **`compare <A> <B>`**: Para gerar matriz de convergência entre duas telas, APIs ou componentes.
- **`explain <alvo>`**: Modo didático de extração de conhecimento sem verbosidade técnica, puramente para ensino de negócio.
