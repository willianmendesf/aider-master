# 📘 Aider OS: Guia Definitivo do Dia a Dia (v1.0)

Este documento é a sua **Referência Diária** para operar o Aider OS. 

A regra de ouro de governança: **Toda alteração estrutural ou funcional deve possuir planejamento prévio.** 

---

## 🔄 Cenários de Trabalho Reais

Abaixo estão os 5 cenários de rotina do desenvolvedor. Siga este "livro de receitas" para garantir rastreabilidade e qualidade absoluta.

### Cenário 1: Projeto Novo (Setup Inicial)
*Você acabou de clonar o repositório ou o time decidiu instaurar o Aider OS no projeto atual.*
1. Rode o comando obrigatório:
   ```bash
   bootstrap
   ```
2. **O que esperar:** A IA lerá tudo. Ela vai criar a pasta `.ai/`, gerar o `project-map.md`, entregar o primeiro Laudo de Arquitetura Base, documentar suas dívidas técnicas (Backlog) e apontar quais arquivos do seu projeto devem virar o *Golden Path* (`.ai/examples/candidates.md`).

---

### Cenário 2: Funcionalidade Complexa ou Mudança Estrutural
*O Product Owner pediu algo grande: "Mudar Redux para Signals", "Criar fluxo inteiro de pagamentos", "Trocar lib de PDFs".*
1. **Decisão:** Exija que a IA avalie trade-offs:
   ```bash
   architect "Migrar Redux para Signals"
   ```
   *(Irá gerar um arquivo oficial `ADR-001.md` com a decisão documentada).*
2. **Planejamento:** Faça a IA quebrar isso em checklist:
   ```bash
   plan ADR-001
   ```
   *(Irá gerar `PLAN-001.md`, listando os `## Sources` utilizados e as `TASK-XXX`).*
3. **Execução Estrita:** Coloque o pedreiro para trabalhar:
   ```bash
   dev .ai/plans/PLAN-001.md
   ```
   *(A IA é proibida de improvisar. Ela fará os códigos e escreverá o Evidence Log no plano).*
4. **Limpeza e Auditoria:**
   ```bash
   review               # Tira os console.logs e sujeiras
   code-review src/     # Garante que não feriu a constituição e passa na Maturidade Mínima
   ```

---

### Cenário 3: Mudança Simples ou Funcionalidade Local
*Demanda menor: "Criar uma tela de cadastro igual à de clientes", "Adicionar novo formulário", "Ajustar uma regra de negócio pequena".*
1. **Design Tático:** (Opcional, se precisar visualizar o escopo primeiro):
   ```bash
   design "Tela de fornecedores"
   ```
2. **Planejamento Direto:** Pule o ADR e vá direto para o checklist:
   ```bash
   plan "Criar tela de fornecedores baseada na tela de clientes"
   ```
3. **Execução Estrita:**
   ```bash
   dev .ai/plans/PLAN-002.md
   ```
4. **Auditoria:**
   ```bash
   review
   code-review src/fornecedores/
   ```

---

### Cenário 4: Padronizar Código Legado ou Terceirizado
*Você herdou uma pasta horrível ou outro desenvolvedor fez fora do padrão, e você quer alinhar com o Golden Path.*
1. **Auditoria Passiva:** Descubra o quão fora do padrão está:
   ```bash
   standardize src/customer --audit
   ```
2. **Correção Direta:** Autorize a IA a converter o código para os padrões do `.ai/examples/`:
   ```bash
   standardize src/customer --fix
   ```
   *(Se preferir passo a passo, use `--plan` em vez de `--fix` para a IA te entregar um check-list de correção manual).*

---

### Cenário 5: Investigação de Legado e Erros Críticos
*Você recebeu um ticket sobre uma área que ninguém conhece ou um bug que está parando o servidor.*
1. **Para Entender o Legado (Engenharia Reversa):**
   ```bash
   discover "geração de fatura" --deep
   ```
   *(A IA fará engenharia reversa do banco de dados, fluxo, regras de negócio e APIs sem quebrar nada e explicará para você).*
2. **Para Caçar o Bug (Root Cause Analysis):**
   ```bash
   debug
   ```
   *(No chat, passe o erro. A IA vai analisar o `project-map.md`, achar o Sintoma, a Evidência, criar uma Hipótese e sugerir a Causa Raiz EXATA sem te dar soluções de "gambiarra").*

---

## 🛡️ A Malha de Defesa (Para lembrar)

O comportamento rígido da IA durante o comando `dev` acontece porque ela é travada por três pilares inquebráveis:
1. **`project-rules.md` e `constitution.md`**: Regras globais de negócio e comportamento.
2. **`.ai/examples/`**: Os seus exemplos perfeitos. É a única base que o `dev` tem permissão de copiar para construir novas abstrações.
3. **Bloqueadores de Review**: Se a IA vazar um secret, usar `any` proibido ou burlar as regras de Clean Code injetadas no comando, o `code-review` vai reprovar impiedosamente a entrega, bloqueando a ida para produção.