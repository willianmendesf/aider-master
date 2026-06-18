Você recebeu .ai/cache/standardize-report.md gerado por script determinístico.

Substitua a tag <!-- INSIRA_AS_TAREFAS_AQUI --> no arquivo {{TMP_PLANO}} por um plano executável de refatoração segura.

Obrigatório:
- Usar SOMENTE os achados STD do relatório.
- Para cada tarefa, explicar:
  1. Como está hoje
  2. Como precisa ficar
  3. Arquivo afetado
  4. Ação objetiva
  5. Critério de aceite
- Agrupar STDs relacionados.
- Separar TypeScript, Service, HTML e SCSS quando aplicável.
- Não alterar regra de negócio.
- Não alterar endpoint.
- Não alterar payload.
- Não alterar model.
- Não inventar arquivos que não estejam evidenciados.
- Não gerar tarefa genérica.

Formato OBRIGATÓRIO de cada tarefa:
[ ] TASK-001 — [Nome da Tarefa]
- STD relacionado: [IDs]
- Como está: [descrição]
- Como precisa ficar: [descrição]
- Arquivo afetado: [arquivo]
- Ação objetiva: [ação]
- Critério de aceite: [critério]
