# 📘 Aider OS: Guia Definitivo do Dia a Dia (v2.0)

Este documento é a sua **Referência Diária** para operar o Aider OS. 

O grande diferencial desta versão é que você **não precisa mais ser o "RAG humano" da IA**. Se antes você perdia tempo caçando em quais pastas estavam as Models, Services e Interfaces para contextualizar a inteligência artificial, agora você usa o Grafo local, o repo-map nativo do Aider e o MCP (Model Context Protocol).

---

## 🔄 Cenários de Trabalho Reais

Abaixo estão os cenários de rotina do desenvolvedor. Aprenda a usar o *Knowledge Extraction Pipeline* a seu favor.

---

### Cenário 1: Cheguei num Projeto Novo (ETL Inicial)
Você acabou de clonar o repositório ou o time decidiu instaurar o Aider OS no projeto atual.

1. **Rode o comando de diagnóstico (Opcional, mas útil)**:
   ```bash
   python3 /dados/aider/scripts/knowledge_pipeline.py --doctor
   ```
   Ele vai sugerir a melhor ferramenta de mercado (ex: Compodoc, TypeDoc, OpenAPI) compatível com seu projeto para extrair dados brutos.

2. **Gere a Base de Dados de Conhecimento**:
   ```bash
   bootstrap
   ```
   O Aider OS não chamará o LLM. Ele rodará as ferramentas detectadas, normalizará a saída e criará um poderoso banco relacional local em `.ai/knowledge/entities.json` e `.ai/knowledge/graph.json`. O projeto agora está indexado.

3. **(Opcional) Indexe o projeto no RAG**:
   ```bash
   brain-index /caminho/para/projeto nome-do-projeto
   ```
   Isso permite usar as ferramentas MCP `search_project_memory` e `get_project_map` para consultas rápidas.

4. **(Opcional) Inicialize com Templates**:
   Se o projeto ainda não tem a estrutura `.ai/`, copie os templates da pasta `templates/aider-os/` para a raiz do seu projeto.

---

### Cenário 2: Perdi o Pé do Chão! Onde fica essa classe?
Você quer encontrar a localização exata de um Service ou Model no disco sem precisar de IDE pesada ou usar LLM para "achar o arquivo".

1. **Consulta Rápida**:
   ```bash
   where FinanceiroService
   ```
   Resposta em 500ms apontando o arquivo exato e a linha, lendo direto do `entities.json`.

2. **Descobrindo Detalhes (Grau de Confiança)**:
   ```bash
   discover Proposta
   ```
   Informa o arquivo, o tipo (model, component, endpoint) e o grau de confiança (ex: 100% de confiança se foi extraído por LSP/Compodoc, ou 70% se for via fallback Repomix).

---

### Cenário 3: Preciso alterar um Serviço. O que vou quebrar?
A dor clássica: "Se eu alterar a assinatura do `gerarBoleto()`, quais telas vão parar de funcionar?".

1. **Navegue pelas arestas do Grafo Instantaneamente**:
   ```bash
   impact FinanceiroService
   ```
   O comando não usa tokens de IA. Ele lê o `graph.json` em ordem reversa (`used_by`) e lista exatamente todos os Componentes, Módulos e Controllers que dependem de `FinanceiroService`. Você descobre o raio de quebra instantaneamente.

---

### Cenário 4: Desenvolvendo uma Nova Feature Baseada no Legado
Você precisa criar uma "Nova Proposta Previdência". Em vez de colocar todos os 500 arquivos do módulo no prompt e deixar a IA confusa e alucinando, você atua como um cirurgião.

1. **Monte o Contexto Cirurgicamente**:
   ```bash
   feature previdencia
   ```
   O sistema varre os JSONs, cruza os serviços da tela de previdencia usando o Grafo de Dependências, e isola apenas os 5 ou 6 arquivos relevantes. O Aider usará ESSE minúsculo e focado relatório para entender a feature.

2. **Planeje a Mudança e Programe**:
   ```bash
   plan "Adicionar regra de desconto na Nova Proposta Previdência"
   dev .ai/plans/PLAN-001.md
   ```

---

### Cenário 5: Garantir a Qualidade da Entrega
Mudança feita. Hora de garantir que ninguém feriu os padrões.

1. **Limpeza e Auditoria**:
   ```bash
   standardize src/app/nova-proposta --audit
   code-review src/app/nova-proposta
   ```
   A IA verifica os padrões do seu `.ai/examples/` (Golden Path) e pune a entrega em caso de dívidas técnicas introduzidas, bloqueando a ida pra produção de lixo no código.

---

### Cenário 6: Modo Ask (Perguntas Rápidas)
Você tem uma dúvida rápida sobre o código, sem precisar editar nada.

1. **Modo Ask Genérico**:
   ```bash
   ask
   ```
   Ou use um modelo específico:
   ```bash
   ask gpt-4o
   ```

2. **Modo Ask Especializados**:
   - `ask-refactor`: Para perguntas sobre refatoração
   - `ask-migration`: Para perguntas sobre migração de tecnologia
   - `ask-enterprise`: Para perguntas completas (segurança, performance, governança)
   - `study`: Modo Ask sem Git (ideal para estudo)

---

### Cenário 7: Investigando um Bug
Você tem um problema e precisa encontrar a causa raiz.

1. **Inicie o Investigação**:
   ```bash
   debug
   ```
   O comando carrega as skills de `root-cause-analysis.md` e `bug-hunter.md` para ajudar a encontrar o problema.

---

### Cenário 8: Usando o RAG para Projetos Antigos
Você quer consultar rapidamente um projeto indexado anteriormente.

1. **Indexar um Projeto no RAG**:
   ```bash
   brain-index /caminho/para/projeto meu-projeto
   ```

2. **Buscar no RAG (via CLI)**:
   ```bash
   python /dados/aider/rag/rag_cli.py search "AppointmentService" meu-projeto
   ```

3. **Ver a Estrutura do Projeto Indexado**:
   ```bash
   python /dados/aider/rag/rag_cli.py map meu-projeto
   ```

---

### Cenário 9: Extrair Regras de Projeto Automaticamente
Você entrou em um projeto novo e quer entender as regras de código e arquitetura.

1. **Extrair Regras**:
   ```bash
   draft-rules
   ```
   O comando analisará o código e gerará `.ai/rules/project-rules.md` com as regras de projeto, coding style e arquitetura.

---

## 🗺️ Usando o Repo-Map Nativo

Para ver o repo-map gerado automaticamente pelo Aider:
1. **Na sessão do Aider**: use `/map` ou `/map-refresh`
2. **No terminal**: execute `aider --show-repo-map`

O repo-map é mantido automaticamente e não requer manutenção manual.

---

## 🛡️ O Fim do "Senta e Reza"

A grande mensagem do Aider OS v2.0 é: **Ferramentas consagradas (LSP, AST, OpenAPI, repo-map nativo) extraem os metadados muito melhor que LLMs lendo texto corrido.**

Ao adotar o fluxo `bootstrap` → `where` → `impact` → `feature` → `dev`, você deixa de terceirizar a arquitetura mental do sistema para uma IA cara e lenta. O seu repositório ganha uma Memória Operacional local rápida, e a IA faz apenas aquilo que faz de melhor: programar dentro de um contexto pequeno, controlado e livre de alucinações.

---

## 📚 Comandos de Referência Rápida
Para uma lista completa de todos os comandos, skills, integrações e MCP, consulte o arquivo [README.md](./README.md).
