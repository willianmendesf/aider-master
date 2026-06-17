# Regras de Programação (O "Linter" do Aider)

Este documento contém regras táticas e absolutas de sintaxe e clean code. A quebra de qualquer destas regras resulta em falha crítica no `CODE-REVIEW`.

## Nomenclaturas e Tipagem
- **Tipagem Estrita:** É EXTREMAMENTE PROIBIDO o uso de `any` ou `unknown` ignorado. Todos os retornos e entradas de funções devem ser tipados com Interfaces ou Classes.
- **CamelCase:** Obrigatório para nomes de métodos, instâncias de serviços e propriedades internas.
- **PascalCase:** Obrigatório para definição de Classes, Interfaces, Enums e Componentes.
- **kebab-case:** Obrigatório para nomes de pastas e arquivos no repositório.

## Estrutura de Código (Clean Code)
- **Tamanho de Arquivo:** Arquivos não devem ultrapassar [300] linhas. Acima disso, refatore extraindo responsabilidades.
- **Ifs Aninhados:** NUNCA passe de 2 níveis de `if/else` aninhados. Utilize cláusulas de guarda (`early return`) para manter o caminho feliz alinhado à esquerda.
- **Métodos Grandes:** Funções devem fazer apenas UMA coisa (Single Responsibility). Se a função possui mais de 20 linhas e múltiplas estruturas lógicas, quebre em funções privadas.

## Convenções de Sufixos (Adapte conforme a Stack)
- `Service`: Sempre que for uma classe injetável que controla regra de negócio.
- `Controller`: Sempre que for ponto de entrada de rota (backend).
- `Repository`: Sempre que tocar o banco de dados.
- `Dto`: Objetos de entrada/saída (ex: `CreateUserDto`).
- `I` (Prefixo): Interfaces devem sempre iniciar com a letra I maiúscula (ex: `IUserRepository`).
