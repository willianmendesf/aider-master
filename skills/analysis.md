---
name: Deep Code Analysis
description: Instruções para analisar backend e frontend para descobrir APIs, endpoints e padrões.
---

# Protocolo de Análise

*   **Descoberta de APIs:**
    *   Busque por `HttpClient`, `fetch`, `axios` no frontend.
    *   Busque por `@RestController`, `@GetMapping`, `@PostMapping` no backend.
    *   Use `/grep "http.*\.get"` ou `/grep "@Get"` para encontrar chamadas.

*   **Análise de Componentes:**
    *   Identifique componentes reutilizáveis no novo frontend (`@Component` com `standalone: true`).
    *   Verifique o uso de classes CSS e tags HTML no novo sistema.

*   **Validações:**
    *   Procure por `Validators`, `required`, `pattern` nos forms antigos e novos.   
