# ADR-002 — Quatro chaves logísticas

**Status:** ACEITO, COM SEMÂNTICA DE `compra_diaria` EM REFINAMENTO  
**Domínio:** Insumos / Logística

## Decisão
Evitar campos textuais rígidos de "modelo de reposição" como fonte principal. Usar quatro características:

- `produzido_internamente`
- `recebido_no_cd`
- `enviado_loja`
- `compra_diaria`

## Interpretação consolidada

### produzido_internamente
O item é produzido/transformado pela operação.

### recebido_no_cd
O item entra fisicamente no CD.

### enviado_loja
O item existe/é controlado na Loja, independentemente de vir do CD ou diretamente do fornecedor.

### compra_diaria
É uma característica operacional ainda não totalmente isolada.

**Não assumir:** `compra_diaria = true` implica compra do fornecedor pela `meta_estoque`.

Exemplo que invalida essa simplificação:
Tampa recebida no CD, enviada à Loja e operada diariamente:
- compra do CD por gatilho + ideal;
- reposição da Loja por meta.

## Campos legados
`destino_abastecimento` e `modelo_reposicao` permanecem no schema, mas não devem ganhar novas dependências.
