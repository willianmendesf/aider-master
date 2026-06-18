# ==========================================
# LÓGICA CENTRAL DO AIDER (COMPARTILHADA)
# ==========================================

# --- HELPERS DE GERENCIAMENTO SEGURO DA PASTA .ai/ ---
# Garante que a estrutura base exista sem nunca apagar conteúdo
_init_ai_workspace() {
    mkdir -p .ai/rules
    mkdir -p .ai/plans/archive
    mkdir -p .ai/decisions
    mkdir -p .ai/examples
    mkdir -p .ai/knowledge
    mkdir -p .ai/tooling/catalog
    mkdir -p .ai/cache
}

_cleanup_ai_temps() {
    echo "🧹 Limpando artefatos temporários de IA..."
    rm -f ./.repomixignore
    rm -f .ai/.aider-*.txt
    rm -f .aider-draft-context*.txt # Legado
}
# ----------------------------------------------------

# Skills globais carregadas sempre como base
BASE_SKILLS=(
    --read "$AIDER_GLOBAL_DIR/skills/anti-hallucination.md"
    --read "$AIDER_GLOBAL_DIR/skills/clean-code.md"
)

# Função Principal (Agent)
agent() {
    _init_ai_workspace

    local MODELO_DEFAULT="o3-mini"
    local MODELO=""

    # Lógica de seleção do modelo
    if [ -z "$1" ] || [ "$1" = "default" ]; then
        MODELO="$MODELO_DEFAULT"
        [ "$1" = "default" ] && shift
    else
        MODELO="$1"
        shift
    fi

    # --- DETECÇÃO AUTOMÁTICA DE BUNDLE NA RAIZ ---
    local EXTRA_FLAGS=()
    
    if [ -f "./bundle-output.txt" ]; then
        echo "📦 Bundle detectado automaticamente: ./bundle-output.txt."
        # A integração RAG agora consome automaticamente os dados do bootstrap.
    fi
    # ----------------------------------------------

    echo "🌱 Modo Econômico"
    echo "🤖 Iniciado com modelo: $MODELO"

    # --- INJEÇÃO DE REGRAS DE PROJETO ---
    # Injeta a Constituição e Regras se existirem
    [ -f ".ai/constitution.md" ] && EXTRA_FLAGS+=(--read ".ai/constitution.md")
    [ -f ".ai/rules/project-rules.md" ] && EXTRA_FLAGS+=(--read ".ai/rules/project-rules.md")
    [ -f ".ai/rules/architecture.md" ] && EXTRA_FLAGS+=(--read ".ai/rules/architecture.md")
    [ -f ".ai/rules/coding.md" ] && EXTRA_FLAGS+=(--read ".ai/rules/coding.md")
    # Para retrocompatibilidade com legado
    [ -f "./.project-rules.md" ] && EXTRA_FLAGS+=(--read "./.project-rules.md")
    # ----------------------------------------------

    mkdir -p .aider
    touch .aider/.aider.root.md

    # Execução dinâmica baseada nas variáveis do ambiente ativo
    PYTHONUTF8=1 OPENAI_API_KEY="$MINHA_CHAVE_API" \
    command aider --config "$AIDER_GLOBAL_DIR/$AIDER_CONFIG_FILE" \
                  --openai-api-base "$MEU_PROVEDOR_URL" \
                  --model "openai/$MODELO" \
                  --no-browser \
                  --no-auto-commits \
                  --no-dirty-commits \
                  --input-history-file ".aider/.aider.input.history" \
                  --chat-history-file ".aider/.aider.chat.history.md" \
                  --llm-history-file ".aider/.aider.llm.history" \
                  --aiderignore "$AIDER_GLOBAL_DIR/ignores/.aiignore" \
                  --read ".aider/.aider.root.md" \
                  "${EXTRA_FLAGS[@]}" \
                  "$@"
}

# ==========================================
# AIDER OS: Comandos de Design e Rastreabilidade
# ==========================================

# Comando para Análise e Decisão Arquitetural (Gera ADR)
architect() {
    if [ -z "$1" ] || [[ "$1" == -* ]]; then
        echo "❌ ERRO: Architect requer uma decisão arquitetural a ser analisada."
        echo "Exemplo: architect \"Migrar Context API para Redux\""
        return 1
    fi
    local DEMANDA="$1"
    shift

    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/architect.md"
    )

    # O repo-map nativo do Aider agora fornece o contexto de repositório automaticamente.
    echo "🏛️ Atuando como Arquiteto para gerar um ADR..."
    agent "$modelo" "${SKILLS[@]}" --message "Atue como Arquiteto. Demanda: $DEMANDA. Avalie as alternativas, decida os trade-offs e CRIE um arquivo sequencial na pasta .ai/decisions/. Não gere ou modifique NENHUM código fonte." "$@"
}

# Comando para Decisões Táticas Locais (Sem ADR)
design() {
    if [ -z "$1" ] || [[ "$1" == -* ]]; then
        echo "❌ ERRO: Design requer uma decisão tática a ser estruturada."
        echo "Exemplo: design \"Nova tela de consulta de boletos\""
        return 1
    fi
    local DEMANDA="$1"
    shift

    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/system-design.md"
    )

    # O repo-map nativo fornece o contexto automaticamente.

    echo "🏗️ Atuando como System Design (Decisão Tática local)..."
    agent "$modelo" "${SKILLS[@]}" --message "Demanda Tática: $DEMANDA. Use a skill System Design para apresentar uma proposta estrutural sem gerar código e sem gerar ADR." "$@"
}

