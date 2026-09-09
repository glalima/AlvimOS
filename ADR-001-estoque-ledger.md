# ADR-001 — Estoque baseado em ledger

**Status:** ACEITO  
**Domínio:** Estoque  
**Data:** 06/09/2026

## Contexto
Tratar estoque como número mutável dificulta auditoria e explicação de divergências.

## Decisão
O saldo será calculado a partir de `movimentacoes_estoque`.

## Consequências
- nenhuma operação crítica deve alterar um campo `saldo`;
- entradas/saídas precisam de taxonomia;
- contagem gera ajuste;
- views calculam posição atual.

## Implementação atual verificada
`vw_estoque_master` calcula `saldo_loja`, `saldo_cd` e `saldo_total`.

`registrar_contagem_estoque` calcula delta e lança `AJUSTE_ENTRADA`/`AJUSTE_SAIDA`.

## Dívida
Existe função antiga `criar_reposicao_por_contagem` usando `AJUSTE_CONTAGEM`. Deve ser retirada do fluxo ou migrada.
