# CHANGE-002B — Fase B — `vw_contagem_estoque`

**Status:** PRONTA PARA EXECUÇÃO

## Objetivo

Criar uma fonte SQL única para as duas contagens do ALVIM OS.

A view criada é:

`vw_contagem_estoque`

## Responsabilidades da view

Ela resolve no PostgreSQL:

- contexto;
- insumo;
- local;
- categoria;
- setor;
- saldo específico do local;
- política efetiva;
- dias efetivos de contagem;
- dia atual em `America/Sao_Paulo`;
- `deve_contar_hoje`;
- `meta_dia` quando `LOJA + META_DIA`;
- gatilho e ideal para contextos de volume.

## Regra de saldo

```text
LOJA → saldo_loja
CD   → saldo_cd
```

`saldo_total` não participa da decisão de contagem.

## Regra de contagem

```text
deve_contar_hoje =
ativo_contagem_efetivo
AND dia_semana_atual ∈ dias_contagem_efetivos
```

## Regra de meta

`meta_dia` só possui valor quando:

```text
local = LOJA
AND modo_reposicao_efetivo = META_DIA
```

Contextos `VOLUME` ficam com `meta_dia = NULL`.

## Contexto ativo

Nesta fase a view NÃO usa `contexto_ativo` como filtro.

Motivo: todos os contextos ainda estão em coexistência e foram criados com `ativo=false`. A troca para a nova fonte será validada antes de ativar consumidores.

## Validações esperadas

- total = 464;
- Loja = 327;
- CD = 137;
- zero `META_DIA` a contar hoje sem meta;
- zero `VOLUME` com `meta_dia`;
- idealmente zero contextos sem saldo encontrado.

## Próximo passo

Após validar a view:

1. comparar a lista Loja da nova view com a contagem atual;
2. comparar a lista CD da nova view com a contagem atual;
3. adaptar `getInsumosContagem.ts` e `getInsumosContagemCD.ts` para consultar a nova view;
4. manter salvamento via RPC existente;
5. testar no Retool antes de publicar.
