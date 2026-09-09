# ADR-004 — Contexto de estoque por local

**Status:** ACEITO / A IMPLEMENTAR  
**Domínio:** Insumos / Contagem / CD

## Problema
O modelo atual mistura:
- `categoria`
- `categoria_loja`
- `categoria_cd`
- `setores[]`

Esses campos tentam representar local físico, setor e classificação simultaneamente.

## Decisão
A classificação operacional pertence ao **insumo em um local**.

Modelo:

`INSUMO → LOCAL → SETOR → CATEGORIA`

## Exemplo — Tampa 550

### Loja
- local: LOJA
- setor: Açaí
- categoria: 8 - Embalagens - Açaí

### CD
- local: CD
- setor: CD
- categoria: Embalagens

## Validação pelas chaves
- `recebido_no_cd = true` → contexto CD esperado.
- `enviado_loja = true` → contexto Loja esperado.
- `produzido_internamente = true` pode exigir contexto CD mesmo com `recebido_no_cd = false`.

## Alvo de schema
Tabela conceitual:
`insumo_contexto_estoque`

Campos esperados:
- `insumo_id`
- `local`
- `setor`
- `categoria_id`
- política/override de contagem
- `ativo`

## Consequência
Loja e CD deixam de depender de fallbacks textuais diferentes.
