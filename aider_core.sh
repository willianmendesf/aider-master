# ==========================================
# LÓGICA CENTRAL DO AIDER (COMPARTILHADA)
# ==========================================

# --- HELPERS DE GERENCIAMENTO SEGURO DA PASTA .ai/ ---
# Garante que a estrutura base exista sem nunca apagar conteúdo
_init_ai_workspace() {
    mkdir -p .ai/rules
    mkdir -p .ai/context
    mkdir -p .ai/plans/archive
    mkdir -p .ai/decisions
    mkdir -p .ai/examples
}

# Limpa ESTRITAMENTE arquivos temporários (bundles/textos) gerados pelas ferramentas
_cleanup_ai_temps() {
    echo "🧹 Limpando artefatos temporários de IA..."
    rm -f ./.repomixignore
    rm -f .ai/.aider-*-context*.txt
    rm -f .aider-draft-context*.txt # Legado
}
# ----------------------------------------------------

# Skills globais carregadas sempre como base
BASE_SKILLS=(
    --read "$AIDER_GLOBAL_DIR/skills/anti-hallucination.md"
    --read "$AIDER_GLOBAL_DIR/skills/clean-code.md"
    --read "$AIDER_GLOBAL_DIR/skills/rtk-master.md"
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
        echo "Adicione seu bundle-output.txt ao RAG com brain-index para indexar o conteúdo do bundle no RAG."
        echo "fora do modo aider, rode no terminal: brain-index /[caminho-do-projeto]/bundle-output.txt [nome-do-projeto]"
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
                  --map-tokens 0 \
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
    if [ -z "$1" ]; then
        echo "❌ ERRO: Architect requer uma decisão arquitetural a ser analisada."
        echo "Exemplo: architect \"Migrar Context API para Redux\""
        return 1
    fi
    local DEMANDA="$1"
    shift

    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/architect.md"
    )

    if [ -s ".ai/context/project-map.md" ]; then
        SKILLS+=(--read ".ai/context/project-map.md")
    else
        echo "⚠️ AVISO: O mapa do projeto (.ai/context/project-map.md) não existe ou está vazio."
        echo "💡 Recomendação: Rode 'sync-full' para gerar o contexto e ajudar a IA a tomar decisões melhores."
    fi

    echo "🏛️ Atuando como Arquiteto para gerar um ADR..."
    agent "$modelo" "${SKILLS[@]}" --message "Atue como Arquiteto. Demanda: $DEMANDA. Avalie as alternativas, decida os trade-offs e CRIE um arquivo sequencial na pasta .ai/decisions/. Não gere ou modifique NENHUM código fonte." "$@"
}

# Comando para Decisões Táticas Locais (Sem ADR)
design() {
    if [ -z "$1" ]; then
        echo "❌ ERRO: Design requer uma decisão tática a ser estruturada."
        echo "Exemplo: design \"Nova tela de consulta de boletos\""
        return 1
    fi
    local DEMANDA="$1"
    shift

    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/system-design.md"
    )

    if [ -s ".ai/context/project-map.md" ]; then
        SKILLS+=(--read ".ai/context/project-map.md")
    fi

    echo "🏗️ Atuando como System Design (Decisão Tática local)..."
    agent "$modelo" "${SKILLS[@]}" --message "Demanda Tática: $DEMANDA. Use a skill System Design para apresentar uma proposta estrutural sem gerar código e sem gerar ADR." "$@"
}

# Comando para Fatiamento de Tarefas (Gera Plano Rastreável)
plan() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/architecture-review.md"
    )

    if [ -s ".ai/context/project-map.md" ]; then
        SKILLS+=(--read ".ai/context/project-map.md")
    else
        echo "⚠️ AVISO: O mapa do projeto (.ai/context/project-map.md) não existe ou está vazio."
        echo "💡 Recomendação: Rode 'sync-full' para gerar o contexto base para o planejamento tático."
    fi

    echo "🗺️ Atuando como Tech Lead para fatiar o Plano de Ação..."
    agent "$modelo" "${SKILLS[@]}" --message "Atue como Tech Lead. Baseado na demanda (ou ADR referenciado), quebre o requisito em tarefas atômicas de checklist [ ]. Salve o resultado em .ai/plans/PLAN-[NUM].md. Para cada TASK gerada, deixe claro no arquivo qual PLAN e ADR ela pertence para facilitar a Rastreabilidade Absoluta. NENHUM código fonte deve ser gerado ou alterado." "$@"
}

