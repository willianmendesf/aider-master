# Padrões e Exigências de Testes

Este documento rege a qualidade da base de código no que tange a testabilidade. O Aider usará isso para auditar e para gerar novos testes no DEV.

## 1. Princípios de Cobertura
- Toda nova funcionalidade deve obrigatoriamente possuir um teste unitário (`.spec.ts`, `_test.go`, `test_*.py`) associado antes de ser fechada a Task.
- Não buscamos 100% de cobertura forçada apenas para bater métricas (evite testes de getter/setters vazios), mas o "Caminho Feliz" e as "Exceções Críticas" do domínio são inegociáveis.

## 2. Estrutura do Teste (Padrão AAA)
Todo bloco de teste escrito deve seguir rigorosamente a separação visual:
- **Arrange (Preparação):** Instanciação das variáveis, classes e definição dos mocks.
- **Act (Ação):** A chamada exata da função que está sendo testada.
- **Assert (Validação):** O bloco onde espera-se que o resultado bata com o esperado (`expect()`).

## 3. Isolamento e Mocks
- **Regra Ouro:** Testes UNITÁRIOS não podem acessar o Banco de Dados, não podem fazer requisições à internet e não podem tocar em arquivos físicos no disco.
- Se a função lê do banco, você deve "MOCKAR" a camada do Repository injetando um falso resultado.
- Testes que demoram para carregar devido à dependências pesadas serão sinalizados como falha arquitetural (Baixa Testabilidade no Code-Review).

## 4. Testes de Falha (Sad Path)
- É obrigatório que o agente crie pelo menos um bloco de teste cobrindo o pior cenário de erro (ex: `should throw an Error when User is not found`).
