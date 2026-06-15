# ==========================================
# DEFINIÇÃO DE CAMINHOS
# ==========================================
# Definimos o diretório base do Aider usando o padrão /c/ para evitar erros no Bash
export AIDER_GLOBAL_DIR="/c/dev/programs/aider"

# Adiciona ao PATH do sistema corretamente
export PATH="$PATH:$AIDER_GLOBAL_DIR"

# Configuração do arquivo de configuração do Aider
export AIDER_CONFIG_FILE="config.yml"

# Carrega as chaves de API centralizadas
if [ -f "$AIDER_GLOBAL_DIR/aider_env.sh" ]; then
    source "$AIDER_GLOBAL_DIR/aider_env.sh"
else echo "Não foi possível localizar o arquivo de configuração de chaves de API: $AIDER_GLOBAL_DIR/aider_env.sh"
fi

# Importa o arquivo de lógica centralizada
if [ -f "$AIDER_GLOBAL_DIR/aider_core.sh" ]; then
    source "$AIDER_GLOBAL_DIR/aider_core.sh"
else echo "Não foi possível localizar o arquivo de lógica centralizada: $AIDER_GLOBAL_DIR/aider_core.sh"
fi