# ==========================================
# AIDER OS: Comandos de Execução
# ==========================================

# Comando para Execução Restrita (Codificação Pura)
dev() {
    if [ -z "$1" ]; then
        echo "Uso: dev <Caminho do Plano .ai/plans/PLAN-XXX.md> [modelo]"
        echo "Exemplo: dev .ai/plans/PLAN-001.md"
        return 1
    fi
    local PLANO="$1"
    shift
    
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    # Verifica se o plano existe
    if [ ! -f "$PLANO" ]; then
        echo "❌ ERRO: O plano '$PLANO' não foi encontrado."
        echo "💡 Use o comando 'plan' para gerar as tarefas antes de codificar."
        return 1
    fi

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/dev-golden-path.md"
        --read "$AIDER_GLOBAL_DIR/skills/angular-patterns.md"
    )

    echo "🔨 Iniciando Motor de Execução Seguro baseado em: $PLANO..."
    agent "$modelo" "${SKILLS[@]}" --read "$PLANO" --message "Atue como Desenvolvedor (Dev Golden Path). Leia o plano fornecido e execute EXATAMENTE as tarefas designadas. NUNCA invente novos padrões arquiteturais, procure por referências no código existente. Atualize o arquivo do plano marcando as tarefas concluídas com [x]. Assine suas criações com a rastreabilidade do PLANO/ADR." "$@"
}

# Modo Ask
ask() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null
    agent "$modelo" "${BASE_SKILLS[@]}" --chat-mode ask "$@"
}

# ==========================================
# AIDER OS: Comandos de Qualidade e Investigação
# ==========================================

# Comando para Debug Avançado (Root Cause Analysis)
debug() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/root-cause-analysis.md"
        --read "$AIDER_GLOBAL_DIR/skills/bug-hunter.md"
    )

    if [ -s ".ai/context/project-map.md" ]; then
        SKILLS+=(--read ".ai/context/project-map.md")
    else
        echo "⚠️ AVISO: O mapa do projeto não existe. Isso pode reduzir a precisão do diagnóstico."
    fi

    echo "🐛 Iniciando Investigação de Causa Raiz (Debug)..."
    agent "$modelo" "${SKILLS[@]}" --message "Atue como Investigador Sênior (Root Cause Analysis). Analise o erro ou problema relatado pelo usuário. Localize a raiz do problema cruzando com o contexto do projeto. NÃO sugira gambiarras, emita o relatório técnico e aponte o arquivo exato a ser corrigido." "$@"
}

# Comando para Revisão Operacional (Code Review Funcional)
review() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

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
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

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
    cp "$AIDER_GLOBAL_DIR/ignores/.aiignore" ./.repomixignore 2>/dev/null
    
    echo "📦 Rodando compactação do projeto -> Gerando: $OUTPUT_FILE..."
    repomix --output "$OUTPUT_FILE"
    
    _cleanup_ai_temps
    echo "✅ Concluído! O arquivo '$OUTPUT_FILE' foi gerado com sucesso."
}

# ==========================================
# AIDER OS: Comandos de Engenharia Reversa e Padrões
# ==========================================

# Comando para Engenharia Reversa de Legado
discover() {
    if [ -z "$1" ]; then
        echo "❌ ERRO: Discover requer um foco de investigação."
        echo "Exemplo: discover \"listar boletos\" [--flow | --api | --db | --deep]"
        return 1
    fi
    local DEMANDA="$1"
    shift

    local FLAG="Padrão"
    for arg in "$@"; do
        case $arg in
            --flow) FLAG="--flow"; shift ;;
            --api) FLAG="--api"; shift ;;
            --db) FLAG="--db"; shift ;;
            --deep) FLAG="--deep"; shift ;;
        esac
    done

    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    _init_ai_workspace
    bundle ".ai/.aider-discover-context-full.txt" > /dev/null 2>&1
    head -n 25000 .ai/.aider-discover-context-full.txt > .ai/.aider-discover.txt

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/discover.md"
        --read ".ai/.aider-discover.txt"
    )

    echo "🕵️ Iniciando Engenharia Reversa (Modo: $FLAG) sobre: $DEMANDA..."
    agent "$modelo" "${SKILLS[@]}" --message "Execute o modo $FLAG da skill Discover com foco em: $DEMANDA. Analise o contexto lido e mapeie tudo em detalhes." "$@"
    
    _cleanup_ai_temps
}