# Comando para Fatiamento de Tarefas (Gera Plano Rastreável)
plan() {
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo "❌ ERRO: Uso: plan \"Sua demanda descritiva\" [--open] [--model <modelo>]"
        echo "Exemplo: plan \"Criar tela HelloWorld na pasta logged\""
        return 1
    fi
    local DEMANDA="$1"
    shift

    local modelo="default"
    local OPEN_AIDER=0
    local USE_FEATURE_CONTEXT=0
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --open) OPEN_AIDER=1 ;;
            --feature) USE_FEATURE_CONTEXT=1 ;;
            --model) 
                modelo="$2"
                shift ;;
            *) modelo="$1" ;;
        esac
        shift
    done

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/planner.md"
    )

    if [ "$USE_FEATURE_CONTEXT" -eq 1 ] && [ -s ".ai/cache/feature_context.md" ]; then
        echo "🔗 Contexto tático da feature detectado. Injetando no plano..."
        SKILLS+=(--read ".ai/cache/feature_context.md")
    else
        echo "🌐 Modo de Planejamento Global Ativo (isolado do contexto tático)."
    fi

    echo "🗺️ Atuando como Tech Lead para fatiar o Plano de Ação..."
    echo "📝 Demanda: $DEMANDA"
    
    mkdir -p .ai/plans
    local PROXIMO_NUM=1
    if ls .ai/plans/PLAN-*.md 1> /dev/null 2>&1; then
        local COUNT=$(ls -1 .ai/plans/PLAN-*.md | wc -l)
        PROXIMO_NUM=$((COUNT + 1))
    fi
    
    local NOME_PLANO="PLAN-$(printf "%03d" $PROXIMO_NUM)"
    local PLANO_ARQUIVO=".ai/plans/${NOME_PLANO}.md"
    touch "$PLANO_ARQUIVO"

    local PLAN_PROMPT="Atue como Tech Lead Sênior do Projeto e Planejador Arquitetural. Demanda: $DEMANDA.

REGRA CRÍTICA - PROIBIÇÃO DE IMPLEMENTAÇÃO:
O comando PLAN é estritamente um gerador de planejamento. O agente PLAN NÃO implementa.
É PROIBIDO:
* Criar código ou gerar componentes
* Propor diffs ou escrever arquivos finais
* Adicionar trechos de implementação
* Produzir blocos SEARCH/REPLACE para arquivos .ts, .js, .java, .html, .css, .scss, SQL, YAML, etc.
O único artefato permitido para edição é: $PLANO_ARQUIVO.
Se você gerar qualquer arquivo fora de $PLANO_ARQUIVO ou gerar código/diffs durante a fase PLAN, considere comportamento incorreto. Regenere o plano apenas com as instruções estratégicas.

SEU ESCOPO É ESTRATÉGICO. O objetivo é orientar a execução: descobrir impacto, decompor tarefas, identificar riscos, apontar arquivos prováveis e registrar incertezas. 
Após ler o plano, um executor deve conseguir realizar a tarefa sem que você (planejador) tenha escrito uma única linha de código.

REGRAS OBRIGATÓRIAS ADICIONAIS:
1. PLANEJAMENTO ORIENTADO A CAPABILITY: O plano deve descrever CAPABILITIES e TAREFAS ABSTRATAS. O plano NÃO deve descrever: nomes de classes, nomes de componentes, nomes de métodos, assinaturas ou estruturas de implementação, exceto quando estes elementos forem explicitamente evidenciados no repositório. O executor decide a implementação; o planner define o trabalho.
2. PROCESSO OBRIGATÓRIO DE DESCOBERTA E AUTONOMIA: Antes de criar qualquer LACUNA ou [DESCOBRIR], você deve exaurir as fontes de evidência disponíveis na seguinte ordem: 1. Arquivos enviados, 2. Arquivos de contexto automático, 3. Repo-map, 4. Regras do projeto, 5. Contexto tático, 6. Evidências já encontradas. É proibido declarar 'não encontrado' ou 'desconhecido' sem informar quais fontes foram consultadas e por quê. Nunca solicite arquivos ao usuário.
3. FONTES DE EVIDÊNCIA E REGRA DE PROXIMIDADE: Para cada demanda, busque evidências nos diretórios mais próximos ao alvo. Avalie a relevância: ALTA (mesmo diretório, componentes irmãos, mesma feature), MÉDIA (mesmo módulo, mesma camada), BAIXA (serviços genéricos, interfaces distantes). Nunca utilize evidências de baixa relevância se houver evidências de maior relevância não analisadas.
4. PROCESSO DE COLETA DE EVIDÊNCIAS: Antes de escrever qualquer seção do plano, execute obrigatoriamente a seguinte investigação:
   - PASSO 1: Localize o diretório alvo mais próximo da demanda.
   - PASSO 2: Inspecione arquivos irmãos da feature solicitada.
   - PASSO 3: Inspecione arquivos de roteamento, registro, bootstrap ou composição relacionados ao alvo.
   - PASSO 4: Colete TODAS as evidências concretas encontradas. O Planner NÃO PODE declarar trechos de código ou linhas. O Planner deve listar apenas os caminhos dos arquivos observados. Se nenhuma evidência direta existir: registre a lacuna, NÃO invente arquivos.
