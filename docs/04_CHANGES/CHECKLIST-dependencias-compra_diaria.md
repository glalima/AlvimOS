# Checklist — Dependências de `compra_diaria`

**Objetivo:** localizar todas as dependências antes de descontinuar ou remover a coluna.

**Regra:** nesta etapa não alterar comportamento. Apenas mapear.

## Banco PostgreSQL / Supabase

- [ ] Coluna em `insumos`
- [ ] Views que leem `compra_diaria`
- [ ] Functions / RPCs
- [ ] Triggers
- [ ] Constraints
- [ ] Policies / RLS
- [ ] Procedures
- [ ] Materialized views, se existirem
- [ ] Queries salvas no Retool
- [ ] Objetos que derivam regras de `estoque_minimo`, `gatilho_pedido` ou `estoque_ideal` com base nela

## Backend Retool / TypeScript

- [ ] `createInsumo`
- [ ] `updateInsumo`
- [ ] `getInsumosCatalog`
- [ ] `getInsumosContagem`
- [ ] `getInsumosContagemCD`
- [ ] `getPainelCompras`
- [ ] funções de reposição
- [ ] funções de compras
- [ ] validações
- [ ] tipagens/interfaces
- [ ] qualquer `if`, ternário ou filtro usando `compra_diaria`

## Frontend

- [ ] formulário de criação de insumo
- [ ] formulário de edição
- [ ] campos visuais condicionais
- [ ] filtros
- [ ] labels/textos
- [ ] lógica de metas
- [ ] lógica de volume
- [ ] tabelas/listagens
- [ ] tipos TypeScript

## Dados

- [ ] quantidade de insumos com `compra_diaria = true`
- [ ] quantidade com `false`
- [ ] exemplos reais de cada grupo
- [ ] verificar se o valor atual ainda representa alguma regra operacional válida
- [ ] detectar combinações das três chaves globais associadas a `true/false`

## Documentação

- [ ] `00_START_HERE.md`
- [ ] `MAPA_TECNICO_MASTER`
- [ ] `ADR-002`
- [ ] `INSUMOS.md`
- [ ] `CONTAGEM.md`
- [ ] `REPOSICAO.md`
- [ ] `COMPRAS.md`
- [ ] `CHANGE-001`
- [ ] `CHANGE-002`
- [ ] `CHANGE-003`
- [ ] `CURRENT_STATE.md`

## Saída esperada da varredura

Gerar uma tabela:

| Local | Arquivo/Objeto | Tipo | Como usa `compra_diaria` | Pode remover? | Ação futura |
|---|---|---|---|---|---|

Ao final classificar cada dependência como:
- **REMOVER**
- **SUBSTITUIR POR CONTEXTO**
- **SUBSTITUIR POR POLÍTICA DE CONTAGEM**
- **SUBSTITUIR POR VOLUME**
- **LEGADO / SEM USO**
- **PENDENTE DE DECISÃO**

## Critério de conclusão

Só considerar a varredura concluída quando nenhuma referência relevante a `compra_diaria` permanecer sem classificação.
