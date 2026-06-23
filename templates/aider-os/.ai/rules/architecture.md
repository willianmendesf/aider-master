# Limites de Arquitetura e Camadas

Este documento mapeia como os módulos da aplicação conversam entre si. Violações de acesso entre camadas resultarão em reprovação IMEDIATA.

## A Estrutura de Camadas Base

1. **Apresentação / Controllers (Ponto de Entrada)**
   - **Regra:** PROIBIDO possuir regras de negócio ou lógicas complexas.
   - **Função:** Receber a chamada, extrair os dados/DTO, e delegar imediatamente a ação para a Camada de Service. Retornar a resposta (HTTP 200, etc) sem formatar strings.

2. **Serviços / Casos de Uso (Core / Regra de Negócio)**
   - **Regra:** O coração da aplicação. Toda lógica, cálculo, validação de regras de negócios mora aqui.
   - **Restrição:** Services não sabem que existem HTTP, JSON ou HTML. Eles recebem dados limpos e retornam resultados limpos. Eles não acessam o banco diretamente, utilizam Repositories para buscar/salvar.

3. **Repositórios / Infraestrutura (Banco de Dados)**
   - **Regra:** A ÚNICA camada autorizada a executar SQL, chamar ORMs (Prisma, TypeORM) ou bater em bases de terceiros genéricas.
   - **Restrição:** Repository NÃO faz regra de negócio. Ele apenas sabe fazer o CRUD ou executar a busca requerida.

## Padrão de Injeção de Dependências
- As dependências entre classes devem ser sempre passadas via injeção pelo construtor (Dependency Injection).
- Evite criar instâncias ativas (`new Class()`) dentro das funções. O controle da criação das instâncias é delegado ao framework.

## Acoplamento e SOLID
- Dependa de abstrações (Interfaces), não de implementações concretas (Dependency Inversion). Isso garante que possamos "mockar" qualquer coisa na camada de testes.
