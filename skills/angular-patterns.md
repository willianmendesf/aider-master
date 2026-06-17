---
name: Angular Patterns
description: Padrões modernos Angular 17+ utilizando Standalone Components, Signals e boas práticas.
---

# Objetivo

Produzir componentes Angular modernos, performáticos, previsíveis e alinhados ao padrão do projeto.

---

# Componentes

Obrigatório:

```ts
standalone: true
```

```ts
changeDetection: ChangeDetectionStrategy.OnPush
```

Utilizar apenas imports necessários.

---

# Injeção de Dependências

Preferir:

```ts
private readonly userService = inject(UserService);
```

Evitar:

```ts
constructor(
  private userService: UserService
) {}
```

Utilizar constructor apenas quando estritamente necessário.

---

# Organização da Classe

Seguir obrigatoriamente a ordem:

1. Serviços injetados
2. Estado privado
3. Signals
4. Computed Signals
5. Forms
6. Lifecycle
7. Métodos públicos
8. Métodos protegidos
9. Métodos privados

---

# Access Modifiers

## private

Utilizar para:

- regras internas
- integrações
- helpers
- processamento

---

## protected

Utilizar para:

- ações da interface
- eventos disparados pelo template

Exemplo:

```ts
protected onSave(): void
```

```ts
protected onSearch(): void
```

---

## public / readonly

Utilizar para:

- signals
- forms
- dados exibidos no template

---

# Signals

Preferir Signals para estado local.

Utilizar:

```ts
readonly loading = signal(false);
```

```ts
readonly users = signal<User[]>([]);
```

---

# Computed

Toda informação derivada deve utilizar:

```ts
computed()
```

Evitar:

```html
{{ calculateSomething() }}
```

Métodos complexos não devem ser executados pelo template.

---

# Formulários

Utilizar:

```ts
FormGroup
FormControl
```

Com tipagem explícita.

Sempre utilizar:

```ts
nonNullable: true
```

quando aplicável.

---

# RxJS

Obrigatório utilizar:

```ts
takeUntilDestroyed()
```

com:

```ts
DestroyRef
```

Evitar:

```ts
Subject<void>
ngOnDestroy()
```

apenas para unsubscribe.

---

# Loading

Toda operação assíncrona deve possuir controle explícito de estado.

Preferir:

```ts
finalize()
```

para garantir consistência.

---

# Estrutura de Fluxo

Separar responsabilidades.

Fluxo recomendado:

```ts
onGenerate()
```

↓

```ts
resolveGeneration()
```

↓

```ts
executeGeneration()
```

---

# Serviços

Services não devem:

- manipular DOM
- abrir modal
- acessar template

Services devem conter:

- regras de negócio
- integração
- transformação de dados

---

# Componentes

Componentes não devem:

- conter regras de negócio complexas
- conter lógica de persistência
- conter regras de domínio

Devem apenas:

- orquestrar UI
- coletar entrada
- exibir dados

---

# Template

Evitar:

```html
(click)="saveUser(user.id, user.name, true)"
```

Preferir:

```html
(click)="onSave(user)"
```

---

# Critérios de Reprovação

- uso excessivo de constructor injection
- ausência de OnPush
- ausência de standalone
- lógica complexa no template
- métodos chamados repetidamente no HTML
- subscriptions sem takeUntilDestroyed
- regras de negócio dentro do componente
- Signals não utilizados para estado local

---

# Regra Final

Componentes devem ser pequenos.

Services devem conter a lógica.

Templates devem ser simples.

Estado deve ser explícito.

Fluxos devem ser previsíveis.