5. REGRA DE EVIDÊNCIA FORTE E PROIBIÇÃO DE INVENÇÃO: É expressamente proibido citar qualquer arquivo que não tenha sido explicitamente observado por você (ferramenta) durante a sessão. Se nenhum arquivo for encontrado, NUNCA gere hipótese de nome de arquivo, gere apenas EVIDÊNCIA NÃO ENCONTRADA e uma LACUNA. É PROIBIDO o Planner aprovar seu próprio plano. Nunca pontue ou classifique o status do plano.
6. REGRA DE PAPEL (FOCO EM ENGENHARIA, NÃO EM GESTÃO): O Planejador mapeia a engenharia, não codifica. Você PODE usar verbos técnicos para descrever O QUE será construído (ex: 'Criar capability de página autenticada', 'Integrar nova rota', 'Apontar arquivos prováveis'), mas É PROIBIDO instruir COMO implementar (não descreva assinaturas, não dite conteúdo interno, não sugira diffs). O plano deve ser detalhado e técnico, guiando o desenvolvedor sem prender suas decisões de código.
7. LINGUAGEM SECA E DIRETA: Não expanda com benefícios ou contextos organizacionais (equipe, aprovações).
8. CRITÉRIOS DE ACEITE TESTÁVEIS: Use fatos concretos ('rota acessível', 'interface carregada sem erros').
9. PROPORCIONALIDADE: Demandas simples exigem checklist curto.

Analise o repositório, o repo-map e o contexto injetado (se ativado).
Edite o arquivo $PLANO_ARQUIVO utilizando ESTRITAMENTE o seguinte formato Markdown:

# $NOME_PLANO

**Objetivo:**
<Descrição objetiva da demanda recebida. Não adicionar benefícios, justificativas ou motivações não evidenciadas.>

## 1. Conhecimento e Evidências

**Evidências Observadas:**
EVID-001
- Arquivo: <Caminho absoluto do código fonte. PROIBIDO usar project-rules.md, repo-map, diretórios, utilitários, ou shared/>
- Necessário validar

**Status:**
NÃO VALIDADO (ou EVIDÊNCIA NÃO ENCONTRADA)

**Hipóteses de Trabalho:**
HIP-001
- Descrição: <O que você acha que existe ou como funciona>
- Motivo: <Por que você acha isso>
- Confiança: <Ex: 40%>

## 2. Lacunas de Conhecimento (Incertezas)

LACUNA-001
- Pergunta: <O que precisa ser descoberto? Ex: Como novas telas são registradas na área logged?>
- Fontes consultadas: <Listar as fontes exauridas. Ex: repo-map, src/app/pages/...>
- Resultado: <O que foi/não foi encontrado>
- Motivo da lacuna: <Por que não foi possível afirmar a evidência>
- Próxima ação: <O que o executor deve fazer na fase de descoberta para resolver a lacuna>

## 3. Decisões Arquiteturais

<Somente criar esta seção se existirem pelo menos 3 evidências diretas e concretas. Caso contrário, escreva: 'Nenhuma decisão arquitetural pôde ser emitida com segurança.'>

DECISÃO-001
- O Que: <Decisão tomada com base exclusiva em evidências reais>
- Evidência Base: <EVID-001>
- Motivo: <Justificativa técnica>
- Confiança: <%>

## 4. Tríade de Gestão
- **Complexidade:** <BAIXA | MÉDIA | ALTA | EXTREMA>
- **Estimativa:** <XS (15-30m) | S (1-2h) | M (Meio dia) | L (1-2 dias) | XL (Semana)>
- **Risco:** <BAIXO | MÉDIO | ALTO>
- **Impacto Esperado:** <Áreas afetadas>

## 5. Arquivos Relevantes
[EVIDENCIADO] <Arquivo base que servirá de referência (Golden Path)>
[DESCOBRIR] <Arquivo que o dev precisa mapear na fase de descoberta>

## 6. Plano de Execução

**Fase 1 — Descoberta:**
[ ] <Tarefa abstrata para o executor resolver LACUNA-001>

**Fase 2 — Construção:**
[ ] <Tarefa técnica orientada a Capability (ex: Criar nova tela na área logged, Integrar mecanismo de navegação). Liste os 'Arquivos prováveis' abaixo da tarefa. NÃO forneça implementação interna.>

**Fase 3 — Validação:**
[ ] <Validar aderência aos padrões e requisitos>

**Critérios de Aceite:**
[ ] <O que garante que a tarefa está pronta de forma verificável>

"

    # Gera o plano de forma autônoma sem prender o terminal do usuário em chat iterativo
    agent "$modelo" "${SKILLS[@]}" \
        --file "$PLANO_ARQUIVO" \
        --yes \
        --message "$PLAN_PROMPT"

    # Validação de Infraestrutura
    if [ ! -s "$PLANO_ARQUIVO" ]; then
        echo "❌ ERRO: O plano gerado está vazio. O modelo falhou em formatar o bloco de texto."
        rm -f "$PLANO_ARQUIVO"
        return 1
    fi

    if ! grep -q "## 1. Conhecimento e Evidências" "$PLANO_ARQUIVO"; then
        echo "❌ ERRO: O plano não possui a estrutura mínima esperada (Possível alucinação do LLM)."
        return 1
    fi

    echo "✅ Plano gerado com sucesso em: $PLANO_ARQUIVO"

    if [ "$OPEN_AIDER" -eq 1 ]; then
        echo "🚀 Abrindo Aider para verificação e execução do plano..."
        agent "$modelo" "${BASE_SKILLS[@]}" --read "$PLANO_ARQUIVO" --message "O plano $NOME_PLANO foi gerado. Antes de codificar, valide as evidências (VERIFY)."
    fi
}

