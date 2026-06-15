# ==========================================
# LÓGICA CENTRAL DO AIDER (COMPARTILHADA)
# ==========================================

# Skills globais carregadas sempre como base
BASE_SKILLS=(
    "$AIDER_GLOBAL_DIR/skills/anti-hallucination.md"
    "$AIDER_GLOBAL_DIR/skills/clean-code.md"
    "$AIDER_GLOBAL_DIR/skills/rtk-master.md"
)

# Função Principal (Agent)
agent() {
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

    echo "🤖 Iniciando Agent com modelo: $MODELO"

    # Execução dinâmica baseada nas variáveis do ambiente ativo
    OPENAI_API_KEY="$MINHA_CHAVE_API" \
    command aider --config "$AIDER_GLOBAL_DIR/$AIDER_CONFIG_FILE" \
                  --openai-api-base "$MEU_PROVEDOR_URL" \
                  --model "openai/$MODELO" \
                  --no-browser \
                  --no-git \
                  --input-history-file ".aider/.aider.input.history" \
                  --chat-history-file ".aider/.aider.chat.history.md" \
                  --llm-history-file ".aider/.aider.llm.history" \
                  #--aiderignore "$AIDER_GLOBAL_DIR/ignores/.aiignore" \
                  "$@"
}

# Modo Ask Ultra Econômico (Aplica a Allowlist/Ignorelist estrita para poupar tokens)
agent-eco() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    echo "🌱 Modo Econômico Ativado: Filtrando contexto agressivamente..."

    # Mantemos as habilidades base na memória
    local SKILLS=(
        "${BASE_SKILLS[@]}"
    )

    # Chamamos o agente injetando o seu arquivo .aiignore restritivo
    agent "$modelo" \
        --read "${SKILLS[@]}" \
        --aiderignore "$AIDER_GLOBAL_DIR/ignores/.aiignore" \
        --chat-mode ask \
        "$@"
}


# Modo Plan (Architect)
plan() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
    )

    agent "$modelo" --read "${SKILLS[@]}" --architect "$@"
}

# Modo Ask
ask() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null
    agent "$modelo" --read "${BASE_SKILLS[@]}" --chat-mode ask "$@"
}

# Modo Ask específico para bugs
ask-bug() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        "$AIDER_GLOBAL_DIR/skills/root-cause-analysis.md"
        "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
    )

    agent "$modelo" --read "${SKILLS[@]}" --chat-mode ask "$@"
}

# Modo Ask específico para refatoração
ask-refactor() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        "$AIDER_GLOBAL_DIR/skills/enterprise-refactor.md"
        "$AIDER_GLOBAL_DIR/skills/test-generator.md"
        "$AIDER_GLOBAL_DIR/skills/pr-review.md"
    )

    agent "$modelo" --read "${SKILLS[@]}" "$@"
}

# Modo Ask específico para migração
ask-migration() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        "$AIDER_GLOBAL_DIR/skills/analysis.md"
        "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        "$AIDER_GLOBAL_DIR/skills/enterprise-refactor.md"
        "$AIDER_GLOBAL_DIR/skills/test-generator.md"
    )

    agent "$modelo" --read "${SKILLS[@]}" "$@"
}

# Modo Ask específico para revisão de código
ask-review() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        "$AIDER_GLOBAL_DIR/skills/pr-review.md"
        "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
        "$AIDER_GLOBAL_DIR/skills/security-audit.md"
        "$AIDER_GLOBAL_DIR/skills/performance-audit.md"
    )

    agent "$modelo" --read "${SKILLS[@]}" --chat-mode ask "$@"
}

# Modo Ask específico para empresas
ask-enterprise() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        "$AIDER_GLOBAL_DIR/skills/analysis.md"
        "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        "$AIDER_GLOBAL_DIR/skills/enterprise-refactor.md"
        "$AIDER_GLOBAL_DIR/skills/root-cause-analysis.md"
        "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
        "$AIDER_GLOBAL_DIR/skills/security-audit.md"
        "$AIDER_GLOBAL_DIR/skills/performance-audit.md"
        "$AIDER_GLOBAL_DIR/skills/test-generator.md"
        "$AIDER_GLOBAL_DIR/skills/pr-review.md"
    )

    agent "$modelo" --read "${SKILLS[@]}" "$@"
}

# Modo Study (Ask sem Git e com as sub-skills base)
study() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null
    agent "$modelo" --read "${BASE_SKILLS[@]}" --chat-mode ask --no-git "$@"
}

# Utilitário de Contexto
context() {
    local OUTPUT_FILE="${1:-study-output.txt}"

    echo "🚀 Compactando projeto (Foco total na pasta src) -> Gerando: $OUTPUT_FILE..."
    
    repomix --include "src/**" \
            --ignore "node_modules/**,dist/**,.git/**,*.png,*.jpg,*.svg,package-lock.json" \
            --output "$OUTPUT_FILE"
    
    echo "✅ Concluído! O arquivo '$OUTPUT_FILE' foi gerado com sucesso na raiz do seu projeto."
}

contextOLD() {
    echo "🚀 Puxando Filtros Globais (.aiignore)"
    
    cp "$AIDER_GLOBAL_DIR/ignores/.aiignore" ./.repomixignore 2>/dev/null
    
    echo "📦 Rodando compactação do projeto..."
    repomix
    
    echo "🧹 Limpando arquivos temporários..."
    rm -f ./.repomixignore
    
    echo "✅ Concluído! O arquivo 'repomix-output.txt' foi gerado com sucesso."
}

# Indexador RAG do Cérebro
brain-index() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "🧠 Uso: brain-index /caminho/do/projeto nome_do_projeto"
        return 1
    fi
    "$AIDER_GLOBAL_DIR/rag/indexer.sh" "$1" "$2"
}