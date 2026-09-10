# CHANGE-002A — Fase B6 — Diagnóstico de metas

## Objetivo

Antes de migrar `meta_estoque` para `meta_estoque_contexto`, separar configuração válida de legado.

Classificação:

- `META_DIA_COM_META_HISTORICA`
  - candidata à migração;

- `META_DIA_SEM_META_HISTORICA`
  - precisa parametrização;

- `VOLUME_COM_META_HISTORICA`
  - meta antiga não deve ser migrada automaticamente;

- `VOLUME_SEM_META_HISTORICA`
  - situação coerente.

## Regra

A existência de linha em `meta_estoque` não define mais a política.

A política efetiva vem de:

`override do contexto ?? padrão da categoria`

Somente contextos LOJA com `modo_reposicao_efetivo = 'META_DIA'` podem ter suas metas migradas para o novo modelo.

## Próximo passo

Depois do diagnóstico:

1. revisar quantos META_DIA já têm metas;
2. listar os META_DIA sem metas;
3. confirmar que metas de itens VOLUME serão descartadas como legado;
4. gerar migration de `meta_estoque_contexto` somente para os META_DIA válidos.
