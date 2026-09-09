# DOMÍNIO — REPOSIÇÃO

## Objetivo
Mover estoque já existente para atender a Loja.

## Regra
Reposição não é compra.

## Fonte de necessidade
Meta física da Loja:

`MAX(meta_dia - quantidade/saldo_loja, 0)`

## Fluxo
1. Contagem Loja
2. Necessidade
3. `PENDENTE_CD`
4. separação
5. envio
6. `ENVIADO_CD`
7. recebimento
8. `RECEBIDO_LOJA`
9. ledger

## RPCs existentes
- `confirmar_envio_cd`
- `confirmar_recebimento_loja`

## Atenção
`criar_reposicao_por_contagem` no dump contém lógica antiga:
- `AJUSTE_CONTAGEM`
- `guardiao_estoque_metas`

Não deve ser considerada regra oficial sem migração.

## Estado alvo
Gerar reposição a partir de:
- contexto Loja;
- meta Loja;
- contexto de origem (CD quando aplicável);
- saldo validado.
