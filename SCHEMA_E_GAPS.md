# DATABASE — Schema e gaps relevantes

## `insumos`
Possui:
- quatro chaves;
- mínimo/ideal/gatilho;
- categorias Loja/CD;
- setores[];
- campos legados.

## `meta_estoque`
Uma linha por insumo com colunas segunda–domingo.

## `movimentacoes_estoque`
Possui:
- insumo;
- tipo;
- quantidade;
- local;
- referência;
- legado;
- auditoria básica.

## `categorias`
Dump analisado:
- nome
- setor
- destino_padrao
- tipo
- setor_padrao
- contagem_diaria

CSV posterior:
- inclui também `dias_contagem`

### Gap
O dump analisado não contém a coluna `dias_contagem`; validar migration/estado real antes de depender dela.

## Views
Verificada:
- `vw_estoque_master`

Ausente no dump, embora usada pelo backend:
- `view_painel_compras`

## RPCs relevantes
- registrar_contagem_estoque
- confirmar_envio_cd
- confirmar_recebimento_loja
- finalizar_entrada_compra

## Legado crítico
`criar_reposicao_por_contagem` ainda usa conceitos antigos.
