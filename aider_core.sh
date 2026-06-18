# ==========================================
# LÓGICA CENTRAL DO AIDER (COMPARTILHADA)
# ==========================================

_aider_python() {
    if [ -x "$AIDER_GLOBAL_DIR/venv/Scripts/python.exe" ]; then
        "$AIDER_GLOBAL_DIR/venv/Scripts/python.exe" "$@"
    elif command -v _aider_python >/dev/null 2>&1; then
        _aider_python "$@"
    else
        python "$@"
    fi
}

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

_load_prompt() {
  local file="$1"
  if [ ! -f "$file" ]; then
    echo "❌ Prompt não encontrado: $file"
    return 1
  fi
  cat "$file"
}

_next_plan_file() {
  mkdir -p .ai/plans .aider

  local count=1
  if ls .ai/plans/PLAN-*.md 1>/dev/null 2>&1; then
    count=$(( $(ls -1 .ai/plans/PLAN-*.md | wc -l) + 1 ))
  fi

  local name="PLAN-$(printf "%03d" "$count")"
  echo "$name"
}

_next_review_file() {
  mkdir -p .ai/reviews .aider

  local count=1
  if ls .ai/reviews/REVIEW-*.md 1>/dev/null 2>&1; then
    count=$(( $(ls -1 .ai/reviews/REVIEW-*.md | wc -l) + 1 ))
  fi

  local name="REVIEW-$(printf "%03d" "$count")"
  echo "$name"
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
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
        echo "❌ ERRO: Uso: plan \"Sua demanda descritiva\" [--feature <nome-feature>] [--new-screen] [--ref <tela-irma>] [--area <area>] [--doc <caminho-doc>] [--open] [--model <modelo>]"
        echo "Exemplos:"
        echo "  plan \"padronizar a tela segunda-via-de-boleto\" --feature segunda-via-de-boleto"
        echo "  plan \"criar nova tela segunda-via-boleto\" --new-screen --ref segunda-via-de-boleto --doc docs/segunda-via.md"
        return 1
    fi
    local DEMANDA="$1"
    shift

    local OPEN_AIDER=0
    local TARGET_FEATURE=""
    local TARGET_REF=""
    local TARGET_AREA=""
    local TARGET_DOC=""
    local IS_NEW_SCREEN=0
    
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --open) OPEN_AIDER=1 ;;
            --feature) 
                if [ -n "$2" ] && [[ "$2" != --* ]]; then
                    TARGET_FEATURE="$2"
                    shift
                fi
                ;;
            --new-screen) IS_NEW_SCREEN=1 ;;
            --ref) 
                if [ -n "$2" ] && [[ "$2" != --* ]]; then
                    TARGET_REF="$2"
                    shift
                fi
                ;;
            --area) 
                if [ -n "$2" ] && [[ "$2" != --* ]]; then
                    TARGET_AREA="$2"
                    shift
                fi
                ;;
            --doc) 
                if [ -n "$2" ] && [[ "$2" != --* ]]; then
                    TARGET_DOC="$2"
                    shift
                fi
                ;;
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

    if [ -n "$TARGET_FEATURE" ]; then
        echo "🔗 Montando contexto para a feature: $TARGET_FEATURE..."
        _aider_python "$AIDER_GLOBAL_DIR/scripts/query.py" feature "$TARGET_FEATURE" > .ai/cache/plan_context.md
        SKILLS+=(--read ".ai/cache/plan_context.md")
    elif [ "$IS_NEW_SCREEN" -eq 1 ] && [ -n "$TARGET_REF" ]; then
        echo "🔗 Montando contexto de referência para a tela: $TARGET_REF..."
        _aider_python "$AIDER_GLOBAL_DIR/scripts/query.py" feature "$TARGET_REF" > .ai/cache/plan_context.md
        SKILLS+=(--read ".ai/cache/plan_context.md")
    elif [ "$IS_NEW_SCREEN" -eq 1 ] && [ -n "$TARGET_AREA" ]; then
        echo "🔗 Buscando referências na área: $TARGET_AREA..."
        mkdir -p .ai/cache
        grep -i "/$TARGET_AREA/" .ai/knowledge/entities.json > .ai/cache/plan_context.md || echo "Nenhuma entidade encontrada para a área $TARGET_AREA" > .ai/cache/plan_context.md
        SKILLS+=(--read ".ai/cache/plan_context.md")
    else
        echo "🌐 Modo de Planejamento Global Ativo (isolado do contexto tático). Pode gerar BLOQUEIO se faltar contexto."
    fi

    if [ -n "$TARGET_DOC" ]; then
        if [ -f "$TARGET_DOC" ]; then
            echo "📄 Injetando documento de referência: $TARGET_DOC"
            SKILLS+=(--read "$TARGET_DOC")
        else
            echo "⚠️ Aviso: Documento $TARGET_DOC não encontrado. Ignorando."
        fi
    fi

    echo "🗺️ Atuando como Tech Lead para fatiar o Plano de Ação..."
    echo "📝 Demanda: $DEMANDA"
    
    mkdir -p .ai/plans
    
    local NOME_PLANO
    NOME_PLANO="$(_next_plan_file)"
    local TMP_PLANO=".aider/${NOME_PLANO}.md"
    local PLANO_ARQUIVO=".ai/plans/${NOME_PLANO}.md"

    # Preenche o esqueleto inicial
    cat > "$TMP_PLANO" <<EOF
