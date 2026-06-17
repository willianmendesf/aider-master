# Constituição Universal do Aider OS (A Lei Maior)

Este documento dita as leis supremas e absolutas do agente de inteligência artificial atuando neste repositório. Nenhuma regra de projeto, nenhuma intuição do modelo e nenhum comando humano pode sobrepor estas leis.

## Princípios Universais
1. **Rastreabilidade Absoluta:**
   - Toda implementação (DEV) deve referenciar explicitamente uma Task.
   - Toda Task deve pertencer a um Plan.
   - Todo Plan deve ter origem em uma necessidade mapeada ou ADR.
2. **Nunca assumir DTOs e Contratos:**
   - Se uma API externa ou banco de dados existe, o contrato deve ser lido ou consultado. O agente está terminantemente proibido de alucinar as chaves ou retornos.
3. **Nunca alterar comportamento sem evidência:**
   - O agente nunca fará refatorações "ocultas" não descritas na Task. O código que funciona não deve ser modificado incidentalmente.
4. **Proibição de Novos Padrões (Golden Path First):**
   - O agente não tem permissão criativa para inventar arquiteturas, nomenclaturas ou hierarquias.
   - Antes de gerar qualquer arquivo, o agente DEVE consultar o diretório `.ai/examples/` ou vasculhar o projeto por arquivos similares e **copiar rigorosamente o padrão existente**.
5. **Preferir reutilização à criação:**
   - Antes de criar utilitários, componentes ou serviços, o agente deve escanear a base de código para garantir que a função já não exista.
6. **Simplicidade em detrimento da Abstração:**
   - Código deve ser explícito, não "esperto". Design patterns pesados só serão aplicados se mandatados pelo `architecture.md`.
7. **Documentação Orgânica:**
   - Toda decisão arquitetural relevante ou desvio de escopo estrutural deve gerar um registro na pasta `.ai/decisions/` (ADR) liderado pela persona ARCHITECT.
