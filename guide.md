# 📘 Aider OS: Guia Definitivo do Dia a Dia (v2.0)

Este documento é a sua **Referência Diária** para operar o Aider OS. 

O grande diferencial desta versão é que você **não precisa mais ser o "RAG humano" da IA**. Se antes você perdia tempo caçando em quais pastas estavam as Models, Services e Interfaces para contextualizar a inteligência artificial, agora você usa o Grafo local, o repo-map nativo do Aider e o MCP (Model Context Protocol).

---

## 🔄 Cenários de Trabalho Reais (Ordem Cronológica de Uso)

Abaixo estão os cenários de rotina organizados na ordem natural de evolução do seu trabalho: do dia em que você entra no projeto até o deploy.

---

### Cenário 1: Cheguei num Projeto Novo (Setup Inicial)
Você acabou de clonar o repositório ou o time decidiu instaurar o Aider OS no projeto atual. Antes de codar, você precisa ensinar o sistema a ler a estrutura.

1. **Rode o comando de diagnóstico (Opcional, mas útil)**:
   ```bash
   python3 /dados/aider/scripts/knowledge_pipeline.py --doctor
   ```
   Ele vai sugerir a melhor ferramenta de mercado (ex: Compodoc, TypeDoc, OpenAPI) compatível com seu projeto para extrair dados brutos.

2. **Gere a Base de Dados de Conhecimento**:
   ```bash
   bootstrap
   ```
   O Aider OS não chamará o LLM. Ele rodará as ferramentas detectadas, normalizará a saída e criará um poderoso banco relacional local em `.ai/knowledge/entities.json` e `.ai/knowledge/graph.json`. O projeto agora está indexado localmente e instantaneamente pesquisável.

3. **(Opcional) Inicialize com Templates**:
   Se o projeto ainda não tem a estrutura `.ai/`, copie os templates da pasta `templates/aider-os/` para a raiz do seu projeto.

---

### Cenário 2: Extrair e Fixar Regras de Arquitetura Automáticas
Você indexou o mapa de arquivos no Passo 1, mas agora a IA precisa saber *como* o time programa (Padrões, bibliotecas, nomenclaturas).

1. **Extrair Regras do Código Existente**:
   ```bash
   draft-rules
   
   # Para projetos maiores, aumente a amostra de leitura:
   draft-rules --context-rows 12000
   ```
   O comando analisará o código de todo o repositório e gerará o arquivo `.ai/rules/project-rules.md`. A partir de hoje, sempre que a IA codar algo, ela respeitará as regras contidas neste arquivo em vez de inventar padrões novos.

---

### Cenário 3: Onde fica essa classe? (Investigação Rápida)
O projeto está configurado. O chefe mandou arrumar a classe "FinanceiroService", mas você não sabe onde ela está num projeto de 5000 arquivos. 

1. **Localização Exata**:
   ```bash
   where FinanceiroService
   ```
   Resposta em milissegundos apontando o arquivo exato e a linha. Custo zero de tokens.

2. **Descobrindo Detalhes (Grau de Confiança)**:
   ```bash
   discover Proposta
   ```
   Informa o arquivo, o tipo (model, component, endpoint) e como ele foi encontrado.

---

### Cenário 4: O que vou quebrar se eu mudar isso? (Análise de Impacto)
A dor clássica: "Se eu alterar a assinatura do `gerarBoleto()`, quais telas vão parar de funcionar?".

1. **Navegue pelas arestas do Grafo Instantaneamente**:
   ```bash
   impact FinanceiroService
   ```
   Lê o `graph.json` em ordem reversa (`used_by`) e lista todos os Componentes, Módulos e Controllers que dependem da classe. Você descobre o raio de quebra instantaneamente sem acionar a IA.

---

### Cenário 5: Desenvolvendo uma Nova Feature Baseada no Legado
Você precisa criar uma "Nova Proposta Previdência". Em vez de colocar todos os 500 arquivos do módulo no prompt e deixar a IA confusa, você atua como um cirurgião.

1. **Monte o Contexto Cirurgicamente**:
   ```bash
   feature previdencia
   ```
   O sistema varre os JSONs, cruza os serviços da tela de previdencia usando o Grafo de Dependências, e isola apenas os 5 ou 6 arquivos relevantes. 

