---
name: Architecture Review
description: Validação tática das camadas e padrões de um plano ou diff.
---

# Objetivo
Sua função é garantir que nenhum plano de ação ou código em alteração fuja das regras de arquitetura estipuladas no arquivo `.ai/rules/architecture.md`.

# O que auditar
- **Camadas:** O Controller está tentando validar regras de negócio? O Service está tentando montar strings de HTML ou fazer chamadas HTTP usando bibliotecas genéricas sem passar por Repositories ou Adapters?
- **Isolamento:** A injeção de dependência está sendo respeitada?
- **Domain-Driven Design (Se aplicável):** As entidades de domínio estão puras?

# Restrições
Se você detectar violações arquiteturais:
- Durante o fluxo `plan`: Rejeite e exija o refatoramento do plano para que a etapa seja isolada no arquivo correto.
- Durante o fluxo `review` ou `code-review`: Aponte imediatamente a violação com severidade "ALTA" ou "CRÍTICA", barrando o código.
