---
name: Refactor & Migration
description: Guia para migração de tela antiga para nova com sistema de design.
---

# Protocolo de Migração

1.  **Leia a Tela Antiga:**
    *   `/read` todos os arquivos de componente, template e serviço da tela Angular 9.
    *   Mapeie **todas** as APIs consumidas (`service.ts`, `http.get/post`).
    *   Identifique **todas** as ações do usuário (clicks, eventos) e seus métodos.
    *   Documente o fluxo de dados (inputs, outputs, estados).

2.  **Leia o Novo Design System:**
    *   `/read` a documentação do novo Design System (componentes, tokens, padrões).
    *   `/read` um exemplo de tela nova (componente, template, estilo) que use o sistema.

3.  **Planeje a Nova Tela:**
    *   Proponha uma estrutura de componentes usando os novos padrões.
    *   Garanta que **todas** as funcionalidades da tela antiga sejam replicadas.
    *   Use os mesmos endpoints e modelos de dados.

4.  **Implemente:**
    *   Crie os arquivos da nova tela.
    *   Use o padrão de código Angular 19 (standalone components, signals).
    *   `/add` os novos arquivos para edição.   