# Comando de Auditoria (VERIFY)
verify() {
    # Uso: verify <caminho_do_plano>
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo "Uso: verify <Caminho do Plano .ai/plans/PLAN-XXX.md>"
        return 1
    fi
    local PLANO="$1"
    
    if [ ! -f "$PLANO" ]; then
        echo "❌ ERRO: O plano '$PLANO' não foi encontrado."
        return 1
    fi

    echo "🔎 Iniciando VERIFY (BASH) para auditoria determinística do plano $PLANO..."

    # Remover certificação anterior se houver
    sed -i '/## 8. Certificação de Auditoria/,$d' "$PLANO"

    local REPROVADO=0
    # Extrai o caminho após "- Arquivo: "
    local ARQUIVOS_EXTRAIDOS=$(grep -E "^- Arquivo: " "$PLANO" | sed 's/^- Arquivo: //')

    echo -e "\n## 8. Certificação de Auditoria" >> "$PLANO"

    if [ -z "$ARQUIVOS_EXTRAIDOS" ]; then
        echo "- **VERIFY:** REPROVADO" >> "$PLANO"
        echo "- **Motivos:** Nenhuma evidência de arquivo encontrada no plano." >> "$PLANO"
        echo "❌ VERIFY REPROVADO: Nenhum arquivo listado para auditoria."
        return 1
    fi

    local MOTIVOS=""
    while IFS= read -r arquivo; do
        arquivo=$(echo "$arquivo" | tr -d '\r')
        if [ -n "$arquivo" ]; then
            if [ ! -e "$arquivo" ]; then
                REPROVADO=1
                MOTIVOS="${MOTIVOS}\n- Arquivo inexistente: $arquivo"
                echo "   ❌ Falha: $arquivo (não existe)"
            else
                echo "   ✅ OK: $arquivo"
            fi
        fi
    done <<< "$ARQUIVOS_EXTRAIDOS"

    if [ $REPROVADO -eq 1 ]; then
        echo "- **VERIFY:** REPROVADO" >> "$PLANO"
        echo -e "- **Motivos:** $MOTIVOS" >> "$PLANO"
        echo "❌ VERIFY REPROVADO. Consulte o plano para os motivos."
        return 1
    else
        echo "- **VERIFY:** APROVADO" >> "$PLANO"
        echo "- **Motivos:** Arquivos listados existem e foram verificados fisicamente." >> "$PLANO"
        echo "✅ VERIFY APROVADO."
    fi
}

# ==========================================
# AIDER OS: Comandos de Execução
# ==========================================

# Comando para Execução Restrita (Codificação Pura)
dev() {
    # Uso: dev <caminho_do_plano> [--model <id>]
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo "Uso: dev <Caminho do Plano .ai/plans/PLAN-XXX.md> [--model <modelo>]"
        echo "Exemplo: dev .ai/plans/PLAN-001.md"
        return 1
    fi
    local PLANO="$1"
    shift

    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
    fi

    # Tenta resolver o plano: primeiro como caminho absoluto/relativo ao CWD,
    # depois a partir da raiz do repositório Git (suporte a monorepo/subpastas)
    if [ ! -f "$PLANO" ]; then
        local GIT_ROOT
        GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
        if [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/$PLANO" ]; then
            PLANO="$GIT_ROOT/$PLANO"
        else
            echo "❌ ERRO: O plano '$PLANO' não foi encontrado."
            echo "   Procurei em: $(pwd)/$PLANO"
            [ -n "$GIT_ROOT" ] && echo "   E em: $GIT_ROOT/$PLANO"
            echo "💡 Use o comando 'plan' para gerar as tarefas antes de codificar."
            return 1
        fi
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/dev-golden-path.md"
        --read "$AIDER_GLOBAL_DIR/skills/angular-patterns.md"
    )

    echo "🔨 Iniciando Motor de Execução Seguro baseado em: $PLANO..."
    
    # Checagem primária em shell antes de chamar a IA
    if ! grep -q "VERIFY: APROVADO" "$PLANO"; then
        echo "❌ ERRO: O plano '$PLANO' não possui a certificação 'VERIFY: APROVADO'."
        echo "   Execute o comando 'verify $PLANO' para auditar o plano antes do dev."
        return 1
    fi

    agent "$modelo" "${SKILLS[@]}" --file "$PLANO" --message "Atue como Desenvolvedor (Dev Golden Path). Leia o plano fornecido. O plano pode conter informações falsas. Assuma inicialmente que TODA evidência do plano é suspeita. ANTES DE IMPLEMENTAR: 1. Verifique a existência e o conteúdo dos arquivos usando suas ferramentas de leitura. 2. Verifique a tecnologia. 3. Verifique os padrões do projeto. Somente você, o DEV, pode produzir evidência concreta. Se qualquer evidência for falsa: PARE, não codifique, e atualize o plano com STATUS: BLOQUEADO (Motivo: Evidência não encontrada). CASO ESTEJA TUDO OK: execute EXATAMENTE as tarefas designadas. NUNCA invente novos padrões arquiteturais, procure por referências no código existente. Atualize o arquivo do plano marcando as tarefas concluídas com [x]. Para as tarefas de Descoberta (Fase 1), você OBRIGATORIAMENTE deve escrever a '## Resultado da Descoberta' contendo 'Arquivo', 'Linhas' e 'Evidência concreta'. Assine suas criações com a rastreabilidade do PLANO/ADR." "$@"
}

# Modo Ask
ask() {
    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi
    agent "$modelo" "${BASE_SKILLS[@]}" --chat-mode ask "$@"
}

# ==========================================
# AIDER OS: Comandos de Qualidade e Investigação
# ==========================================

