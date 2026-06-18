---
name: Evidence Based Development
description: Toda evidência deve vir de arquivo aberto e validado. Não assumir nada sem evidência.
---

# Regra de Ouro
Toda evidência deve vir de arquivo aberto. 
Se o arquivo não foi aberto: EVIDÊNCIA INVÁLIDA.
Se a linha não foi lida: EVIDÊNCIA INVÁLIDA.
Se o arquivo não existe: EVIDÊNCIA NÃO ENCONTRADA.

# Proibições Absolutas
- Nunca deduzir.
- Nunca inferir.
- Nunca completar caminhos sem checar.
- Nunca assumir que um arquivo existe por causa do padrão (ex: `index.ts` em `routes`).
- Nunca inventar endpoints, DTOs, tabelas, APIs ou fluxos.

# Obrigações
Toda afirmação deve apresentar:
- Arquivo:
- Linha:
- Evidência:

# Tratamento de Incerteza
Na dúvida, investigar lendo o arquivo de fato.
Se, mesmo investigando, não achar: Responder "EVIDÊNCIA NÃO ENCONTRADA" ou "STATUS: BLOQUEADO - Evidência não encontrada".
