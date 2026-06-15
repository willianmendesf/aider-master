#!/bin/bash
# /dados/aider/rag/indexer.sh

PROJECT_PATH=$1
PROJECT_NAME=$2

if [ -z "$PROJECT_PATH" ] || [ -z "$PROJECT_NAME" ]; then
    echo "Uso: indexer.sh /caminho/do/projeto nome_do_projeto"
    exit 1
fi

DB_DIR="/dados/aider/rag/db/$PROJECT_NAME"
mkdir -p "$DB_DIR"

echo "🧠 Indexando projeto '$PROJECT_NAME' em $DB_DIR..."

# 1. Criar Mapa de Arquivos (Estrutura de forma compatível Win/Linux)
# Usamos o 'prune' para o find ignorar pastas pesadas antes de listar os arquivos
find "$PROJECT_PATH" \
  \( -name ".git" -o -name "node_modules" -o -name "venv" -o -name ".venv" \) -prune -o \
  -type f \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.txt" \) -print \
  > "$DB_DIR/file_list.txt"

# 2. Criar Resumo de Símbolos (Funções e Classes)
echo "# Mapa de Símbolos - $PROJECT_NAME" > "$DB_DIR/index.txt"
echo "Gerado em: $(date)" >> "$DB_DIR/index.txt"
echo "---" >> "$DB_DIR/index.txt"

# Se o caminho for um arquivo único (como o bundle-output.txt), o grep roda direto nele
if [ -f "$PROJECT_PATH" ]; then
    grep -n -E "def |class |function |const |let " "$PROJECT_PATH" >> "$DB_DIR/index.txt"
else
    # Se for uma pasta, faz a busca recursiva ignorando o lixo de forma multiplataforma
    grep -r \
      --include="*.py" --include="*.js" --include="*.ts" --include="*.txt" \
      --exclude-dir=".git" --exclude-dir="node_modules" --exclude-dir="venv" \
      -n -E "def |class |function |const |let " "$PROJECT_PATH" \
      >> "$DB_DIR/index.txt"
fi

# 3. Gerar Arquivo de Arquitetura (Se não existir e for uma pasta)
if [ -d "$PROJECT_PATH" ] && [ ! -f "$PROJECT_PATH/ARCHITECTURE.md" ]; then
    echo "Dica: Crie um arquivo ARCHITECTURE.md na raiz do projeto para ajudar a IA."
fi

echo "✅ Indexação concluída!"
echo "Agora o Aider pode usar as ferramentas 'search_project_memory' e 'get_project_map'."