# Comando para Debug Avançado (Root Cause Analysis)
debug() {
    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/root-cause-analysis.md"
        --read "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
    )

    # O repo-map nativo fornece o contexto automaticamente.

    echo "🐛 Iniciando Investigação de Causa Raiz (Debug)..."
    agent "$modelo" "${SKILLS[@]}" --message "Atue como Investigador Sênior (Root Cause Analysis). Analise o erro ou problema relatado pelo usuário. Localize a raiz do problema cruzando com o contexto do projeto. NÃO sugira gambiarras, emita o relatório técnico e aponte o arquivo exato a ser corrigido." "$@"
}

# Comando para Tribunal de Código (Code Review)
# Uso: code-review <arquivo_ou_diretorio> [--model <id>]
code-review() {
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo "❌ ERRO: Uso: code-review <arquivo_ou_diretorio> [--model <modelo>]"
        echo "Exemplos:"
        echo "  code-review src/app/pages/logged/appointments/"
        echo "  code-review src/app/app.module.ts"
        return 1
    fi
    local ALVO="$1"
    shift

    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
    fi

    # --- Validação do alvo ---
    if [ ! -e "$ALVO" ]; then
        echo "❌ ERRO: O alvo '$ALVO' não existe como arquivo ou diretório."
        return 1
    fi

    # --- Montagem de evidência ---
    local EVIDENCE_ARGS=()

    if [ -f "$ALVO" ]; then
        # Arquivo único: passa diretamente como --file
        echo "📄 Arquivo individual selecionado para Code Review: $ALVO"
        EVIDENCE_ARGS+=(--file "$ALVO")
    elif [ -d "$ALVO" ]; then
        # Diretório: gera bundle repomix com o conteúdo para garantir evidência concreta
        _init_ai_workspace
        local BUNDLE_FILE=".ai/cache/code-review-bundle.txt"
        echo "📂 Diretório detectado. Gerando bundle de evidência: $BUNDLE_FILE"
        if command -v repomix &>/dev/null; then
            repomix "$ALVO" --output "$BUNDLE_FILE" --quiet 2>/dev/null \
                || repomix "$ALVO" --output "$BUNDLE_FILE" 2>/dev/null
        else
            # Fallback: concatenar arquivos de código relevantes
            find "$ALVO" -type f \(
                -name "*.ts" -o -name "*.js" -o -name "*.java" \
                -o -name "*.py" -o -name "*.cs" -o -name "*.kt"
            \) -not -path "*/node_modules/*" -not -path "*/target/*" \
               -not -path "*/dist/*" -not -path "*/.git/*" \
            | head -n 60 \
            | xargs -I{} sh -c 'echo "\n=== {} ==="; cat "{}"' \
            > "$BUNDLE_FILE" 2>/dev/null
        fi

        if [ ! -s "$BUNDLE_FILE" ]; then
            echo "❌ ERRO: Não foi possível gerar evidência do diretório '$ALVO'. Verifique se há arquivos de código."
            return 1
        fi

        local LINE_COUNT
        LINE_COUNT=$(wc -l < "$BUNDLE_FILE")
        echo "✅ Bundle gerado com $LINE_COUNT linhas de evidência."
        EVIDENCE_ARGS+=(--read "$BUNDLE_FILE")
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/security-audit.md"
    )

    # O repo-map nativo fornece o contexto de forma automática.
    if [ -s ".ai/decisions/ARCHITECTURE-BASELINE.md" ]; then
        SKILLS+=(--read ".ai/decisions/ARCHITECTURE-BASELINE.md")
    fi

    # Regras do projeto corrente
    [ -f ".ai/constitution.md" ] && SKILLS+=(--read ".ai/constitution.md")
    [ -f ".ai/rules/project-rules.md" ] && SKILLS+=(--read ".ai/rules/project-rules.md")
    [ -f ".ai/rules/coding.md" ] && SKILLS+=(--read ".ai/rules/coding.md")
    [ -f ".ai/rules/architecture.md" ] && SKILLS+=(--read ".ai/rules/architecture.md")
    [ -f ".ai/rules/testing.md" ] && SKILLS+=(--read ".ai/rules/testing.md")

    echo "⚖️ Iniciando Tribunal de Código (Code Review) em: $ALVO..."
    agent "$modelo" "${SKILLS[@]}" "${EVIDENCE_ARGS[@]}" \
        --message "Faça o Code Review dos arquivos/código do alvo '$ALVO' disponibilizados como contexto. Você DEVE analisar o conteúdo concreto fornecido — NÃO emita laudo genérico ou de aprovação sem evidência. Avalie: qualidade, segurança, padrões arquiteturais, acoplamento e manutenibilidade. Emita o laudo final com SCORE (0-100) e cite linhas específicas com problemas ou elogios." "$@"
}

# Comando para Revisão Operacional (Code Review Funcional)
review() {
    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
    elif [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/pr-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
        --read "$AIDER_GLOBAL_DIR/skills/security-audit.md"
        --read "$AIDER_GLOBAL_DIR/skills/angular-patterns.md"
    )

    echo "🔎 Iniciando Revisão Operacional (PR / Micro-Gerenciamento)..."
    agent "$modelo" "${SKILLS[@]}" --message "Atue como Revisor Operacional de PR. Seu foco é sujeira de código, variáveis não usadas, logs perdidos e erros sintáticos evidentes. Emita o laudo (APROVADO, REPROVADO, RESSALVAS) e liste as linhas exatas onde a sujeira/bug se encontra." "$@"
}

# Modo Ask específico para refatoração
ask-refactor() {
    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        --read "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/enterprise-refactor.md"
        --read "$AIDER_GLOBAL_DIR/skills/test-generator.md"
        --read "$AIDER_GLOBAL_DIR/skills/pr-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/angular-patterns.md"
    )

    agent "$modelo" "${SKILLS[@]}" "$@"
}

