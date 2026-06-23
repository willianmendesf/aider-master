---
name: Clean Code
description: Produzir código limpo, previsível, legível e fácil de manter.
---

# Objetivo

Produzir código que seja:

- Fácil de ler
- Fácil de entender
- Fácil de modificar
- Fácil de testar
- Fácil de revisar

Legibilidade possui prioridade sobre abstrações sofisticadas.

---

# Nomenclatura

## Variáveis

Devem descrever claramente seu propósito.

Bom:

```ts
activeUsers
selectedCustomerId
isAuthorized
```

Ruim:

```ts
data
temp
flag
obj
item
```

---

## Métodos

Devem representar exatamente a ação executada.

Bom:

```ts
loadUsers()
calculateTotal()
validateCustomer()
```

Ruim:

```ts
execute()
process()
handle()
run()
```

---

## Classes

Devem representar uma responsabilidade clara.

Bom:

```ts
UserService
UserRepository
UserValidator
```

Ruim:

```ts
UserManager
SystemHelper
GlobalUtils
```

---

# Responsabilidade Única

## Métodos

Cada método deve possuir apenas uma responsabilidade.

Se um método:

- valida
- transforma
- decide
- persiste

ao mesmo tempo,

ele deve ser dividido.

---

## Classes

Cada classe deve possuir apenas um motivo para mudança.

Evitar:

- God Class
- Helper Genérico
- Manager Genérico

---

# Estrutura

Organizar código para leitura de cima para baixo.

Fluxos devem ser claros.

Evitar saltos excessivos entre métodos.

---

# Complexidade

Evitar:

- ifs aninhados
- switch gigantes
- métodos longos
- classes longas

Preferir:

- early return
- extração de métodos
- composição

---

# Duplicação

Antes de criar código novo:

- procurar implementação semelhante
- reutilizar padrões existentes
- reutilizar componentes existentes

Duplicação deve ser removida sempre que possível.

---

# Tratamento de Erros

Proibido:

```ts
catch {}
```

```ts
catch(error) {}
```

Todo erro deve:

- ser tratado
- ser propagado
- ou ser registrado

---

# Comentários

Comentários devem explicar:

- regras de negócio
- decisões arquiteturais
- comportamentos não óbvios

Comentários não devem explicar código simples.

---

# Dependências

- Não adicionar bibliotecas sem necessidade.
- Reutilizar soluções existentes do projeto.
- Seguir padrões definidos em `.ai/rules/`.

---

# Refatoração

Ao alterar código existente:

- melhorar nomes confusos
- reduzir complexidade
- remover duplicação
- melhorar legibilidade

Nunca alterar comportamento sem evidência.

---

# Critérios de Reprovação

- nomes genéricos
- métodos gigantes
- classes gigantes
- duplicação
- código morto
- comentários redundantes
- acoplamento excessivo
- baixa legibilidade
- tratamento de erro inexistente

---

# Regra Final

Sempre escolher:

Código claro > Código curto

Código simples > Código sofisticado

Código previsível > Código criativo
