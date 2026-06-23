# Regras do Projeto (O "Whitepaper" do Domínio)

Este arquivo descreve a visão geral, a missão e a pilha de tecnologia master do projeto. 
*Atenção: Regras de linting e camadas exatas pertencem aos outros arquivos. Aqui documenta-se o "Como pensamos".*

## 1. Stack Tecnológica Base
- **Frontend / Backend Framework:** [Angular, React, NestJS, etc - INSERIR AQUI]
- **Linguagem:** [TypeScript, Python, Go, etc]
- **Gerenciamento de Estado:** [Redux, Context API, Signals, RxJS]
- **Design System / UI:** [Tailwind, Material, Unimed DSU]

## 2. Padrões de Domínio (DDD ou Feature-First)
- O projeto adota a arquitetura orientada a [Features / Domínios]. 
- Módulos não devem conversar diretamente com módulos de outros domínios sem passar por interfaces públicas.

## 3. Gestão de Fluxo e Componentes
- Como a aplicação gerencia dados? O estado flui sempre de [Cima para Baixo / Store Global para Locais].
- Componentes de UI (Dumb Components) não podem fazer requisições HTTP, devendo delegar isso para os Componentes de Página (Smart Components) ou Stores.

## 4. Padrões de DTOs e Comunicação
- Toda a comunicação com a API externa DEVE usar objetos de transferência formatados (`DTO`). 
- Dados provenientes de APIs devem ser mapeados (Mappers/Adapters) antes de entrar no estado interno da aplicação para prevenir quebra de contrato.