# Modo Ask específico para migração
ask-migration() {
    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/analysis.md"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        --read "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/enterprise-refactor.md"
        --read "$AIDER_GLOBAL_DIR/skills/test-generator.md"
    )

    agent "$modelo" "${SKILLS[@]}" "$@"
}

# Modo Ask específico para empresas
ask-enterprise() {
    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        --read "$AIDER_GLOBAL_DIR/skills/analysis.md"
        --read "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/enterprise-refactor.md"
        --read "$AIDER_GLOBAL_DIR/skills/root-cause-analysis.md"
        --read "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
        --read "$AIDER_GLOBAL_DIR/skills/security-audit.md"
        --read "$AIDER_GLOBAL_DIR/skills/performance-audit.md"
        --read "$AIDER_GLOBAL_DIR/skills/test-generator.md"
        --read "$AIDER_GLOBAL_DIR/skills/pr-review.md"
    )

    agent "$modelo" "${SKILLS[@]}" "$@"
}

# Modo Study (Ask sem Git e com as sub-skills base)
study() {
    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi
    agent "$modelo" "${BASE_SKILLS[@]}" --chat-mode ask --no-git "$@"
}

bundle() {
    local OUTPUT_FILE="${1:-bundle-output.txt}"
    shift 1 2>/dev/null

    echo "🚀 Puxando Filtros Globais (.aiignore)..."
    cp "$AIDER_GLOBAL_DIR/ignores/.aiignore" ./.repomixignore 2>/dev/null
    
    echo "📦 Rodando compactação do projeto -> Gerando: $OUTPUT_FILE..."
    if [ "$#" -gt 0 ]; then
        repomix "$@" --output "$OUTPUT_FILE"
    else
        repomix --output "$OUTPUT_FILE"
    fi
    
    echo "✅ Concluído! O arquivo '$OUTPUT_FILE' foi gerado com sucesso."
}

# ==========================================
# AIDER OS: Comandos de Engenharia Reversa e Padrões
# ==========================================

# Comando para Engenharia Reversa de Legado
discover() {
    python3 "$AIDER_GLOBAL_DIR/scripts/query.py" discover "$@"
}

where() {
    python3 "$AIDER_GLOBAL_DIR/scripts/query.py" where "$@"
}

impact() {
    python3 "$AIDER_GLOBAL_DIR/scripts/query.py" impact "$@"
}

feature() {
    if [ -z "$1" ] || [[ "$1" == -* ]]; then
        echo "❌ ERRO: Uso: feature <Nome> [--ai | --report]"
        return 1
    fi
    local ALVO="$1"
    shift
    
    local USE_AI=0
    local OPEN_AIDER=0
    local modelo="default"
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --ai|--report) USE_AI=1 ;;
            --open) OPEN_AIDER=1 ;;
            *) modelo="$1" ;;
        esac
        shift
    done
    
    echo "🧠 Montando contexto cirúrgico para a feature: $ALVO..."
    python3 "$AIDER_GLOBAL_DIR/scripts/query.py" feature "$ALVO" > .ai/cache/feature_context.md
    
    if grep -q "⚠️ Nenhuma entidade" .ai/cache/feature_context.md; then
        cat .ai/cache/feature_context.md
        return 1
    fi
    
    if [ "$USE_AI" -eq 1 ]; then
        local SKILLS=("${BASE_SKILLS[@]}")
        echo "🤖 Gerando relatório explicativo da feature via IA..."
        agent "$modelo" "${SKILLS[@]}" --read ".ai/cache/feature_context.md" --message "Aja como Arquiteto de Software. Usando APENAS o contexto fornecido em .ai/cache/feature_context.md, gere um relatório detalhado da Feature '$ALVO', navegando no grafo para explicar o fluxo e o propósito. Formate em Markdown claro."
    else
        cat .ai/cache/feature_context.md
    fi

    if [ "$OPEN_AIDER" -eq 1 ]; then
        if [ -s ".ai/cache/feature_files.txt" ]; then
            echo "🚀 Abrindo Aider com contexto focado e disparando onboarding automático..."
            local ONBOARDING_MSG="Analise a feature carregada. Explique:
1. Objetivo da feature
2. Fluxo principal
3. APIs consumidas
4. Models utilizados
5. Arquivos mais importantes
6. Pontos de extensão
7. Riscos de alteração

Não escreva código."
            agent "$modelo" "${BASE_SKILLS[@]}" $(cat .ai/cache/feature_files.txt) --message "$ONBOARDING_MSG"
        else
            echo "⚠️ Nenhum arquivo encontrado para abrir no Aider."
        fi
    fi
}