# $NOME_PLANO

## 1. Conhecimento e Evidências
<!-- Preencha aqui as evidências encontradas -->

## 6. Plano de Execução
<!-- Preencha aqui as tarefas -->
EOF

    local PLAN_PROMPT
    PLAN_PROMPT="$(_load_prompt "$AIDER_GLOBAL_DIR/skills/prompts/plan.md")"
    PLAN_PROMPT="${PLAN_PROMPT//\{\{DEMANDA\}\}/$DEMANDA}"
    PLAN_PROMPT="${PLAN_PROMPT//\{\{PLANO_ARQUIVO\}\}/$TMP_PLANO}"
    PLAN_PROMPT="${PLAN_PROMPT//\{\{NOME_PLANO\}\}/$NOME_PLANO}"

    # Gera o plano de forma autônoma sem prender o terminal do usuário em chat iterativo
    agent "$modelo" "${SKILLS[@]}" \
        --file "$TMP_PLANO" \
        --yes \
        --message "$PLAN_PROMPT"

    # Validação de Infraestrutura
    if [ -s "$TMP_PLANO" ]; then
        mv "$TMP_PLANO" "$PLANO_ARQUIVO"
    else
        echo "❌ ERRO: O plano temporário gerado está vazio. O modelo falhou em formatar o bloco de texto."

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
    local ARQUIVOS_REFERENCIA=$(sed -n 's/^[[:space:]]*[-*]*[[:space:]]*\[REFERENCIA\][[:space:]]*//p' "$PLANO")
    local ARQUIVOS_EDITAR=$(sed -n 's/^[[:space:]]*[-*]*[[:space:]]*\[EDITAR\][[:space:]]*//p' "$PLANO")
    
    # Junta as duas listas removendo linhas vazias
    local ARQUIVOS_EXTRAIDOS=$(echo -e "${ARQUIVOS_REFERENCIA}\n${ARQUIVOS_EDITAR}" | grep -v '^[[:space:]]*$')

    echo -e "\n## 8. Certificação de Auditoria" >> "$PLANO"

    local MOTIVOS=""
    if echo "$ARQUIVOS_EXTRAIDOS" | grep -qE "<.*>|\(a descobrir\)|possível"; then
        REPROVADO=1
        MOTIVOS="${MOTIVOS}\n- Arquivo com placeholder inválido detectado."
        echo "   ❌ Falha: Placeholder detectado em arquivo a auditar"
    fi

    if [ -n "$ARQUIVOS_EXTRAIDOS" ]; then
        while IFS= read -r arquivo; do
            arquivo=$(echo "$arquivo" | tr -d '\r')
            if [ -n "$arquivo" ]; then
                if [ ! -f "$arquivo" ]; then
                    REPROVADO=1
                    MOTIVOS="${MOTIVOS}\n- Arquivo inexistente ou não regular: $arquivo"
                    echo "   ❌ Falha: $arquivo (não é arquivo válido)"
                else
                    echo "   ✅ OK: $arquivo"
                fi
            fi
        done <<< "$ARQUIVOS_EXTRAIDOS"
    else
        echo "   ⚠️ Nenhum arquivo de referência ou edição para validar."
    fi

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

    local ARQUIVOS_REFERENCIA=$(sed -n 's/^[[:space:]]*[-*]*[[:space:]]*\[REFERENCIA\][[:space:]]*//p' "$PLANO")
    local ARQUIVOS_EDITAR=$(sed -n 's/^[[:space:]]*[-*]*[[:space:]]*\[EDITAR\][[:space:]]*//p' "$PLANO")
    local ARQUIVOS_NOVOS=$(sed -n 's/^[[:space:]]*[-*]*[[:space:]]*\[NOVO\][[:space:]]*//p' "$PLANO")

    if [ -n "$ARQUIVOS_REFERENCIA" ]; then
        while IFS= read -r arquivo; do
            arquivo=$(echo "$arquivo" | tr -d '\r')
            if [ -n "$arquivo" ] && [ -f "$arquivo" ]; then
                SKILLS+=(--read "$arquivo")
            fi
        done <<< "$ARQUIVOS_REFERENCIA"
    fi

    if [ -n "$ARQUIVOS_EDITAR" ]; then
        while IFS= read -r arquivo; do
            arquivo=$(echo "$arquivo" | tr -d '\r')
            if [ -n "$arquivo" ] && [ -f "$arquivo" ]; then
                SKILLS+=(--file "$arquivo")
            fi
        done <<< "$ARQUIVOS_EDITAR"
    fi

    if [ -n "$ARQUIVOS_NOVOS" ]; then
        while IFS= read -r arquivo; do
            arquivo=$(echo "$arquivo" | tr -d '\r')
            if [ -n "$arquivo" ] && [[ "$arquivo" != *"<"* ]] && [[ "$arquivo" != *"("* ]]; then
                SKILLS+=(--file "$arquivo")
            fi
        done <<< "$ARQUIVOS_NOVOS"
    fi

    echo "🔨 Iniciando Motor de Execução Seguro baseado em: $PLANO..."
    
    # Checagem primária em shell antes de chamar a IA
    if ! grep -qE "VERIFY:\*\* APROVADO|VERIFY: APROVADO" "$PLANO"; then
        echo "❌ ERRO: O plano '$PLANO' não possui a certificação 'VERIFY: APROVADO'."
        echo "   Execute o comando 'verify $PLANO' para auditar o plano antes do dev."
        return 1
    fi

    local PROMPT
    PROMPT="$(_load_prompt "$AIDER_GLOBAL_DIR/skills/prompts/dev.md")"

    agent "$modelo" "${SKILLS[@]}" --file "$PLANO" --message "$PROMPT" "$@"
}

