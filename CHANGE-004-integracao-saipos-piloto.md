# CHANGE-004 — Integração Saipos / Piloto de consumo automático

**Status:** FUTURO / NÃO INICIADO

## Escopo inicial
Categoria simples, preferencialmente cigarros.

## Objetivo
Validar:
VENDA → CONSUMO → LEDGER

## Fases
1. importação;
2. staging;
3. de-para;
4. simulação;
5. conciliação manual;
6. idempotência;
7. ativação de `SAIDA_CONSUMO`.

## Não fazer
Não integrar todo o cardápio antes de validar o caso 1:1.
