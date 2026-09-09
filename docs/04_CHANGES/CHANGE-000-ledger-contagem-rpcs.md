# CHANGE-000 — Consolidação inicial do ledger e RPCs

**Status:** PARCIALMENTE CONCLUÍDO

## Entregas verificadas
- `vw_estoque_master`
- `registrar_contagem_estoque`
- `confirmar_envio_cd`
- `confirmar_recebimento_loja`
- `finalizar_entrada_compra`
- uso de `ENTRADA_COMPRA` na entrada moderna

## Pendências
- remover/neutralizar `criar_reposicao_por_contagem` antigo;
- eliminar `AJUSTE_CONTAGEM`;
- confirmar todas as rotas antigas;
- transacionalidade completa de fluxos restantes.

## Critério para marcar CONCLUÍDO
Nenhum fluxo ativo pode gravar saldo absoluto ou taxonomia legada.
