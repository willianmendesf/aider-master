# 1. Remover a pasta venv antiga (que está com problemas)
rm -rf /dados/aider/venv

# 2. Criar um NOVO ambiente virtual
python3 -m venv /dados/aider/venv

# 3. Ativar o novo ambiente
source /dados/aider/venv/bin/activate

# Atualizar o pip primeiro
pip install --upgrade pip

# Instalar as bibliotecas do cérebro
pip install fastmcp chromadb sentence-transformers


colocar no .bashrc: no linux
# ==========================================
# AIDER - Carregar funções centralizadas
# ==========================================
if [ -f "/dados/.aider/bash_linux_functions.sh" ]; then
    source "/dados/.aider/bash_linux_functions.sh"
fi   


Colocar no windows
# ==========================================
# AIDER - Carregar funções centralizadas
# ==========================================
if [ -f "/c/dev/programs/aider/bash_win_functions.sh" ]; then
    source "/c/dev/programs/aider/bash_win_functions.sh"
fi   


crie a pasta padrão que o Aider lê no Linux e aponte o link para a sua pasta de backup:
mkdir -p ~/.config/aider
ln -s /dados/aider/mcp/mcp.json ~/.config/aider/mcp.json


usando o cérebro da aplicação:
 brain-index [caminho do projeto a ser indexado];


## dia a dia
ask               # perguntas rápidas
plan              # arquitetura
ask-bug           # debugging
ask-refactor      # melhorias
ask-migration     # Angular 9 -> 19
ask-review        # revisar código
ask-enterprise    # tarefa crítica