# Modo Ask
ask() {
    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
    fi
    agent "$modelo" "${BASE_SKILLS[@]}" --chat-mode ask "$@"
}

# ==========================================
# AIDER OS: Comandos de Qualidade e Investigação
# ==========================================

# Comando para Debug Avançado (Root Cause Analysis)
debug() {
    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
        --read "$AIDER_GLOBAL_DIR/skills/governance-audit.md"
        --read "$AIDER_GLOBAL_DIR/skills/angular-patterns.md"
        --read "$AIDER_GLOBAL_DIR/skills/clean-architecture.md"
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
    
    local NOME_REVIEW
    NOME_REVIEW="$(_next_review_file)"
    local TMP_REVIEW=".aider/${NOME_REVIEW}.md"
    local REVIEW_ARQUIVO=".ai/reviews/${NOME_REVIEW}.md"

    cat > "$TMP_REVIEW" <<EOF
# $NOME_REVIEW

## Veredito
<!-- APROVADO | APROVADO COM RESSALVAS | REPROVADO -->

## Score
<!-- 0-100 -->

## Bloqueadores
<!-- Liste bloqueadores reais com arquivo e evidência -->

## Divergências por Arquivo
<!-- Liste as divergências -->

## Refatorações Recomendadas
<!-- Liste ações objetivas -->
EOF

    local PROMPT
    PROMPT="$(_load_prompt "$AIDER_GLOBAL_DIR/skills/prompts/code-review.md")"
    PROMPT="${PROMPT//\{\{ALVO\}\}/$ALVO}"
    PROMPT="${PROMPT}

Edite OBRIGATORIAMENTE o arquivo $TMP_REVIEW preenchendo o esqueleto."

    agent "$modelo" "${SKILLS[@]}" "${EVIDENCE_ARGS[@]}" \
        --file "$TMP_REVIEW" \
        --yes \
        --message "$PROMPT" "$@"

    if [ -s "$TMP_REVIEW" ]; then
        mv "$TMP_REVIEW" "$REVIEW_ARQUIVO"
        echo "✅ Review salvo com sucesso em: $REVIEW_ARQUIVO"
    else
        echo "❌ Falha: O arquivo temporário de review ficou vazio."
        rm -f "$TMP_REVIEW"
        return 1
    fi
}