# Comando para Convergir Código para o Golden Path
standardize() {
    if [ -z "$1" ]; then
        echo "❌ ERRO: Uso: standardize <alvo> [--audit | --plan | --fix]"
        return 1
    fi
    local ALVO="$1"
    shift

    local FLAG="--audit"
    for arg in "$@"; do
        case $arg in
            --audit) FLAG="--audit"; shift ;;
            --plan) FLAG="--plan"; shift ;;
            --fix) FLAG="--fix"; shift ;;
        esac
    done

    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/standardizer.md"
    )

    # Injeta arquivos do Golden Path para referência
    [ -d ".ai/examples" ] && find .ai/examples -type f -name "*.md" -o -name "*.ts" -o -name "*.js" | while read -r f; do SKILLS+=(--read "$f"); done

    local MENSAGEM="Atue como Standardizer."
    if [ "$FLAG" = "--audit" ]; then
        MENSAGEM="$MENSAGEM Analise o código em $ALVO e liste APENAS as divergências encontradas contra o Golden Path e regras. NÃO altere o código e não gere planos."
    elif [ "$FLAG" = "--plan" ]; then
        MENSAGEM="$MENSAGEM Analise o código em $ALVO, encontre as divergências e CRIE um PLAN-XXX.md na pasta .ai/plans/ com as tarefas rastreáveis TASK-XXX. Não altere o código fonte."
    elif [ "$FLAG" = "--fix" ]; then
        MENSAGEM="$MENSAGEM Analise o código em $ALVO e EXECUTE as adequações necessárias no arquivo fornecido para convergir estritamente aos padrões do Golden Path."
    fi

    echo "📏 Iniciando Padronização em $ALVO (Modo: $FLAG)..."
    agent "$modelo" "${SKILLS[@]}" --file "$ALVO" --message "$MENSAGEM" "$@"
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
    
    _init_ai_workspace

    echo "📦 Lendo todos os seus arquivos para entender o padrão (isso pode levar uns segundos)..."
    
    bundle ".ai/.aider-draft-context-full.txt" > /dev/null 2>&1
    head -n 12000 .ai/.aider-draft-context-full.txt > .ai/.aider-draft-context.txt

    local SKILLS=(
        --read "$AIDER_GLOBAL_DIR/skills/rules-extractor.md"
        --read ".ai/.aider-draft-context.txt"
    )

    # Deleta as regras apenas quando explicitamente rodar o draft (para recriá-las)
    rm -f .project-rules.md
    rm -f .ai/rules/project-rules.md

    agent "$modelo" "${SKILLS[@]}" --message "Use o arquivo .ai/.aider-draft-context.txt fornecido para entender o padrão do projeto. Ele contém a árvore de pastas e uma amostra do código-fonte. CRIE o arquivo .ai/rules/project-rules.md DE IMEDIATO. NUNCA faça perguntas." .ai/rules/project-rules.md "$@"
    
    _cleanup_ai_temps
}

# ==========================================
# AIDER OS: Comandos de Governança e Contexto
# ==========================================

# Comando Bootstrap para Novos Projetos
bootstrap() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    echo "🚀 Iniciando Bootstrap do Projeto (Aider OS v1.0)..."
    _init_ai_workspace

    bundle ".ai/.aider-bootstrap-full.txt" > /dev/null 2>&1
    head -n 25000 .ai/.aider-bootstrap-full.txt > .ai/.aider-bootstrap.txt

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
        --read "$AIDER_GLOBAL_DIR/skills/governance-audit.md"
    )

    echo "🔍 Mapeando projeto e gerando Backlog Técnico..."
    agent "$modelo" "${SKILLS[@]}" --read ".ai/.aider-bootstrap.txt" \
    --message "Atue simultaneamente como Context Builder e Auditor. Analise o contexto e execute as 4 etapas:
1. Atualize .ai/context/project-map.md e domain-map.md.
2. Crie .ai/decisions/ARCHITECTURE-BASELINE.md com o Laudo Base e Score.
3. Crie .ai/plans/TECHNICAL-DEBT-BACKLOG.md listando dívidas técnicas em formato [ ] TASK-XXX.
4. Crie .ai/examples/candidates.md sugerindo classes/arquivos bem avaliados como Golden Path.
NÃO faça perguntas." "$@"

    _cleanup_ai_temps
    echo "✅ Bootstrap Concluído! Cérebro inicializado."
}

