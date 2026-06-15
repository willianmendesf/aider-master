# ==========================================
# LÓGICA CENTRAL DO AIDER (COMPARTILHADA)
# ==========================================

# Skills globais carregadas sempre como base
BASE_SKILLS=(
    --read "$AIDER_GLOBAL_DIR/skills/anti-hallucination.md"
    --read "$AIDER_GLOBAL_DIR/skills/clean-code.md"
    --read "$AIDER_GLOBAL_DIR/skills/rtk-master.md"
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

    # --- DETECÇÃO AUTOMÁTICA DE BUNDLE NA RAIZ ---
    local EXTRA_FLAGS=()
    
    # Lista de nomes prováveis que você usa/usou para o output do bundle
    if [ -f "./bundle-output.txt" ]; then
        echo "📦 Bundle detectado automaticamente: ./bundle-output.txt."
        echo "Adicione seu bundle-output.txt ao RAG com brain-index para indexar o conteúdo do bundle no RAG."
        echo "fora do modo aider, rode no terminal: brain-index /[caminho-do-projeto]/bundle-output.txt [nome-do-projeto]"
        #EXTRA_FLAGS+=(--read "./bundle-output.txt")
    fi
    # ----------------------------------------------

    echo "🌱 Modo Econômico"
    echo "🤖 Iniciado com modelo: $MODELO"

    # --- LOOP DE AUTONOMIA E DETECÇÃO DE REGRAS ---
    if [ -f "./.project-rules.md" ]; then
        echo "📜 Regras do projeto detectadas e injetadas automaticamente."
        EXTRA_FLAGS+=(--read "./.project-rules.md")
    fi

    if [ -f "./package.json" ]; then
        if grep -q '"lint"' "./package.json"; then
            echo "🔧 Linter detectado (npm run lint). Auto-correção ativada."
            EXTRA_FLAGS+=(--lint-cmd "npm run lint")
        fi
        if grep -q '"test"' "./package.json"; then
            echo "🧪 Testes detectados (npm run test). Auto-teste ativado."
            EXTRA_FLAGS+=(--test-cmd "npm run test")
        fi
    fi
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
                  --map-tokens 0 \
                  --input-history-file ".aider/.aider.input.history" \
                  --chat-history-file ".aider/.aider.chat.history.md" \
                  --llm-history-file ".aider/.aider.llm.history" \
                  --aiderignore "$AIDER_GLOBAL_DIR/ignores/.aiignore" \
                  --read ".aider/.aider.root.md" \
                  "${EXTRA_FLAGS[@]}" \
                  "$@"
}

# Modo Plan (Architect)
plan() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        --read "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
    )

    agent "$modelo" "${SKILLS[@]}" --architect "$@"
}

# Modo Ask
ask() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null
    agent "$modelo" "${BASE_SKILLS[@]}" --chat-mode ask "$@"
}

# Modo Ask específico para bugs
ask-bug() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/root-cause-analysis.md"
        --read "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
    )

    agent "$modelo" "${SKILLS[@]}" --chat-mode ask "$@"
}

# Modo Ask específico para refatoração
ask-refactor() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        --read "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/enterprise-refactor.md"
        --read "$AIDER_GLOBAL_DIR/skills/test-generator.md"
        --read "$AIDER_GLOBAL_DIR/skills/pr-review.md"
    )

    agent "$modelo" "${SKILLS[@]}" "$@"
}

# Modo Ask específico para migração
ask-migration() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

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

# Modo Ask específico para revisão de código
ask-review() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/pr-review.md"
        --read "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
        --read "$AIDER_GLOBAL_DIR/skills/security-audit.md"
        --read "$AIDER_GLOBAL_DIR/skills/performance-audit.md"
    )

    agent "$modelo" "${SKILLS[@]}" --chat-mode ask "$@"
}

# Modo Ask específico para empresas
ask-enterprise() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

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
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null
    agent "$modelo" "${BASE_SKILLS[@]}" --chat-mode ask --no-git "$@"
}

# Empacotador de Contexto para IA (Unificado e protegido pelo .aiignore global)
bundle() {
    local OUTPUT_FILE="${1:-bundle-output.txt}"

    echo "🚀 Puxando Filtros Globais (.aiignore)..."
    # Copia o seu ignore global para a raiz do projeto atual como o Repomix espera
    cp "$AIDER_GLOBAL_DIR/ignores/.aiignore" ./.repomixignore 2>/dev/null
    
    echo "📦 Rodando compactação do projeto -> Gerando: $OUTPUT_FILE..."
    # Executa o repomix forçando a saída para o arquivo desejado
    repomix --output "$OUTPUT_FILE"
    
    echo "🧹 Limpando arquivos temporários..."
    rm -f ./.repomixignore
    
    echo "✅ Concluído! O arquivo '$OUTPUT_FILE' foi gerado com sucesso na raiz do seu projeto."
}

# Indexador RAG do Cérebro
brain-index() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "🧠 Uso: brain-index /caminho/do/projeto nome_do_projeto"
        return 1
    fi
    "$AIDER_GLOBAL_DIR/rag/indexer.sh" "$1" "$2"
}

# Modo Extrator de Regras (Draft Rules)
draft-rules() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    echo "========================================================"
    echo "🤖 MODO EXTRATOR DE REGRAS INICIADO"
    echo "========================================================"
    echo "📦 Lendo todos os seus arquivos para entender o padrão (isso pode levar uns segundos)..."
    
    # Cria o bundle temporário focado para extração
    repomix --output .aider-draft-context.txt > /dev/null 2>&1

    local SKILLS=(
        --read "$AIDER_GLOBAL_DIR/skills/rules-extractor.md"
        --read ".aider-draft-context.txt"
    )

    agent "$modelo" "${SKILLS[@]}" --message "Use o arquivo .aider-draft-context.txt fornecido para entender todo o projeto. CRIE o arquivo .project-rules.md na raiz DE IMEDIATO com base no código lido. NUNCA faça perguntas óbvias. Leia o código e defina a regra." "$@"
    
    # Limpa o arquivo temporário depois
    rm -f .aider-draft-context.txt
}