---
name: Clean Architecture
description: Avalia separação de camadas, responsabilidade arquitetural, dependências e limites entre UI, aplicação, domínio e infraestrutura.
---

# Objetivo

Garantir que o código esteja organizado em camadas claras, com responsabilidades bem separadas e dependências previsíveis.

Clean Architecture aqui significa:

- Component não vira service
- Service não vira component
- UI não contém regra de negócio pesada
- Domínio não depende de detalhe visual
- Infraestrutura não contamina a tela
- Código novo respeita padrões existentes

---

# Camadas

## UI / Component

Deve conter apenas:

- estado de tela
- eventos de usuário
- bindings
- orquestração simples
- chamadas para services
- adaptação mínima para exibição

Não deve conter:

- regra de negócio complexa
- montagem pesada de payload
- parsing repetido
- transformação pesada de resposta
- lógica de download complexa
- lógica de modal complexa
- regras de autorização
- regra de domínio
- acesso direto a API client

Critérios de reprovação:

- component com muitas responsabilidades
- component com método gigante
- component decidindo fluxo de negócio
- component manipulando payload de API de forma complexa
- component concentrando form, tabela, modal, download e integração

---

## Service de Feature

Deve conter:

- comunicação com API
- montagem de request
- adaptação simples de response
- métodos específicos da feature

Não deve conter:

- estado visual
- texto de modal
- regra de template
- manipulação de DOM
- lógica de apresentação

Critérios de reprovação:

- service misturado com UI
- duplicação excessiva de HttpParams
- métodos públicos sem propósito claro
- service genérico demais

---

## Domain / Models / DTOs

Devem representar:

- contratos
- tipos
- requests
- responses
- entidades da feature

Não devem conter:

- lógica visual
- dependência de componente
- dependência de framework de UI

Critérios de reprovação:

- model usado como depósito genérico
- any
- DTO duplicado sem necessidade
- contrato alterado sem evidência

---

## Utils / Helpers

Usar para:

- funções puras
- parsing
- formatação
- validação reutilizável
- transformação sem estado

Não usar para:

- regra de negócio grande
- dependência de service
- dependência de component
- lógica contextual demais

Critérios de reprovação:

- helper genérico demais
- função utilitária com regra específica escondida
- duplicação de util existente

---

# Direção de Dependência

Permitido:

```text
Component -> Service -> ApiClient
Component -> Utils
Service -> Models/DTOs
Service -> ApiClient