# Comando para atualizar o mapa de TODO o projeto
sync-full() {
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
    )
    
    _init_ai_workspace
    
    # Gera o bundle com repomix herdando o .aiignore (remove dependências e lixo)
    bundle ".ai/.aider-sync-context-full.txt" > /dev/null 2>&1

    # OTIMIZAÇÃO DE TOKENS: Pegamos as primeiras 15.000 linhas e salvamos na pasta .ai/
    head -n 15000 .ai/.aider-sync-context-full.txt > .ai/.aider-sync-context.txt

    echo "🔄 Rodando Sync Full (Otimizado com Amostragem de Contexto)..."
    agent "$modelo" "${SKILLS[@]}" --read ".ai/.aider-sync-context.txt" .ai/context/project-map.md .ai/context/domain-map.md --message "Leia o contexto fornecido (que contém a árvore de diretórios no topo) e atue como Context Builder. ATUALIZE IMEDIATAMENTE os arquivos .ai/context/project-map.md e .ai/context/domain-map.md. NUNCA crie regras, apenas mapeie o existente. NUNCA modifique código fonte." "$@"

    _cleanup_ai_temps
}

# Comando para atualizar o mapa de apenas um módulo específico (Econômico)
sync-module() {
    if [ -z "$1" ]; then
        echo "Uso: sync-module <caminho-do-modulo> [modelo]"
        echo "Exemplo: sync-module src/modules/user"
        return 1
    fi
    local MODULO="$1"
    shift
    
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    _init_ai_workspace

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/context-builder.md"
    )

    echo "🔄 Rodando Sync Module focado em: $MODULO..."
    # Adicionamos os arquivos de contexto existentes no chat de forma editável e passamos os arquivos do módulo
    agent "$modelo" "${SKILLS[@]}" --file "$MODULO" .ai/context/project-map.md .ai/context/domain-map.md --message "Atue como Context Builder. Leia APENAS o módulo especificado ($MODULO). Atualize os arquivos na pasta .ai/context/ (project-map.md e domain-map.md) integrando o que você aprendeu deste módulo sem perder o que já existe sobre os outros módulos. NÃO faça perguntas, apenas atualize os arquivos." "$@"
}

# Comando para Auditoria Punitiva de Conformidade
code-review() {
    if [ -z "$1" ]; then
        echo "Uso: code-review <alvo> [modelo]"
        echo "Exemplo: code-review src/modules/user"
        echo "Exemplo: code-review ."
        return 1
    fi
    local ALVO="$1"
    shift
    
    local modelo="${1:-default}"
    [ "$1" = "default" ] && shift || shift 0 2>/dev/null

    # Lê todos os estatutos da pasta .ai/rules caso existam no projeto atual
    local REGRAS_PROJETO=()
    [ -f ".ai/constitution.md" ] && REGRAS_PROJETO+=(--read ".ai/constitution.md")
    [ -f ".ai/rules/project-rules.md" ] && REGRAS_PROJETO+=(--read ".ai/rules/project-rules.md")
    [ -f ".ai/rules/coding.md" ] && REGRAS_PROJETO+=(--read ".ai/rules/coding.md")
    [ -f ".ai/rules/architecture.md" ] && REGRAS_PROJETO+=(--read ".ai/rules/architecture.md")
    [ -f ".ai/rules/testing.md" ] && REGRAS_PROJETO+=(--read ".ai/rules/testing.md")

    local SKILLS=(
        "${BASE_SKILLS[@]}"
        --read "$AIDER_GLOBAL_DIR/skills/governance-audit.md"
        --read "$AIDER_GLOBAL_DIR/skills/angular-patterns.md"
        "${REGRAS_PROJETO[@]}"
    )

    echo "⚖️ Iniciando Tribunal de Código (Code-Review Punitivo) sobre: $ALVO..."
    agent "$modelo" "${SKILLS[@]}" --file "$ALVO" --message "Atue estritamente como Auditor Sênior Implacável usando a skill Governance Audit. Analise o código fornecido contra os arquivos de regras lidos. Emita IMEDIATAMENTE o seu Laudo de Maturidade com Score (0-100) e Letra (A-E), listando todos os desvios. NUNCA altere o código fonte. Apenas emita o laudo de REPROVADO se as regras fundamentais forem quebradas." "$@"
}