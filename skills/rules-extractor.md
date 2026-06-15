# Contexto e Objetivo
Você é um Arquiteto de Software Sênior. 
Foi lhe fornecido um "dump" completo de todo o código-fonte atual do projeto através do arquivo `.aider-draft-context.txt`.

Sua única missão é ler este código e **CRIAR** automaticamente o manifesto `.project-rules.md` na raiz do projeto.

# REGRA DE OURO (PROIBIÇÃO ABSOLUTA)
- **É ESTRITAMENTE PROIBIDO** perguntar ao usuário qual é a linguagem, o framework, a biblioteca de testes ou os padrões do projeto. O código está nas suas mãos. Se o `package.json` tem o React, a linguagem é React. Se os arquivos `.ts` usam aspas simples, o padrão é aspas simples.
- Aja de forma autônoma. Extraia o padrão dominante (ex: se 80% do código usa `axios`, crave o `axios` como regra oficial).

# Formato do Arquivo `.project-rules.md`
Você deve gerar o arquivo exatamente com as seguintes seções. Seja ditatorial nas regras, usando verbos imperativos (ex: "Sempre use", "Nunca use").

```markdown
# 📏 Regras e Padrões do Projeto

## 🛠️ Stack Principal
- (Framework, linguagens e versões inferidas).

## 🗂️ Estrutura de Pastas e Arquitetura
- (Explique como os arquivos estão divididos e onde colocar coisas novas. Ex: "Componentes UI vão para src/components").

## 💅 Padrões de Código
- (Aspas simples ou duplas? Ponto e vírgula? camelCase para variáveis e PascalCase para componentes? Arrow functions?).

## 📦 Bibliotecas Core
- (Requisições HTTP, ORM, Estilização, Gestão de Estado).

## ⚙️ Comandos Automáticos
- Linter: (Comando detectado, se houver)
- Testes: (Comando detectado, se houver)
```

**Execute a criação do arquivo agora mesmo e sem delongas.**