# Comando para Convergir Código para o Golden Path
# Uso: standardize <arquivo_ou_diretorio> [--audit | --plan | --fix] [--model <id>]
standardize() {
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo "❌ ERRO: Uso: standardize <alvo> [--audit | --plan | --fix] [--model <modelo>]"
        echo "Exemplos:"
        echo "  standardize src/app/pages/login.component.ts --audit"
        echo "  standardize src/app/pages/logged/appointments/ --plan"
        return 1
    fi
    local ALVO="$1"
    shift

    # --- Validação de existência ANTES de qualquer coisa ---
    if [ ! -e "$ALVO" ]; then
        echo "❌ ERRO: O alvo '$ALVO' não existe como arquivo ou diretório."
        echo "💡 Forneça o caminho real do componente (ex: src/app/login.component.ts ou src/app/pages/login/)."
        return 1
    fi

    local FLAG="--audit"
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --audit|--plan|--fix) FLAG="$1"; shift ;;
            --model)
                if [ -n "$2" ]; then
                    local modelo="$2"; shift 2
                else
                    echo "❌ ERRO: --model requer um valor."; return 1
                fi
                ;;
            *) break ;;
        esac
    done
    local modelo="${modelo:-default}"

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/standardizer.md"
    )

    # Injeta exemplos do Golden Path para referência (usa --read, nunca --file)
    if [ -d ".ai/examples" ]; then
        while IFS= read -r f; do
            SKILLS+=(--read "$f")
        done < <(find .ai/examples -type f \( -name "*.md" -o -name "*.ts" -o -name "*.js" \))
    fi

    # --- Monta os argumentos de contexto de acordo com o tipo do alvo ---
    local CONTEXT_ARGS=()
    if [ -f "$ALVO" ]; then
        # Arquivo único: pode ser editado diretamente com --fix
        if [ "$FLAG" == "--fix" ]; then
            CONTEXT_ARGS=(--file "$ALVO")
        else
            CONTEXT_ARGS=(--read "$ALVO")
        fi
    elif [ -d "$ALVO" ]; then
        # Diretório: nunca usa --file diretamente num dir. Gera bundle para leitura.
        _init_ai_workspace
        local BUNDLE_FILE=".ai/cache/standardize-bundle.txt"
        echo "📂 Diretório detectado. Gerando snapshot do código: $BUNDLE_FILE"
        find "$ALVO" -type f \( \
            -name "*.ts" -o -name "*.js" -o -name "*.java" \
            -o -name "*.py" -o -name "*.cs" -o -name "*.kt" \
        \) -not -path "*/node_modules/*" -not -path "*/target/*" \
           -not -path "*/dist/*" -not -path "*/.git/*" \
        | head -n 60 \
        | while IFS= read -r srcfile; do
            echo "\n=== $srcfile ==="
            cat "$srcfile"
        done > "$BUNDLE_FILE" 2>/dev/null

        if [ ! -s "$BUNDLE_FILE" ]; then
            echo "❌ ERRO: Nenhum arquivo de código encontrado em '$ALVO'."
            return 1
        fi
        echo "✅ Bundle gerado ($(wc -l < "$BUNDLE_FILE") linhas)."
        CONTEXT_ARGS=(--read "$BUNDLE_FILE")
        if [ "$FLAG" == "--fix" ]; then
            echo "⚠️  AVISO: --fix em diretório adiciona os arquivos como editáveis ao Aider."
            while IFS= read -r srcfile; do
                CONTEXT_ARGS+=(--file "$srcfile")
            done < <(find "$ALVO" -type f \( \
                -name "*.ts" -o -name "*.js" -o -name "*.java" \
                -o -name "*.py" -o -name "*.cs" -o -name "*.kt" \
            \) -not -path "*/node_modules/*" -not -path "*/target/*" \
               -not -path "*/dist/*" -not -path "*/.git/*" | head -n 30)
        fi
    fi

    local MENSAGEM="Atue como Standardizer."
    if [ "$FLAG" == "--audit" ]; then
        MENSAGEM="$MENSAGEM Analise o código do alvo '$ALVO' e liste APENAS as divergências encontradas contra o Golden Path e regras de projeto. NÃO altere o código e não gere planos."
    elif [ "$FLAG" == "--plan" ]; then
        MENSAGEM="$MENSAGEM Analise o código do alvo '$ALVO', encontre as divergências e CRIE um PLAN-XXX.md na pasta .ai/plans/ com as tarefas rastreáveis TASK-XXX. Não altere o código fonte."
    elif [ "$FLAG" == "--fix" ]; then
        MENSAGEM="$MENSAGEM Analise e EXECUTE as adequações no código do alvo '$ALVO' para convergir estritamente aos padrões do Golden Path."
    fi

    echo "📏 Iniciando Padronização em $ALVO (Modo: $FLAG)..."
    agent "$modelo" "${SKILLS[@]}" "${CONTEXT_ARGS[@]}" --message "$MENSAGEM" "$@"
}

# brain-index foi removido. A integração MCP agora lê diretamente de .ai/knowledge.

# Modo Extrator de Regras (Draft Rules)
draft-rules() {
    local modelo="default"
    local context_rows=4000
    local agent_args=()

    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"
        shift
    fi

    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --context-rows)
                context_rows="$2"
                shift 2
                ;;
            *)
                agent_args+=("$1")
                shift
                ;;
        esac
    done

    echo "========================================================"
    echo "🤖 MODO EXTRATOR DE REGRAS INICIADO (Linhas: $context_rows) mude isso usando: --context-rows <linhas>"
    echo "========================================================"
    
    _init_ai_workspace

    echo "📦 Lendo todos os seus arquivos para entender o padrão (isso pode levar uns segundos)..."
    
    bundle ".ai/.aider-draft-context-full.txt" > /dev/null 2>&1
    head -n "$context_rows" .ai/.aider-draft-context-full.txt > .ai/.aider-draft-context.txt

    local SKILLS=(
        --read "$AIDER_GLOBAL_DIR/skills/rules-extractor.md"
        --read ".ai/.aider-draft-context.txt"
    )

    local TMP_RULES=".ai/rules/project-rules.tmp.md"
    local FINAL_RULES=".ai/rules/project-rules.md"

    # Remove qualquer lixo temporário que tenha ficado antes de iniciar
    rm -f "$TMP_RULES"

    # Pede para a IA criar no arquivo temporário
    agent "$modelo" "${SKILLS[@]}" --subtree-only --message "Use o arquivo .ai/.aider-draft-context.txt fornecido para entender o padrão do projeto. Ele contém a árvore de pastas e uma amostra do código-fonte. CRIE o arquivo $TMP_RULES DE IMEDIATO. NUNCA faça perguntas." "$TMP_RULES" "${agent_args[@]}"

    # Só aplica a sobrescrita se a IA tiver gerado o arquivo temporário com sucesso
    if [ -f "$TMP_RULES" ]; then
        rm -f .project-rules.md # Limpa o sujo legado na raiz se houver
        mv "$TMP_RULES" "$FINAL_RULES"
        echo "✅ Sucesso! As novas regras foram gravadas em $FINAL_RULES."
    else
        echo "❌ Falha na geração das regras. O arquivo anterior foi preservado."
    fi
}

