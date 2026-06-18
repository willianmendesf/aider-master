---
name: Clean Architecture Audit
description: Avalia separação de responsabilidades, dependências e camadas.
---

# Objetivo

Auditar se o código respeita separação de camadas e responsabilidades.

# Avaliar obrigatoriamente

## Component
Deve conter apenas:
- estado de tela
- handlers de UI
- orquestração simples

Não deve concentrar:
- regra de negócio
- transformação pesada
- montagem complexa de payload
- controle complexo de modal
- lógica de download
- parsing/manual formatting repetido

## Service
Deve conter:
- comunicação com API
- montagem de request
- adaptação simples de resposta

Não deve conter:
- estado visual
- regra de apresentação
- lógica de componente

## Utils / Helpers
Usar quando houver:
- formatação reutilizável
- validação pura
- parsing
- montagem repetitiva de parâmetros

# Classificações

## Bloqueador
- Componente com regra de negócio crítica
- API client/endpoints alterados sem evidência
- lógica de domínio duplicada em múltiplos lugares
- subscribe sem ciclo de vida controlado

## Warning
- método longo
- componente grande
- service repetitivo
- modal acoplado demais
- template com lógica excessiva

# Saída obrigatória

Para cada item:

- Camada:
- Arquivo:
- Evidência:
- Violação:
- Risco:
- Refatoração recomendada:
- O que preservar: