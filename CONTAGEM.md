# DOMÍNIO — CONTAGEM

## Objetivo
Conferir fisicamente Loja e CD, ajustar ledger e gerar informação operacional.

## Dois contextos
A mesma mercadoria pode aparecer:
- na Loja;
- no CD;
- nos dois.

A classificação e a frequência podem ser diferentes.

## Estado atual — Loja
`getInsumosContagem.ts`:
- filtra `enviado_loja = true`;
- usa `categoria_loja`;
- usa `setores[]`;
- lê `saldo_loja`.

## Estado atual — CD
`getInsumosContagemCD.ts`:
- filtra somente `recebido_no_cd = true`;
- usa `categoria_cd`;
- lê `saldo_cd`.

### Bug conhecido
Produzidos internamente podem existir no CD mesmo com `recebido_no_cd=false`; o filtro atual não os inclui.

## Política de contagem
Categorias já receberam defaults no CSV:
- todos os dias;
- segunda/sexta;
- terça;
- domingo;
- quinta etc.

## Estado alvo
Uma camada SQL única:

`vw_itens_contagem`

Campos sugeridos:
- insumo_id
- local
- setor
- categoria
- unidade
- saldo_atual
- ultima_contagem
- dias_categoria
- dias_override
- dias_efetivos
- origem_politica
- deve_contar_hoje

Consultas:
- Loja → `local='LOJA'`
- CD → `local='CD'`

## Regras
A frequência de contagem não deve ser inferida apenas por `compra_diaria`.