2. **Planeje a Mudança como um Tech Lead**:
   ```bash
   plan "Adicionar regra de desconto na Nova Proposta Previdência"
   ```
   A IA fatiará a feature em pequenas tarefas de código num arquivo `PLAN-001.md`.

3. **Programe as Tarefas (O Método Guiado)**:
   ```bash
   dev .ai/plans/PLAN-001.md
   ```
   A IA executará o plano de forma focada e cega a distrações.

---

### Cenário 6: Desenvolvimento Livre (Mão na Massa Direto)
Se a sua tarefa é pequena e não exige um "Plano Oficial", você pode codar e gerar arquivos livremente numa sessão interativa, usando o `agent` principal.

1. **Inicie o Agente de Desenvolvimento**:
   ```bash
   agent
   ```
   Isso abre a sessão do Aider já com o `repo-map` carregado.

2. **Adicione Contexto no Chat**:
   Descobriu com o `where` que o arquivo é o `proposta.service.ts`? Adicione-o à conversa:
   ```text
   /add src/services/proposta.service.ts
   ```

3. **Gere Código e Arquivos**:
   Basta pedir em linguagem natural na sessão:
   ```text
   > crie um novo arquivo de Utils para datas e refatore o PropostaService para usá-lo.
   ```
   O Aider irá criar o arquivo, escrever o código, e aplicar a mudança. Como desativamos commits automáticos (`--no-auto-commits`), você revisa tudo no seu VSCode antes de commitar!

---

### Cenário 7: Investigando um Bug em Produção
O sistema quebrou, e você tem apenas a mensagem de erro.

1. **Inicie a Investigação de Causa Raiz**:
   ```bash
   debug
   ```
   O comando carrega as skills de `root-cause-analysis.md` e `bug-hunter.md`. Cole o erro do console, e a IA cruzará o log com o repo-map para encontrar a linha exata que está causando pânico, sem sugerir gambiarras.

---

### Cenário 8: Garantir a Qualidade da Entrega (Antes do Deploy)
Mudança feita e bug corrigido. Hora de garantir que ninguém feriu os padrões corporativos.

1. **Limpeza e Auditoria**:
   ```bash
   standardize src/app/nova-proposta --audit
   code-review src/app/nova-proposta
   ```
   A IA verifica os padrões do seu `project-rules.md` e do `Golden Path`, punindo a entrega em caso de dívidas técnicas introduzidas, bloqueando lixo no código.

---

### Cenário 9: Modo Ask (Perguntas Rápidas ao Longo do Dia)
Você tem uma dúvida conceitual sobre o código, sem precisar editar nada.

1. **Modo Ask Genérico**:
   ```bash
   ask
   ```

2. **Modos Ask Especializados**:
   - `ask-refactor`: Para perguntas de refatoração ("Como deixar esse while mais eficiente?")
   - `ask-migration`: Dúvidas sobre upgrade de versão ("Como migrar isso pra Angular 18?")
   - `ask-enterprise`: Foco em segurança e performance.
   - `study`: Modo Ask sem alterar o Git (ideal para aprender a linguagem).

---

## 🗺️ Usando o Repo-Map Nativo

Durante qualquer conversa, o Aider constrói o mapa estrutural automaticamente:
1. **Na sessão do Aider**: use `/map` ou `/map-refresh`
2. **No terminal**: execute `aider --show-repo-map`

O repo-map é mantido automaticamente e não requer manutenção manual.

---

## 🛡️ O Fim do "Senta e Reza"

A grande mensagem do Aider OS v2.0 é: **Ferramentas consagradas (LSP, AST, OpenAPI, repo-map nativo) extraem os metadados muito melhor que LLMs lendo texto corrido.**

Ao adotar o fluxo `bootstrap` → `draft-rules` → `where` → `impact` → `plan` → `dev`, você deixa de terceirizar a arquitetura mental do sistema para uma IA cara e lenta. O seu repositório ganha uma Memória Operacional local rápida, e a IA faz apenas aquilo que faz de melhor: programar dentro de um contexto pequeno, controlado e livre de alucinações.
