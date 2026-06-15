# 🤖 Aider Centralizado (Multi-Ambiente: Windows & Linux)

Este repositório centraliza as configurações, chaves de API (BYOK), instruções de contexto (skills), inteligência (RAG) e atalhos customizados para o uso do Aider de forma idêntica no Windows e no Linux.

---

## 🛠️ Requisitos Prévios

Antes de começar, certifique-se de ter instalado em sua máquina:
1. Python 3.10+
2. Node.js & npm (Necessário para a ferramenta de contexto repomix)
3. Git

---

## 🚀 Instalação e Inicialização do Ambiente

Siga os passos abaixo de acordo com o seu sistema operacional para preparar a pasta e o ambiente virtual do Python.

### 🐧 No Linux (Ubuntu/Debian/etc.)

  # 1. Garanta que o Node.js/npm e ferramentas de compilação estão instalados
  sudo apt update
  sudo apt install nodejs npm build-essential python3-dev -y

  # 2. Instale o Repomix globalmente para a função 'context' funcionar
  sudo npm install -g repomix

  # 3. Acesse a pasta do projeto, limpe e recrie o ambiente virtual (venv)
  cd /dados/aider
  rm -rf venv
  python3 -m venv venv
  source venv/bin/activate

  # 4. Atualize o pip e instale as dependências do ecossistema/cérebro
  pip install --upgrade pip
  pip install aider-chat fastmcp chromadb sentence-transformers



### No Windows (Via Git Bash)

  # 1. Instale o Repomix globalmente (Abra o CMD ou PowerShell como Administrador)
  npm install -g repomix

  # 2. Abra o Git Bash e instale o gerenciador global pipx
  python -m pip install pipx --upgrade
  python -m pipx ensurepath

  # 🚨 IMPORTANTE: Feche e abra o seu Git Bash agora para o PATH do Windows atualizar!

  # 3. Instale o Aider e o ecossistema do cérebro de forma isolada e compatível
  pipx install aider-chat --pip-args="--pre --upgrade-strategy=eager"
  pipx inject aider-chat fastmcp chromadb sentence-transformers


## 🔗 Vinculando os Atalhos ao Terminal (.bashrc)

Para que os comandos customizados (ask, plan, study, context) fiquem disponíveis globalmente, adicione o bloco correspondente ao arquivo de configuração do seu terminal.

### 🐧 Configuração no Linux (~/.bashrc)
Abra o arquivo ~/.bashrc e adicione ao final:

  # ==========================================
  # AIDER - Carregar funções centralizadas
  # ==========================================
  if [ -f "/dados/aider/bash_linux_functions.sh" ]; then
      source "/dados/aider/bash_linux_functions.sh"
  fi

### 🪟 Configuração no Windows (C:\Users\SEU_USUARIO\.bashrc)
Abra o seu .bashrc de usuário no Windows e adicione ao final:

  # ==========================================
  # AIDER - Carregar funções centralizadas
  # ==========================================
  if [ -f "/c/dev/programs/aider/bash_win_functions.sh" ]; then
      source "/c/dev/programs/aider/bash_win_functions.sh"
  fi

> 💡 Nota para o Windows: Se o Git Bash ignorar o .bashrc, certifique-se de ter um arquivo chamado ~/.bash_profile na sua pasta de usuário com a linha: [ -f ~/.bashrc ] && source ~/.bashrc.

---

## 🧠 Usando a Memória do Projeto (RAG & MCP)

Para economizar tokens, este ecossistema possui um sistema RAG nativo. Como o Aider atualmente não suporta o protocolo MCP de forma nativa, criamos um script CLI (`rag_cli.py`) que simula a "ferramenta MCP" direto no chat do Aider, utilizando busca inteligente com fallback full-text!

### 1. Indexando o seu projeto (Construindo a Memória)
Antes de consultar, você precisa "ensinar" o projeto ao sistema. Execute no seu terminal:
```bash
# Indexar um projeto inteiro ou um arquivo consolidado (ex: bundle-output.txt)
brain-index /[caminho-do-projeto] [nome-do-projeto]
```

### 2. Consultando o RAG por dentro do Aider
Sempre que estiver no chat do Aider e precisar buscar o funcionamento de uma função, lógica antiga, ou entender a estrutura do projeto **sem gastar tokens lendo arquivos desnecessários**, use o comando `/run`:

```text
# Para buscar por uma lógica, função, ou palavra-chave:
/run python3 /dados/aider/rag/rag_cli.py search "como conectar no banco"

# Para ver a estrutura de pastas e mapeamento do projeto:
/run python3 /dados/aider/rag/rag_cli.py map
```
*(No Windows, substitua `python3` por `python` e você pode usar a variável `$AIDER_GLOBAL_DIR/rag/rag_cli.py` caso prefira o caminho absoluto).*

> **💡 Dica:** O script é inteligente! Ele rastreia a pasta `.git` do diretório atual para inferir automaticamente em qual projeto do banco de RAG ele deve procurar.

### 3. Usando com Editores Externos via MCP (Cursor, Windsurf, Claude Desktop)
Se você usa IAs ou editores que possuem suporte ao protocolo MCP real, o servidor já está configurado. Basta apontar o software para o `mcp/code_rag_server.py` ou usar o nosso `mcp.json`. Exemplo de link simbólico para sistemas baseados no Claude:

#### 🐧 No Linux
```bash
  mkdir -p ~/.config/aider
  ln -sf /dados/aider/mcp/mcp.json ~/.config/aider/mcp.json
```

#### 🪟 No Windows (Git Bash)
```bash
  mkdir -p ~/.config/aider
  ln -sf [seu-caminho-windows]/aider/mcp/mcp.json ~/.config/aider/mcp.json
```

---

## 📖 Como Usar os Comandos Customizados

Após recarregar o seu terminal (source ~/.bashrc), os seguintes comandos estarão prontos para uso em qualquer pasta de projeto:

| Comando | Descrição |
| :--- | :--- |
| ask [modelo] | Abre o chat do Aider em modo pergunta (ask) com as suas habilidades (skills) já injetadas. |
| plan [modelo] | Abre o Aider em modo Arquiteto (--architect), ideal para planejar refatorações complexas. |
| study [modelo] | Abre o modo pergunta ignorando completamente o Git do projeto (--no-git). |
| context [arquivo.txt] | Roda o Repomix focado na pasta src/, gerando um relatório compactado do código (padrão: study-output.txt). |
| brain-index [caminho] [nome] | Executa o indexador RAG para alimentar a base de conhecimento do cérebro da aplicação. |

### 💡 Exemplos Práticos:

  # Iniciar um chat focado em tirar dúvidas de código usando o modelo padrão (o3-mini)
  ask

  # Usar o modo arquiteto forçando outro modelo (ex: gpt-4o)
  plan gpt-4o

  # Compactar o projeto Angular/React atual antes de subir os tokens
  context meu-projeto-compactado.txt

  # Indexar um projeto no cérebro
  brain-index /c/meus-projetos/sistema-antigo sistema-legado# aider-master
