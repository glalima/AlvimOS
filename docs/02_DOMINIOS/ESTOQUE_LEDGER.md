# DOMÍNIO — ESTOQUE / LEDGER

## Fonte de verdade
`movimentacoes_estoque`

## View atual
`vw_estoque_master`

## Locais
- LOJA
- CD

## Saldo
Calculado por soma algébrica de movimentos válidos.

## Taxonomia reconhecida atualmente
Entradas:
- ENTRADA_COMPRA
- ENTRADA_TRANSFERENCIA
- AJUSTE_ENTRADA

Saídas:
- SAIDA_CONSUMO
- SAIDA_TRANSFERENCIA
- AJUSTE_SAIDA

## Contagem
`registrar_contagem_estoque`:
1. calcula saldo;
2. compara com físico;
3. grava somente diferença.

## Regras
- nunca gravar contagem absoluta como movimentação;
- nunca atualizar saldo diretamente;
- cada movimento deve registrar local;
- novas integrações devem produzir eventos idempotentes.

## Dívida
Mapear e remover tipos legados, especialmente `AJUSTE_CONTAGEM`.
