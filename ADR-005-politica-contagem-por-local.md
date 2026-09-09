# ADR-005 — Política de contagem por local, com herança

**Status:** ACEITO / A IMPLEMENTAR  
**Domínio:** Contagem

## Problema
Nem todos os itens precisam ser contados diariamente e a frequência pode diferir entre Loja e CD.

## Decisão
Política de contagem pertence ao contexto local.

Herança:

`CATEGORIA NO LOCAL → padrão`
`INSUMO NO LOCAL → override opcional`

## Semântica
- override `NULL` → herda categoria;
- override preenchido → usa regra específica;
- não usar lógica React para resolver herança.

## Exemplo
Tampa 550:
- Loja → categoria pode exigir todos os dias;
- CD → categoria pode exigir segunda/sexta.

## Situação atual
CSV de categorias já contém `dias_contagem`.
Dump de 06/09/2026 ainda não apresenta essa coluna.

## Alvo
View SQL deve retornar:
- dias da categoria;
- dias override;
- dias efetivos;
- origem da política;
- `deve_contar_hoje`.
