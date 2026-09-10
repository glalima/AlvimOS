# CHANGE-002A — Fase B5 — Herança efetiva de políticas

## Objetivo

Fazer o banco resolver a política operacional efetiva de cada contexto sem depender do frontend.

Regra oficial:

```text
modo_reposicao_efetivo
=
override do contexto
?? padrão da categoria
```

Para o CD:

```text
modo_reposicao_efetivo = VOLUME
```

A contagem usa a mesma lógica:

```text
dias_contagem_efetivos
=
dias_contagem_override
?? dias_contagem_padrao
```

## Alteração de schema

A coluna:

`insumo_contexto_estoque.modo_reposicao_loja`

é renomeada para:

`insumo_contexto_estoque.modo_reposicao_override`

Motivo: o contexto deixa de armazenar o comportamento padrão e passa a armazenar somente exceções.

## Nova view

`vw_contexto_estoque_efetivo`

Ela centraliza:

- local;
- categoria;
- setor;
- política padrão;
- overrides;
- política efetiva;
- dias efetivos de contagem;
- gatilho;
- ideal;
- chaves logísticas globais.

## O que NÃO muda ainda

- contextos continuam `ativo=false`;
- telas atuais ainda não consomem a nova view;
- `meta_estoque` histórica ainda não foi migrada;
- `compra_diaria` continua deprecated, mas presente;
- nenhuma lógica de contagem foi trocada nesta fase.

## Critérios de aceite

- nenhum contexto sem `modo_reposicao_efetivo`;
- nenhuma categoria ativa para contagem sem `dias_contagem_efetivos`;
- todo contexto CD resolve para `VOLUME`;
- a Loja resolve corretamente `VOLUME` ou `META_DIA` conforme categoria, salvo overrides futuros.

## Próximo passo

Após validar a B5:

1. identificar quais contextos LOJA têm política efetiva `META_DIA`;
2. migrar somente as metas válidas para `meta_estoque_contexto`;
3. criar a view de itens a contar hoje;
4. depois migrar as telas de contagem.