# ==========================================
# AIDER OS: Comandos de Governança e Contexto
# ==========================================

# Comando Bootstrap para Novos Projetos
# Combina ETL estrutural (Python/Compodoc/OpenAPI) + mapeamento LLM do contexto
bootstrap() {
    local modelo="default"
    if [ "$#" -gt 0 ] && [[ ! "$1" == -* ]]; then
        modelo="$1"; shift
    fi

    echo "🚀 Iniciando Bootstrap do Projeto (Aider OS v2.0)..."
    _init_ai_workspace

    # --- ETAPA 1: ETL estrutural (Compodoc/OpenAPI/Repomix → entities.json + graph.json) ---
    echo ""
    echo "📊 Etapa 1/2: Extração estrutural de entidades..."
    python3 "$AIDER_GLOBAL_DIR/scripts/knowledge_pipeline.py"

    echo "✅ Bootstrap Concluído! O banco de conhecimento local está pronto para comandos como where, impact e feature."
}

# Comando para atualizar o mapa de TODO o projeto
# Uso: sync-full [--model <modelo>]
sync-full() {
    echo "⚠️ AVISO: Comando legado; o repo-map nativo do Aider agora substitui este fluxo."
    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"; shift 2
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
    )

    _init_ai_workspace
    mkdir -p .ai/context

    # Pré-cria os arquivos para que o Aider não precise criar do zero
    # (evita conflito com aiignore que bloqueia criação de arquivos em .ai/)
    touch .ai/context/project-map.md .ai/context/domain-map.md

    # Gera bundle do projeto inteiro (herdando .aiignore para excluir lixo)
    echo "📦 Empacotando projeto para análise..."
    bundle ".ai/.aider-sync-context-full.txt" > /dev/null 2>&1

    # Otimização de tokens: primeiras 15000 linhas
    head -n 15000 ".ai/.aider-sync-context-full.txt" > ".ai/.aider-sync-context.txt"

    echo "🔄 Rodando Sync Full — atualizando project-map.md e domain-map.md..."
    agent "$modelo" "${SKILLS[@]}" \
        --read ".ai/.aider-sync-context.txt" \
        --file ".ai/context/project-map.md" \
        --file ".ai/context/domain-map.md" \
        --message "Leia o contexto fornecido (que contém a árvore de diretórios no topo e amostras de código) e atue como Context Builder. ATUALIZE IMEDIATAMENTE os arquivos .ai/context/project-map.md e .ai/context/domain-map.md com:
- Mapa completo de componentes, serviços, módulos, páginas e suas responsabilidades
- Endpoints de API identificados (URLs, métodos, parâmetros)
- Padrões e convenções do projeto
- Localização de models, guards, interceptors e componentes reutilizáveis
NUNCA crie regras de negócio, apenas mapeie o que existe. NUNCA modifique código fonte." "$@"

    _cleanup_ai_temps
    echo "✅ Sync Full concluído! .ai/context/project-map.md atualizado."
}

# Comando para atualizar o mapa de apenas um módulo específico (econômico)
# Uso: sync-module <caminho-do-modulo> [--model <modelo>]
sync-module() {
    echo "⚠️ AVISO: Comando legado; o repo-map nativo do Aider agora substitui este fluxo."
    if [ -z "$1" ] || [[ "$1" == --* ]]; then
        echo "❌ ERRO: Uso: sync-module <caminho-do-modulo> [--model <modelo>]"
        echo "Exemplo: sync-module src/app/pages/logged/appointments"
        return 1
    fi
    local MODULO="$1"
    shift

    # Valida existência do módulo
    if [ ! -e "$MODULO" ]; then
        echo "❌ ERRO: O módulo '$MODULO' não existe."
        return 1
    fi

    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"; shift 2
    fi

    _init_ai_workspace
    mkdir -p .ai/context

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
    )

    echo "🔄 Rodando Sync Module focado em: $MODULO..."
    # Pré-cria os mapas de contexto para que o Aider possa editar (não criar do zero)
    touch .ai/context/project-map.md .ai/context/domain-map.md
    # Passa os arquivos do módulo e os mapas de contexto como editáveis
    agent "$modelo" "${SKILLS[@]}" \
        --file "$MODULO" \
        --file ".ai/context/project-map.md" \
        --file ".ai/context/domain-map.md" \
        --message "Atue como Context Builder. Leia APENAS o módulo especificado ($MODULO). Atualize os arquivos .ai/context/project-map.md e .ai/context/domain-map.md INTEGRANDO o que você aprendeu deste módulo sem perder o que já existe sobre os outros módulos. NÃO faça perguntas. NÃO modifique código fonte." "$@"
}

# NOTA: A segunda definição de code-review() foi removida (duplicata que sobrescrevia a principal).
# A definição correta está acima (~linha 279) com suporte a bundle, diretórios e regras do projeto.