# Comando para Revisão Operacional (Code Review Funcional)
review() {
    local modelo="default"
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
    _aider_python "$AIDER_GLOBAL_DIR/scripts/query.py" discover "$@"
}

where() {
    _aider_python "$AIDER_GLOBAL_DIR/scripts/query.py" where "$@"
}

impact() {
    _aider_python "$AIDER_GLOBAL_DIR/scripts/query.py" impact "$@"
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
    _aider_python "$AIDER_GLOBAL_DIR/scripts/query.py" feature "$ALVO" > .ai/cache/feature_context.md
    
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
    local REF=""
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
            --ref)
                if [ -n "$2" ] && [[ "$2" != --* ]]; then
                    REF="$2"; shift 2
                else
                    echo "❌ ERRO: --ref requer um caminho."; return 1
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

    if [ -d ".ai/examples" ]; then
        while IFS= read -r f; do
            SKILLS+=(--read "$f")
        done < <(find .ai/examples -type f \( -name "*.md" -o -name "*.ts" -o -name "*.js" \))
    fi

    # 1. Executa auditoria determinística
    echo "🔎 Extraindo fatos objetivos via standardize_audit.py..."
    _init_ai_workspace
    
    local CMD_AUDIT=("$AIDER_GLOBAL_DIR/scripts/standardize_audit.py" --target "$ALVO" --out-json ".ai/cache/standardize-report.json" --out-md ".ai/cache/standardize-report.md")
    if [ -n "$REF" ]; then
        CMD_AUDIT+=(--ref "$REF")
    fi
    if [ -d ".ai/examples" ]; then
        CMD_AUDIT+=(--examples ".ai/examples")
    fi

    if ! _aider_python "${CMD_AUDIT[@]}"; then
        echo "❌ Falha ao rodar auditoria determinística."
        return 1
    fi

    # 2. Fluxo por Flag
    if [ "$FLAG" == "--audit" ]; then
        echo "✅ Auditoria concluída. Relatório factual:"
        # Usa awk para colorir as evidências no terminal mantendo o arquivo .md limpo
        awk '
        BEGIN { in_code = 0 }
        /^```/ {
            if (in_code) {
                printf "\033[0m\n"
                in_code = 0
            } else {
                printf "\033[34m\n"
                in_code = 1
            }
            next
        }
        { print }
        ' .ai/cache/standardize-report.md
        return 0
    fi

    # --- Se for --plan ou --fix, injetamos o laudo na IA ---
    local CONTEXT_ARGS=(--read ".ai/cache/standardize-report.md")

    if [ "$FLAG" == "--plan" ]; then
        mkdir -p .ai/plans .aider
        local PROXIMO_NUM=1
        if ls .ai/plans/PLAN-*.md 1> /dev/null 2>&1; then
            PROXIMO_NUM=$(( $(ls -1 .ai/plans/PLAN-*.md | wc -l) + 1 ))
        fi
        
        local NOME_PLANO="PLAN-$(printf "%03d" $PROXIMO_NUM)"
        local PLANO_ARQUIVO=".ai/plans/${NOME_PLANO}.md"
        local TMP_PLANO="tmp-${NOME_PLANO}.standardize.md"
        
        # Preenche o esqueleto inicial para forçar a IA a usar um bloco de SEARCH/REPLACE
        cat <<EOF > "$TMP_PLANO"
# $NOME_PLANO

## Sources
- .ai/cache/standardize-report.md
- .ai/examples
- .ai/rules/project-rules.md

## Objetivo
Refatorar a tela alvo para melhorar organização, legibilidade e aderência ao padrão, preservando comportamento funcional.

## Tarefas
<!-- INSIRA_AS_TAREFAS_AQUI -->
EOF

        local MENSAGEM="Você recebeu .ai/cache/standardize-report.md gerado por script determinístico.

Substitua a tag <!-- INSIRA_AS_TAREFAS_AQUI --> no arquivo $TMP_PLANO por um plano executável de refatoração segura.

Obrigatório:
- Usar SOMENTE os achados STD do relatório.
- Para cada tarefa, explicar:
  1. Como está hoje
  2. Como precisa ficar
  3. Arquivo afetado
  4. Ação objetiva
  5. Critério de aceite
- Agrupar STDs relacionados.
- Separar TypeScript, Service, HTML e SCSS quando aplicável.
- Não alterar regra de negócio.
- Não alterar endpoint.
- Não alterar payload.
- Não alterar model.
- Não inventar arquivos que não estejam evidenciados.
- Não gerar tarefa genérica.

Formato OBRIGATÓRIO de cada tarefa:
[ ] TASK-001 — [Nome da Tarefa]
- STD relacionado: [IDs]
- Como está: [descrição]
- Como precisa ficar: [descrição]
- Arquivo afetado: [arquivo]
- Ação objetiva: [ação]
- Critério de aceite: [critério]
"
        echo "📏 Planejando Padronização em $ALVO (Gerando rascunho em $TMP_PLANO)..."
        agent "$modelo" "${SKILLS[@]}" "${CONTEXT_ARGS[@]}" --file "$TMP_PLANO" --yes --message "$MENSAGEM" "$@"
        
        if [ -s "$TMP_PLANO" ]; then
            mv "$TMP_PLANO" "$PLANO_ARQUIVO"
            echo "✅ Plano movido com sucesso. Gerado em: $PLANO_ARQUIVO"
        else
            echo "❌ Falha: plano temporário vazio ou não gerado."
            return 1
        fi
    elif [ "$FLAG" == "--fix" ]; then
        local MENSAGEM="Atue como Standardizer. Você recebeu um relatório factual gerado por script determinístico (em standardize-report.md). Sua tarefa: Analisar e EXECUTAR as adequações no código do alvo para convergir estritamente aos padrões documentados no laudo."
        if [ -f "$ALVO" ]; then
            CONTEXT_ARGS+=(--file "$ALVO")
        elif [ -d "$ALVO" ]; then
            echo "⚠️  AVISO: --fix em diretório adiciona os arquivos como editáveis ao Aider."
            while IFS= read -r srcfile; do
                CONTEXT_ARGS+=(--file "$srcfile")
            done < <(find "$ALVO" -type f \( \
                -name "*.ts" -o -name "*.js" -o -name "*.java" \
                -o -name "*.py" -o -name "*.cs" -o -name "*.kt" \
            \) -not -path "*/node_modules/*" -not -path "*/target/*" \
               -not -path "*/dist/*" -not -path "*/.git/*" | head -n 30)
        fi
        echo "📏 Aplicando Padronização em $ALVO..."
        agent "$modelo" "${SKILLS[@]}" "${CONTEXT_ARGS[@]}" --message "$MENSAGEM" "$@"
    fi
}

# Modo Extrator de Regras (Draft Rules)
draft-rules() {
    local modelo="default"
    local context_rows=4000
    local agent_args=()

    if [ "$1" == "--model" ] && [ -n "$2" ]; then
        modelo="$2"
        shift 2
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
    _aider_python "$AIDER_GLOBAL_DIR/scripts/knowledge_pipeline.py"

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