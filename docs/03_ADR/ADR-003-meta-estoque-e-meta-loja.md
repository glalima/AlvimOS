# ADR-003 — `meta_estoque` representa a meta física da Loja

**Status:** ACEITO  
**Domínio:** Contagem / Reposição

## Contexto
A meta diária estava sendo confundida com alvo de compra.

## Decisão
`meta_estoque` representa exclusivamente:

**quanto se deseja fisicamente disponível na Loja em cada dia da semana.**

## Fórmula
`necessidade_loja = MAX(meta_dia - saldo_loja, 0)`

## Não representa
- estoque ideal do CD;
- gatilho de compra;
- alvo total da empresa.

## Exemplo — Tampas
CD:
- gatilho = 1 caixa
- ideal = 2 caixas

Loja:
- meta diária em tiras/unidades operacionais

O CD pode precisar comprar por volume ao mesmo tempo em que abastece a Loja pela meta diária.

## Consequência
Painel de Compras e Reposição não devem reutilizar a mesma fórmula.
